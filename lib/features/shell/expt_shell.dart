import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/debug/debug_console.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/keyboard/keyboard_inset_follower.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../services/native_ime_sheet_bridge.dart';
import '../../services/recurring_alarm_service.dart';
import '../../state/event_store.dart';
import '../notifications/data/notification_repository.dart';
import '../notifications/notifications_page.dart';
import '../notifications/state/notification_store.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/models/fast_info_config.dart';
import '../settings/settings_page.dart';
import '../settings/state/push_notification_log_store.dart';
import '../settings/widgets/push_log/push_notification_event_sheet.dart';
import '../settings/widgets/options/backheader_style_options_panel.dart';
import '../settings/theme/expense_theme.dart';
import '../stats/stats_page.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/sync/google_sheets_sync_controller.dart';
import '../transactions/models/backheader_budget_item.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
import '../transactions/widgets/category_menu/category_editor_panel.dart';
import '../transactions/widgets/category_menu/category_editor_sheet.dart';
import '../transactions/widgets/category_menu/category_menu_panel.dart';
import '../transactions/widgets/header_card/budget_target_editor_sheet.dart';
import '../transactions/widgets/transaction_menu_metrics.dart';
import '../transactions/widgets/recurring_manager_sheet.dart';
import '../transactions/widgets/slide_up_menu_card.dart';
import 'app_tab.dart';
import 'widgets/expt_bottom_nav.dart';
import 'widgets/expt_fab.dart';

class ExptShell extends StatefulWidget {
  const ExptShell({
    super.key,
    required this.store,
    required this.nativeBridge,
    this.googleSheetsSyncController,
  });

  final EventStore store;
  final NativeBridge nativeBridge;
  final GoogleSheetsSyncController? googleSheetsSyncController;

  @override
  State<ExptShell> createState() => _ExptShellState();
}

class _ExptShellState extends State<ExptShell> with WidgetsBindingObserver {
  static const _rightFabBottomOffset = AppDimensions.bottomNavHeight + 24.0;
  static const _nativeSheetCloseSettleDelay = Duration(milliseconds: 360);
  static double _rightFabDebugBottomOffset(double fabSize) =>
      _rightFabBottomOffset + fabSize + 12.0;
  static double _rightFabLogBottomPadding(double fabSize) =>
      _rightFabBottomOffset + fabSize + 24.0;

  late AppTab _activeTab;
  late final TransactionStore _transactionStore;
  late final NotificationStore _notificationStore;
  late final NativeImeSheetBridge _nativeImeSheetBridge;
  late final RecurringAlarmService _recurringAlarmService;
  final _sheetHostKey = GlobalKey<_ShellSheetHostState>();
  final _budgetEditorActiveKey = ValueNotifier<String?>(null);
  late final PageController _pageController;
  var _homeBlockingOverlayOpen = false;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();
  FastInfoConfig _fastInfoConfig = FastInfoConfig.defaults();
  late TransactionHomePage _transactionHomePage;
  double _lastKeyboardInset = 0;
  String? _lastThemeSurfaceLogSignature;
  Timer? _homeThemeSettingsSaveDebounce;
  var _homeThemeSettingsRevision = 0;
  late StatsPage _statsPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DebugConsole.log('[Shell] start');
    _activeTab = _tabFromStoreKey(widget.store.shellActiveTabKey);
    _pageController = PageController(initialPage: appTabs.indexOf(_activeTab));
    _recurringAlarmService = RecurringAlarmService();
    _notificationStore = NotificationStore(
      NotificationRepository(widget.nativeBridge),
    );
    _notificationStore.addListener(_handleNotificationStoreChanged);
    _transactionStore = TransactionStore(
      TransactionRepository(widget.nativeBridge),
      onNotificationsMayHaveChanged:
          _refreshNotificationsAfterTransactionChange,
    );
    _nativeImeSheetBridge = NativeImeSheetBridge(
      onTransactionCommitted: _handleNativeTransactionCommitted,
      onSheetClosed: _handleNativeSheetClosed,
      onDebugLog: (message) async => DebugConsole.log(message),
    );
    unawaited(_transactionStore.start());
    _transactionHomePage = _buildTransactionHomePage();
    _statsPage = _buildStatsPage();
    _requestPostNotificationsOnFirstLaunch();
    unawaited(_notificationStore.start());
    unawaited(_syncRecurringAlarms());
    unawaited(_loadShellSettings());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _homeThemeSettingsSaveDebounce?.cancel();
    _budgetEditorActiveKey.dispose();
    _transactionStore.dispose();
    _nativeImeSheetBridge.dispose();
    _notificationStore.removeListener(_handleNotificationStoreChanged);
    _notificationStore.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refreshBackgroundTransactionsOnResume());
    unawaited(_processRecurringOnResume());
  }

  @override
  void didChangeMetrics() {
    final startedAt = DateTime.now();
    final keyboard = KeyboardInsetReader.snapshotOf(context);
    final inset = keyboard.inset;
    final previous = _lastKeyboardInset;
    _lastKeyboardInset = inset;
    DebugConsole.log(
      '[Perf] Keyboard metrics changed inset=${inset.toStringAsFixed(1)} '
      'previous=${previous.toStringAsFixed(1)} '
      'delta=${(inset - previous).toStringAsFixed(1)} '
      'activeTab=${_activeTab.id} homeOverlay=$_homeBlockingOverlayOpen '
      'source=${keyboard.source} phase=${keyboard.phase ?? 'none'} '
      'seq=${keyboard.sequence?.toString() ?? 'n/a'} '
      'ageMs=${keyboard.ageMs?.toString() ?? 'n/a'} '
      'fallback=${keyboard.fallbackInset.toStringAsFixed(1)}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final frameKeyboard = KeyboardInsetReader.snapshotOf(context);
      DebugConsole.log(
        '[Perf] Keyboard metrics frame inset=${frameKeyboard.inset.toStringAsFixed(1)} '
        'elapsed=${_elapsedMs(startedAt)}ms activeTab=${_activeTab.id} '
        'source=${frameKeyboard.source} '
        'phase=${frameKeyboard.phase ?? 'none'} '
        'seq=${frameKeyboard.sequence?.toString() ?? 'n/a'} '
        'ageMs=${frameKeyboard.ageMs?.toString() ?? 'n/a'} '
        'fallback=${frameKeyboard.fallbackInset.toStringAsFixed(1)}',
      );
    });
  }

  String _contextKeyboardTrace() {
    final keyboard = KeyboardInsetReader.snapshotOf(context);
    return 'keyboard=${keyboard.inset.toStringAsFixed(1)} '
        'source=${keyboard.source} '
        'phase=${keyboard.phase ?? 'none'} '
        'seq=${keyboard.sequence?.toString() ?? 'n/a'} '
        'ageMs=${keyboard.ageMs?.toString() ?? 'n/a'} '
        'fallback=${keyboard.fallbackInset.toStringAsFixed(1)}';
  }

  int _elapsedMs(DateTime startedAt) {
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  TransactionHomePage _buildTransactionHomePage() {
    final fabSize = _themeSettings.fabSize.toDouble();
    return TransactionHomePage(
      store: _transactionStore,
      expenseTheme: ExpenseTheme.fromSettings(_themeSettings),
      fastInfoConfig: _fastInfoConfig,
      logBottomPadding: _rightFabLogBottomPadding(fabSize),
      onNotificationPressed: _handleHeaderNotificationPressed,
      notificationUnreadCount: _notificationStore.unreadCount,
      onEditTransaction: _openEditTransaction,
      onDeleteTransactionRequested: _confirmDeleteTransaction,
      onBlockingOverlayChanged: _setHomeBlockingOverlay,
      onBudgetTargetEditorRequested:
          (item, {required requestedAt, required headerExpanded}) {
            _sheetHostKey.currentState?.openBudgetTargetEditor(
              item,
              requestedAt: requestedAt,
              headerExpanded: headerExpanded,
            );
          },
      onBudgetTargetEditorClosed: () {
        _sheetHostKey.currentState?.closeBudgetTargetEditor();
      },
      onCategoryMenuRequested: (request) {
        _sheetHostKey.currentState?.openCategoryPicker(request);
      },
      onVendorSheetRequested: () {
        _sheetHostKey.currentState?.openVendorFilter();
      },
      onFocusedSheetDismissRequested: () {
        _sheetHostKey.currentState?.closeAll();
      },
      onAddCategoryEditorRequested: () {
        _sheetHostKey.currentState?.openCategory();
      },
      onEditCategoryEditorRequested: (category) {
        _sheetHostKey.currentState?.openCategory(initialCategory: category);
      },
      onThemeSettingsChanged: (settings) {
        _queueHomeThemeSettings(settings);
      },
      onBackheaderLiveTunerRequested: () {
        _sheetHostKey.currentState?.openBackheaderLiveTuner();
      },
      onPickSummaryMonth: (initial) => widget.nativeBridge.expensePickYearMonth(
        year: initial.year,
        month: initial.month,
      ),
      budgetEditorActiveKey: _budgetEditorActiveKey,
    );
  }

  StatsPage _buildStatsPage() {
    return StatsPage(
      store: _transactionStore,
      expenseTheme: ExpenseTheme.fromSettings(_themeSettings),
      onCategoryMenuRequested: (request) {
        _sheetHostKey.currentState?.openCategoryPicker(request);
      },
      onAddCategoryEditorRequested: () {
        _sheetHostKey.currentState?.openCategory();
      },
      onEditCategoryEditorRequested: (category) {
        _sheetHostKey.currentState?.openCategory(initialCategory: category);
      },
    );
  }

  void _requestPostNotificationsOnFirstLaunch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_requestPostNotificationsOnFirstLaunchAfterFrame());
    });
  }

  Future<void> _requestPostNotificationsOnFirstLaunchAfterFrame() async {
    try {
      final requested = await widget.nativeBridge
          .requestPostNotificationsOnFirstLaunch();
      DebugConsole.log(
        '[Notification] first launch permission prompt requested=$requested',
      );
    } catch (error) {
      DebugConsole.log(
        '[Notification] first launch permission prompt failed: $error',
      );
    }
  }

  Future<void> _syncRecurringAlarms() async {
    try {
      await _recurringAlarmService.syncRecurringAlarms();
      DebugConsole.log('[RecurringAlarm] shell sync complete');
    } catch (error) {
      DebugConsole.log('[RecurringAlarm] shell sync failed: $error');
    }
  }

  Future<void> _processRecurringOnResume() async {
    try {
      final result = await _recurringAlarmService.processRecurringNow();
      DebugConsole.log(
        '[RecurringAlarm] resume processed ${result.processedCount} recurring rows',
      );
      if (!mounted) return;
      if (result.processedCount == 0) return;
      final processedTransactions = result.processed
          .map(TransactionRecord.fromMap)
          .toList();
      if (processedTransactions.isNotEmpty) {
        _transactionStore.mergeExternalTransactions(processedTransactions);
      } else {
        await _transactionStore.refreshAfterRecurringProcessing();
      }
    } catch (error) {
      DebugConsole.log('[RecurringAlarm] resume processing failed: $error');
    }
  }

  Future<void> _refreshBackgroundTransactionsOnResume() async {
    try {
      final events = await widget.store.refreshNewEvents();
      if (!mounted || events.isEmpty) return;
      await _transactionStore.mergeTransactionsForNotificationEvents(
        events.map((event) => event.id),
      );
    } catch (error) {
      DebugConsole.log('[PushParser] resume event refresh failed: $error');
    }
  }

  Future<void> _loadShellSettings() async {
    final payload = await widget.nativeBridge.expenseLoadSettings();
    if (!mounted) return;
    setState(() {
      _themeSettings = payload.themeSettings;
      _fastInfoConfig = payload.fastInfoConfig;
      _transactionHomePage = _buildTransactionHomePage();
      _statsPage = _buildStatsPage();
    });
  }

  void _handleNotificationStoreChanged() {
    if (!mounted) return;
    unawaited(
      _transactionStore.mergeTransactionsForNotificationEvents(
        widget.store.allEvents.map((event) => event.id),
      ),
    );
    setState(() {
      _transactionHomePage = _buildTransactionHomePage();
    });
  }

  Future<void> _refreshNotificationsAfterTransactionChange() async {
    await _notificationStore.refresh();
    if (_activeTab == AppTab.notifications) {
      await _notificationStore.markAllUnreadRead();
    }
  }

  Future<void> _handleNativeTransactionCommitted() async {
    DebugConsole.log(
      '[NativeImeSheet] AddTransaction committed refresh queued',
    );
    await Future<void>.delayed(_nativeSheetCloseSettleDelay);
    if (!mounted) return;
    DebugConsole.log('[NativeImeSheet] AddTransaction committed refresh start');
    await _transactionStore.refreshAfterRecurringProcessing();
    if (!mounted) return;
    setState(() {
      _transactionHomePage = _buildTransactionHomePage();
      _statsPage = _buildStatsPage();
    });
    DebugConsole.log('[NativeImeSheet] AddTransaction committed refresh end');
  }

  Future<void> _handleNativeSheetClosed() async {
    DebugConsole.log('[NativeImeSheet] sheet closed acknowledged');
  }

  void _applyThemeSettings(AppThemeSettings settings) {
    setState(() {
      _themeSettings = settings;
      _transactionHomePage = _buildTransactionHomePage();
      _statsPage = _buildStatsPage();
    });
    DebugConsole.log(
      '[ThemeSurface] shell apply ${_settingsSignature(settings)}',
    );
  }

  void _queueHomeThemeSettings(AppThemeSettings settings) {
    _homeThemeSettingsRevision += 1;
    final revision = _homeThemeSettingsRevision;
    _applyThemeSettings(settings);
    _homeThemeSettingsSaveDebounce?.cancel();
    _homeThemeSettingsSaveDebounce = Timer(
      const Duration(milliseconds: 180),
      () => unawaited(_persistHomeThemeSettings(settings, revision)),
    );
  }

  Future<void> _persistHomeThemeSettings(
    AppThemeSettings settings,
    int revision,
  ) async {
    try {
      final confirmed = await widget.nativeBridge.expenseUpdateThemeSettings(
        settings,
      );
      if (!mounted || revision != _homeThemeSettingsRevision) return;
      _applyThemeSettings(confirmed);
    } catch (error) {
      DebugConsole.log('[ThemeSurface] home live update failed: $error');
    }
  }

  void _applyFastInfoConfig(FastInfoConfig config) {
    setState(() {
      _fastInfoConfig = config;
      _transactionHomePage = _buildTransactionHomePage();
    });
  }

  void _selectTab(AppTab tab) {
    if (_activeTab == tab) {
      DebugConsole.log(
        '[Perf] BottomNav tap ignored tab=${tab.id} '
        '${_contextKeyboardTrace()}',
      );
      return;
    }
    final requestedAt = DateTime.now();
    final previous = _activeTab;
    DebugConsole.log(
      '[Perf] BottomNav tap from=${previous.id} to=${tab.id} '
      'homeOverlay=$_homeBlockingOverlayOpen '
      '${_contextKeyboardTrace()}',
    );
    _sheetHostKey.currentState?.closeAll();
    DebugConsole.log(
      '[Perf] BottomNav close sheets issued from=${previous.id} to=${tab.id} '
      'elapsed=${_elapsedMs(requestedAt)}ms',
    );
    if (previous == AppTab.settings && tab != AppTab.settings) {
      widget.store.setSettingsActiveMenuKey('root');
      DebugConsole.log(
        '[Settings] active menu reset reason=bottom_nav_leave target=${tab.id}',
      );
    }
    setState(() {
      _activeTab = tab;
      _homeBlockingOverlayOpen = false;
    });
    widget.store.setShellActiveTabKey(tab.id);
    DebugConsole.log(
      '[Perf] BottomNav shell state queued from=${previous.id} to=${tab.id} '
      'elapsed=${_elapsedMs(requestedAt)}ms',
    );
    _jumpToTabPage(tab, requestedAt);
    if (tab == AppTab.notifications) {
      unawaited(_openNotificationsTab(requestedAt));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeTab != tab) return;
      DebugConsole.log(
        '[Perf] BottomNav frame from=${previous.id} to=${tab.id} '
        'elapsed=${_elapsedMs(requestedAt)}ms '
        '${_contextKeyboardTrace()}',
      );
    });
  }

  void _jumpToTabPage(AppTab tab, DateTime requestedAt) {
    final pageIndex = appTabs.indexOf(tab);
    if (tab == AppTab.stats) {
      DebugConsole.log(
        '[Perf] BottomNav page jump deferred tab=${tab.id} '
        'reason=post-frame elapsed=${_elapsedMs(requestedAt)}ms',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _activeTab != tab || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(pageIndex);
        DebugConsole.log(
          '[Perf] BottomNav page jump tab=${tab.id} index=$pageIndex '
          'deferred=true elapsed=${_elapsedMs(requestedAt)}ms',
        );
      });
      return;
    }
    if (!_pageController.hasClients) {
      DebugConsole.log(
        '[Perf] BottomNav page jump deferred tab=${tab.id} '
        'elapsed=${_elapsedMs(requestedAt)}ms',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _activeTab != tab || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(pageIndex);
        DebugConsole.log(
          '[Perf] BottomNav page jump tab=${tab.id} index=$pageIndex '
          'deferred=true elapsed=${_elapsedMs(requestedAt)}ms',
        );
      });
      return;
    }
    _pageController.jumpToPage(pageIndex);
    DebugConsole.log(
      '[Perf] BottomNav page jump tab=${tab.id} index=$pageIndex '
      'deferred=false elapsed=${_elapsedMs(requestedAt)}ms',
    );
  }

  Future<void> _openNotificationsTab(DateTime requestedAt) async {
    DebugConsole.log(
      '[Notification] tab open refresh requested elapsed=${_elapsedMs(requestedAt)}ms',
    );
    await _notificationStore.refresh();
    await _notificationStore.markAllUnreadRead();
    DebugConsole.log(
      '[Notification] tab open refresh complete elapsed=${_elapsedMs(requestedAt)}ms',
    );
  }

  void _handleFabPressed() {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] AddTransaction shell open requested source=fab',
    );
    _sheetHostKey.currentState?.openTransaction(
      requestedAt: requestedAt,
      source: 'fab',
    );
  }

  void _handleFabLongPressed() {
    DebugConsole.log(
      '[SlideUpMenu] RecurringManager shell open requested source=fabLongPress',
    );
    _sheetHostKey.currentState?.openRecurring();
  }

  void _handleHeaderNotificationPressed() {
    DebugConsole.log('[Notification] header bell open requested');
    _selectTab(AppTab.notifications);
  }

  void _openEditTransaction(TransactionRecord transaction) {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] EditTransaction shell open requested source=logbox '
      'id=${transaction.id}',
    );
    _sheetHostKey.currentState?.openTransaction(
      requestedAt: requestedAt,
      source: 'logbox',
      transaction: transaction,
    );
  }

  Future<void> _openTransactionFromPushLog(int transactionId) async {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[PushLink] open transaction requested source=push_log '
      'transaction=$transactionId',
    );
    final transaction = await widget.nativeBridge.expenseGetTransaction(
      transactionId,
    );
    if (!mounted) return;
    if (transaction == null) {
      DebugConsole.log(
        '[PushLink] open transaction failed reason=missing transaction=$transactionId',
      );
      return;
    }
    _sheetHostKey.currentState?.closeAll();
    setState(() {
      _activeTab = AppTab.home;
      _homeBlockingOverlayOpen = false;
    });
    widget.store.setShellActiveTabKey(AppTab.home.id);
    widget.store.setSettingsActiveMenuKey('root');
    _jumpToTabPage(AppTab.home, requestedAt);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetHostKey.currentState?.openTransaction(
        requestedAt: requestedAt,
        source: 'push_log',
        transaction: transaction,
      );
      DebugConsole.log(
        '[PushLink] transaction opened source=push_log '
        'transaction=${transaction.id} elapsed=${_elapsedMs(requestedAt)}ms',
      );
    });
  }

  Future<void> _openNotificationEventFromTransaction(int eventId) async {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[PushLink] open notification requested source=edit_transaction '
      'event=$eventId',
    );
    final logStore = PushNotificationLogStore(
      bridge: widget.nativeBridge,
      parserStore: widget.store,
    );
    try {
      final event = await logStore.loadEvent(eventId);
      if (!mounted) return;
      if (event == null) {
        DebugConsole.log(
          '[PushLink] open notification failed reason=missing event=$eventId',
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        builder: (context) => PushNotificationEventSheet(
          event: event,
          parserStore: widget.store,
          logStore: logStore,
          onOpenTransaction: _openTransactionFromPushLog,
        ),
      );
      DebugConsole.log(
        '[PushLink] notification sheet closed event=$eventId '
        'elapsed=${_elapsedMs(requestedAt)}ms',
      );
    } finally {
      logStore.dispose();
    }
  }

  void _setHomeBlockingOverlay(bool open) {
    if (_homeBlockingOverlayOpen == open) return;
    setState(() => _homeBlockingOverlayOpen = open);
  }

  Future<bool> _confirmDeleteTransaction(TransactionRecord transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tranzakció törlése'),
          content: Text(
            'Biztosan törlöd ezt a tranzakciót: ${transaction.displayMerchant}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Mégse'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Törlés'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return false;

    final deleted = await _transactionStore.deleteTransaction(transaction);
    if (!deleted) return false;
    if (!mounted) return true;
    _sheetHostKey.currentState?.closeTransactionIfEditing(transaction.id);
    return true;
  }

  List<Widget> _buildShellNavigation(ExpenseTheme expenseTheme) {
    final fabSize = expenseTheme.settings.fabSize.toDouble();
    return [
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: ExptBottomNav(
          activeTab: _activeTab,
          surfaceColor: expenseTheme.logBox,
          surfaceStyle: expenseTheme.bottomNavSurfaceStyle,
          accentColor: expenseTheme.accent,
          accentLightColor: expenseTheme.accentLight,
          activeBackgroundColor: expenseTheme.activeBackground,
          onTabSelected: _selectTab,
        ),
      ),
      Positioned(
        right: 20,
        bottom: _rightFabBottomOffset,
        child: ExptFab(
          primaryColor: expenseTheme.accent,
          surfaceStyle: expenseTheme.buttonSurfaceStyle,
          size: fabSize,
          onPressed: _handleFabPressed,
          onLongPress: _handleFabLongPressed,
        ),
      ),
    ];
  }

  Widget _buildShellPage(AppTab tab, ExpenseTheme expenseTheme) {
    switch (tab) {
      case AppTab.home:
        return _transactionHomePage;
      case AppTab.stats:
        return _statsPage;
      case AppTab.notifications:
        return NotificationsPage(
          nativeBridge: widget.nativeBridge,
          store: _notificationStore,
          expenseTheme: expenseTheme,
          active: false,
          onBack: () => _selectTab(AppTab.home),
        );
      case AppTab.settings:
        return SettingsPage(
          store: widget.store,
          nativeBridge: widget.nativeBridge,
          googleSheetsSyncController: widget.googleSheetsSyncController,
          expenseTheme: expenseTheme,
          onThemeSettingsChanged: _applyThemeSettings,
          onFastInfoConfigChanged: _applyFastInfoConfig,
          onOpenTransaction: _openTransactionFromPushLog,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseTheme = ExpenseTheme.fromSettings(_themeSettings);
    _logThemeSurfaceOnce(expenseTheme);
    final shellNavigation = _buildShellNavigation(expenseTheme);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: expenseTheme.appBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              key: const ValueKey('shell-page-stack'),
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appTabs.length,
              itemBuilder: (context, index) =>
                  _buildShellPage(appTabs[index], expenseTheme),
            ),
          ),
          if (!_homeBlockingOverlayOpen) ...shellNavigation,
          DebugFloatingButton(
            bottomOffset: _rightFabDebugBottomOffset(
              _themeSettings.fabSize.toDouble(),
            ),
            nativeImeSheetBridge: _nativeImeSheetBridge,
            recurringAlarmService: _recurringAlarmService,
            onRecurringChanged:
                _transactionStore.refreshAfterRecurringProcessing,
          ),
          Positioned.fill(
            child: _ShellSheetHost(
              key: _sheetHostKey,
              store: _transactionStore,
              nativeBridge: widget.nativeBridge,
              budgetEditorActiveKey: _budgetEditorActiveKey,
              expenseTheme: expenseTheme,
              resolveNotificationEventId:
                  widget.nativeBridge.expenseNotificationEventIdForTransaction,
              onOpenNotificationEvent: _openNotificationEventFromTransaction,
              onThemeSettingsChanged: _queueHomeThemeSettings,
            ),
          ),
        ],
      ),
    );
  }

  void _logThemeSurfaceOnce(ExpenseTheme expenseTheme) {
    final signature =
        '${_settingsSignature(expenseTheme.settings)} '
        'accent=${_hex(expenseTheme.accent)} '
        'bgColor=${_hex(expenseTheme.appBackground)} '
        'headerColor=${_hex(expenseTheme.headerCard)} '
        'logBoxColor=${_hex(expenseTheme.logBox)}';
    if (_lastThemeSurfaceLogSignature == signature) return;
    _lastThemeSurfaceLogSignature = signature;
    DebugConsole.log('[ThemeSurface] shell resolved $signature');
  }

  String _settingsSignature(AppThemeSettings settings) {
    return 'button=${settings.buttonSurfaceStyle.nativeValue} '
        'content=${settings.contentSurfaceStyle.nativeValue} '
        'bg=${settings.backgroundColor.nativeValue} '
        'card=${settings.cardColor.nativeValue} '
        'box=${settings.boxColor.nativeValue} '
        'magnet=${settings.magnetType.nativeValue} '
        'backheader=${settings.backheaderStyle.nativeValue}';
  }

  String _hex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }

  AppTab _tabFromStoreKey(String key) {
    for (final tab in appTabs) {
      if (tab.id == key) return tab;
    }
    return AppTab.home;
  }
}

class _ShellSheetHost extends StatefulWidget {
  const _ShellSheetHost({
    super.key,
    required this.store,
    required this.nativeBridge,
    required this.budgetEditorActiveKey,
    required this.expenseTheme,
    required this.resolveNotificationEventId,
    required this.onOpenNotificationEvent,
    required this.onThemeSettingsChanged,
  });

  final TransactionStore store;
  final NativeBridge nativeBridge;
  final ValueNotifier<String?> budgetEditorActiveKey;
  final ExpenseTheme expenseTheme;
  final Future<int?> Function(int transactionId) resolveNotificationEventId;
  final Future<void> Function(int eventId) onOpenNotificationEvent;
  final ValueChanged<AppThemeSettings> onThemeSettingsChanged;

  @override
  State<_ShellSheetHost> createState() => _ShellSheetHostState();
}

class _ShellSheetHostState extends State<_ShellSheetHost> {
  final _transactionSlotKey = GlobalKey<_TransactionSheetSlotState>();
  final _categoryPickerSlotKey = GlobalKey<_CategoryMenuPickerSlotState>();
  final _vendorFilterSlotKey = GlobalKey<_VendorFilterSheetSlotState>();
  final _categorySlotKey = GlobalKey<_CategorySheetSlotState>();
  final _recurringSlotKey = GlobalKey<_RecurringSheetSlotState>();
  final _budgetSlotKey = GlobalKey<_BudgetTargetSheetSlotState>();
  final _backheaderTunerSlotKey = GlobalKey<_BackheaderLiveTunerSlotState>();

  void openTransaction({
    required DateTime requestedAt,
    required String source,
    TransactionRecord? transaction,
  }) {
    _categoryPickerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _transactionSlotKey.currentState?.open(
      requestedAt: requestedAt,
      source: source,
      transaction: transaction,
    );
  }

  void openCategory({TransactionCategory? initialCategory}) {
    _transactionSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _categorySlotKey.currentState?.open(initialCategory: initialCategory);
  }

  void openCategoryPicker(CategoryMenuSheetRequest request) {
    _transactionSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.open(request);
  }

  void openVendorFilter() {
    _transactionSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.open();
  }

  void openRecurring() {
    _transactionSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _recurringSlotKey.currentState?.open(requestedAt: DateTime.now());
  }

  void openBackheaderLiveTuner() {
    _transactionSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.open();
  }

  void openBudgetTargetEditor(
    BackheaderBudgetItem item, {
    required DateTime requestedAt,
    required bool headerExpanded,
  }) {
    _transactionSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.open(
      item,
      requestedAt: requestedAt,
      headerExpanded: headerExpanded,
    );
  }

  void closeTransactionIfEditing(int transactionId) {
    _transactionSlotKey.currentState?.closeIfEditing(transactionId);
  }

  void closeBudgetTargetEditor() {
    _budgetSlotKey.currentState?.close();
  }

  void closeAll() {
    _transactionSlotKey.currentState?.close();
    _categoryPickerSlotKey.currentState?.close();
    _vendorFilterSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _backheaderTunerSlotKey.currentState?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _TransactionSheetSlot(
            key: _transactionSlotKey,
            store: widget.store,
            expenseTheme: widget.expenseTheme,
            resolveNotificationEventId: widget.resolveNotificationEventId,
            onOpenNotificationEvent: widget.onOpenNotificationEvent,
          ),
        ),
        Positioned.fill(
          child: _CategoryMenuPickerSlot(
            key: _categoryPickerSlotKey,
            store: widget.store,
            expenseTheme: widget.expenseTheme,
          ),
        ),
        Positioned.fill(
          child: _VendorFilterSheetSlot(
            key: _vendorFilterSlotKey,
            store: widget.store,
            expenseTheme: widget.expenseTheme,
          ),
        ),
        Positioned.fill(
          child: _CategorySheetSlot(
            key: _categorySlotKey,
            store: widget.store,
            expenseTheme: widget.expenseTheme,
          ),
        ),
        Positioned.fill(
          child: _RecurringSheetSlot(
            key: _recurringSlotKey,
            store: widget.store,
            nativeBridge: widget.nativeBridge,
            expenseTheme: widget.expenseTheme,
          ),
        ),
        Positioned.fill(
          child: _BudgetTargetSheetSlot(
            key: _budgetSlotKey,
            store: widget.store,
            activeKey: widget.budgetEditorActiveKey,
            expenseTheme: widget.expenseTheme,
          ),
        ),
        Positioned.fill(
          child: _BackheaderLiveTunerSlot(
            key: _backheaderTunerSlotKey,
            expenseTheme: widget.expenseTheme,
            onThemeSettingsChanged: widget.onThemeSettingsChanged,
          ),
        ),
      ],
    );
  }
}

class _BackheaderLiveTunerSlot extends StatefulWidget {
  const _BackheaderLiveTunerSlot({
    super.key,
    required this.expenseTheme,
    required this.onThemeSettingsChanged,
  });

  final ExpenseTheme expenseTheme;
  final ValueChanged<AppThemeSettings> onThemeSettingsChanged;

  @override
  State<_BackheaderLiveTunerSlot> createState() =>
      _BackheaderLiveTunerSlotState();
}

class _BackheaderLiveTunerSlotState extends State<_BackheaderLiveTunerSlot> {
  var _open = false;
  AppThemeSettings? _draftSettings;

  void open() {
    setState(() {
      _open = true;
      _draftSettings = widget.expenseTheme.settings;
    });
    DebugConsole.log('[BackheaderTuner] shell open');
  }

  void close() {
    if (!_open && _draftSettings == null) return;
    setState(() {
      _open = false;
      _draftSettings = null;
    });
    DebugConsole.log('[BackheaderTuner] shell closed');
  }

  @override
  void didUpdateWidget(covariant _BackheaderLiveTunerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_open) {
      _draftSettings = null;
    } else {
      _draftSettings ??= widget.expenseTheme.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _draftSettings ?? widget.expenseTheme.settings;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
    return SlideUpMenuCard(
      cardKey: const ValueKey('backheader-live-tuner-slide-card'),
      debugLabel: 'BackheaderLiveTuner',
      visible: _open,
      panelHeight: panelHeight,
      showFocusVeil: false,
      dismissOnVeilTap: false,
      dragFromHandleOnly: true,
      dragHandleExtent: 72,
      verticalDragBias: 1.2,
      onDismissed: close,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ColoredBox(
          key: const ValueKey('backheader-live-tuner-panel'),
          color: widget.expenseTheme.fieldSurface,
          child: BackheaderStyleOptionsPanel(
            settings: settings,
            onChanged: _updateDraftSettings,
          ),
        ),
      ),
    );
  }

  void _updateDraftSettings(AppThemeSettings settings) {
    setState(() => _draftSettings = settings);
    widget.onThemeSettingsChanged(settings);
  }
}

class _TransactionSheetSlot extends StatefulWidget {
  const _TransactionSheetSlot({
    super.key,
    required this.store,
    required this.expenseTheme,
    required this.resolveNotificationEventId,
    required this.onOpenNotificationEvent,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final Future<int?> Function(int transactionId) resolveNotificationEventId;
  final Future<void> Function(int eventId) onOpenNotificationEvent;

  @override
  State<_TransactionSheetSlot> createState() => _TransactionSheetSlotState();
}

class _TransactionSheetSlotState extends State<_TransactionSheetSlot> {
  var _open = false;
  DateTime? _openRequestedAt;
  TransactionRecord? _editingTransaction;

  void open({
    required DateTime requestedAt,
    required String source,
    TransactionRecord? transaction,
  }) {
    final label = transaction == null ? 'AddTransaction' : 'EditTransaction';
    setState(() {
      _open = true;
      _openRequestedAt = requestedAt;
      _editingTransaction = transaction;
    });
    DebugConsole.log(
      '[SlideUpMenu] $label shell state queued source=$source '
      'elapsed=${_elapsedMs(requestedAt)}ms',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openRequestedAt != requestedAt) return;
      DebugConsole.log(
        '[SlideUpMenu] $label shell first frame '
        'elapsed=${_elapsedMs(requestedAt)}ms',
      );
    });
  }

  void close() {
    if (!_open && _editingTransaction == null && _openRequestedAt == null) {
      return;
    }
    setState(() {
      _open = false;
      _openRequestedAt = null;
      _editingTransaction = null;
    });
  }

  void closeIfEditing(int transactionId) {
    if (_editingTransaction?.id != transactionId) return;
    close();
  }

  @override
  Widget build(BuildContext context) {
    return AddTransactionSheet(
      store: widget.store,
      initialTransaction: _editingTransaction,
      openRequestedAt: _openRequestedAt,
      visible: _open,
      expenseTheme: widget.expenseTheme,
      resolveNotificationEventId: widget.resolveNotificationEventId,
      onOpenNotificationEvent: widget.onOpenNotificationEvent,
      onClose: close,
    );
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}

class _CategoryMenuPickerSlot extends StatefulWidget {
  const _CategoryMenuPickerSlot({
    super.key,
    required this.store,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;

  @override
  State<_CategoryMenuPickerSlot> createState() =>
      _CategoryMenuPickerSlotState();
}

class _CategoryMenuPickerSlotState extends State<_CategoryMenuPickerSlot> {
  CategoryMenuSheetRequest? _request;

  void open(CategoryMenuSheetRequest request) {
    setState(() => _request = request);
    DebugConsole.log('[CategoryMenu] shell picker open ${request.debugLabel}');
  }

  void close({bool notify = true}) {
    final request = _request;
    if (request == null) return;
    setState(() => _request = null);
    if (notify) request.onClosed();
    DebugConsole.log(
      '[CategoryMenu] shell picker closed ${request.debugLabel}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) return const SizedBox.shrink();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = (screenHeight - request.topOffset)
        .clamp(0.0, screenHeight)
        .toDouble();
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return SlideUpMenuCard(
          cardKey: request.cardKey,
          debugLabel: request.debugLabel,
          visible: true,
          panelHeight: panelHeight,
          onDismissed: () => close(),
          dismissOnVeilTap: true,
          focusVeilPassthroughTop: 0,
          dragFromHandleOnly: true,
          dragHandleExtent: 72,
          verticalDragBias: 1.2,
          keyboardAvoidance: false,
          child: SafeArea(
            top: false,
            bottom: false,
            child: CategoryMenuPanel(
              key: request.panelKey,
              activeType: request.activeType,
              categories: widget.store.categories,
              categoryTransactionCounts: widget.store.categoryTransactionCounts,
              activeCategory: request.activeCategory,
              selectedCategoryIds: request.selectedCategoryIds,
              onSelect: (category) {
                request.onSelect(category);
                close(notify: false);
              },
              onApply: (ids) {
                request.onApply(ids);
                close(notify: false);
              },
              onModify: request.onModify,
              onDelete: request.onDelete,
              onAdd: request.onAdd,
              onClose: () => close(),
              surfaceColor: widget.expenseTheme.categoryMenu,
              cardSurfaceColor: widget.expenseTheme.categoryCard,
              cardSurfaceStyle: widget.expenseTheme.categoryCardSurfaceStyle,
              avatarSurfaceStyle: widget.expenseTheme.buttonSurfaceStyle,
              accentColor: widget.expenseTheme.accent,
              addButtonPlacement: CategoryMenuAddButtonPlacement.card,
            ),
          ),
        );
      },
    );
  }
}

class _VendorFilterSheetSlot extends StatefulWidget {
  const _VendorFilterSheetSlot({
    super.key,
    required this.store,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;

  @override
  State<_VendorFilterSheetSlot> createState() => _VendorFilterSheetSlotState();
}

class _VendorFilterSheetSlotState extends State<_VendorFilterSheetSlot> {
  final _scrollController = ScrollController();
  var _open = false;
  Set<String> _pendingVendorFilters = const <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void open() {
    DebugConsole.clear();
    DebugConsole.log('[KeyboardFlow] VendorFilter debug cleared');
    setState(() {
      _pendingVendorFilters = {...widget.store.activeMerchantFilters};
      _open = true;
    });
    DebugConsole.log('[VendorFilter] shell open');
  }

  void close() {
    if (!_open) return;
    setState(() => _open = false);
    DebugConsole.log('[VendorFilter] shell closed');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return SlideUpMenuCard(
          cardKey: const ValueKey('vendor-filter-slide-card'),
          debugLabel: 'VendorFilter',
          visible: _open,
          panelHeight: panelHeight,
          onDismissed: close,
          dismissOnVeilTap: true,
          focusVeilPassthroughTop: 0,
          canDragFrom: _canDragVendorSheet,
          dragFromHandleOnly: true,
          dragHandleExtent: 72,
          verticalDragBias: 1.2,
          keyboardAvoidance: false,
          child: SafeArea(
            top: false,
            bottom: false,
            child: VendorFilterPanel(
              summaries: widget.store.vendorFilterSummaries,
              selectedVendors: _pendingVendorFilters,
              activeType: widget.store.activeType,
              scrollController: _scrollController,
              accentColor: widget.expenseTheme.accent,
              cardSurfaceColor: widget.expenseTheme.categoryCard,
              cardSurfaceStyle: widget.expenseTheme.categoryCardSurfaceStyle,
              avatarSurfaceStyle: widget.expenseTheme.buttonSurfaceStyle,
              buttonSurfaceStyle: widget.expenseTheme.buttonSurfaceStyle,
              onToggle: _togglePendingVendorFilter,
              onRename: _renameVendorFilterSummary,
              onResetName: _resetVendorFilterSummary,
              onApply: _applyVendorFilters,
            ),
          ),
        );
      },
    );
  }

  bool _canDragVendorSheet(
    Offset globalPosition,
    Offset startGlobalPosition,
    double gestureDx,
    double gestureDy,
  ) {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 0.5;
  }

  void _togglePendingVendorFilter(String vendor) {
    setState(() {
      final next = {..._pendingVendorFilters};
      if (!next.add(vendor)) next.remove(vendor);
      _pendingVendorFilters = next;
    });
  }

  Future<void> _renameVendorFilterSummary(
    VendorFilterSummary summary,
    String userAssignedName,
  ) async {
    final previousName = summary.name.trim();
    final nextName = userAssignedName.trim();
    if (nextName.isEmpty) return;
    await widget.store.renameTransactionsByOriginalMerchant(
      summary.originalName,
      nextName,
    );
    if (!mounted) return;
    setState(() {
      final nextFilters = {..._pendingVendorFilters};
      if (nextFilters.remove(previousName)) nextFilters.add(nextName);
      _pendingVendorFilters = nextFilters;
    });
  }

  Future<void> _resetVendorFilterSummary(VendorFilterSummary summary) async {
    final previousName = summary.name.trim();
    final nextName = summary.originalName.trim();
    await widget.store.resetTransactionNamesByOriginalMerchant(
      summary.originalName,
    );
    if (!mounted) return;
    setState(() {
      final nextFilters = {..._pendingVendorFilters};
      if (nextFilters.remove(previousName) && nextName.isNotEmpty) {
        nextFilters.add(nextName);
      }
      _pendingVendorFilters = nextFilters;
    });
  }

  void _applyVendorFilters() {
    widget.store.setMerchantFilters(_pendingVendorFilters);
    close();
  }
}

class _CategorySheetSlot extends StatefulWidget {
  const _CategorySheetSlot({
    super.key,
    required this.store,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;

  @override
  State<_CategorySheetSlot> createState() => _CategorySheetSlotState();
}

class _CategorySheetSlotState extends State<_CategorySheetSlot> {
  var _open = false;
  TransactionCategory? _initialCategory;

  void open({TransactionCategory? initialCategory}) {
    final label = initialCategory == null ? 'AddCategory' : 'EditCategory';
    DebugConsole.clear();
    DebugConsole.log('[KeyboardFlow] $label debug cleared');
    setState(() {
      _open = true;
      _initialCategory = initialCategory;
    });
  }

  void close() {
    if (!_open && _initialCategory == null) return;
    setState(() {
      _open = false;
      _initialCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return CategoryEditorSheet(
          activeType: widget.store.activeType,
          initialCategory: _initialCategory,
          panelHeight: _menuPanelHeight(context),
          visible: _open,
          surfaceColor: widget.expenseTheme.fieldSurface,
          bodySurfaceStyle: widget.expenseTheme.contentSurfaceStyle,
          buttonSurfaceStyle: widget.expenseTheme.buttonSurfaceStyle,
          selectedSurfaceStyle: widget.expenseTheme.forcedInsetSurfaceStyle,
          accentColor: widget.expenseTheme.accent,
          onClose: close,
          onSave: (draft) => unawaited(_saveCategory(draft)),
          onDelete: _initialCategory == null
              ? null
              : (category) => unawaited(_deleteCategory(category)),
        );
      },
    );
  }

  Future<void> _saveCategory(CategoryDraft draft) async {
    final initial = _initialCategory;
    if (initial == null) {
      await widget.store.addCategory(
        name: draft.name,
        type: draft.type,
        colorSlot: draft.colorSlot,
        iconSlot: draft.iconSlot,
      );
    } else {
      await widget.store.updateCategory(
        initial,
        name: draft.name,
        colorSlot: draft.colorSlot,
        iconSlot: draft.iconSlot,
      );
    }
    if (!mounted) return;
    close();
  }

  Future<void> _deleteCategory(TransactionCategory category) async {
    await widget.store.deleteCategory(category);
    if (!mounted) return;
    close();
  }

  double _menuPanelHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
  }
}

class _RecurringSheetSlot extends StatefulWidget {
  const _RecurringSheetSlot({
    super.key,
    required this.store,
    required this.nativeBridge,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final NativeBridge nativeBridge;
  final ExpenseTheme expenseTheme;

  @override
  State<_RecurringSheetSlot> createState() => _RecurringSheetSlotState();
}

class _RecurringSheetSlotState extends State<_RecurringSheetSlot> {
  var _open = false;
  DateTime? _openRequestedAt;

  void open({required DateTime requestedAt}) {
    setState(() {
      _open = true;
      _openRequestedAt = requestedAt;
    });
  }

  void close() {
    if (!_open && _openRequestedAt == null) return;
    setState(() {
      _open = false;
      _openRequestedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RecurringManagerSheet(
      store: widget.store,
      visible: _open,
      openRequestedAt: _openRequestedAt,
      expenseTheme: widget.expenseTheme,
      onLoadInstalledApps: widget.nativeBridge.listInstalledApps,
      onClose: close,
    );
  }
}

class _BudgetTargetSheetSlot extends StatefulWidget {
  const _BudgetTargetSheetSlot({
    super.key,
    required this.store,
    required this.activeKey,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final ValueNotifier<String?> activeKey;
  final ExpenseTheme expenseTheme;

  @override
  State<_BudgetTargetSheetSlot> createState() => _BudgetTargetSheetSlotState();
}

class _BudgetTargetSheetSlotState extends State<_BudgetTargetSheetSlot> {
  var _open = false;
  DateTime? _openRequestedAt;
  BackheaderBudgetItem? _item;

  void open(
    BackheaderBudgetItem item, {
    required DateTime requestedAt,
    required bool headerExpanded,
  }) {
    if (widget.activeKey.value != item.key) {
      widget.activeKey.value = item.key;
    }
    setState(() {
      _open = true;
      _item = item;
      _openRequestedAt = requestedAt;
    });
    DebugConsole.log(
      '[BudgetTargetEditor] backheader state queued '
      'headerExpanded=$headerExpanded elapsed=${_elapsedMs(requestedAt)}ms',
    );
  }

  void close() {
    if (!_open && _item == null && _openRequestedAt == null) return;
    setState(() {
      _open = false;
      _item = null;
      _openRequestedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final hostItem = _item ?? _defaultBudgetEditorItem();
        if (hostItem == null) return const SizedBox.shrink();
        return BudgetTargetEditorSheet(
          item: hostItem,
          openRequestedAt: _openRequestedAt,
          visible: _open,
          periodLabel: widget.store.activePeriodLabel,
          items: widget.store.backheaderBudgetItems,
          categoryBars: widget.store.categoryBudgetBars,
          overviewItems: widget.store.overviewBudgetItems,
          periodIncome: widget.store.activePeriodIncomeTotal,
          expenseTheme: widget.expenseTheme,
          onCancel: close,
          onActiveItemChanged: _setActiveItem,
          onSaveOverview:
              (kind, {required limitAmount, required alertActive}) async {
                await widget.store.saveOverviewLimit(
                  kind,
                  limitAmount: limitAmount,
                  alertActive: alertActive,
                );
              },
          onSaveCategory:
              (bar, {required limitAmount, required alertActive}) async {
                await widget.store.saveCategoryLimitForBar(
                  bar,
                  limitAmount: limitAmount,
                  alertActive: alertActive,
                );
              },
        );
      },
    );
  }

  void _setActiveItem(BackheaderBudgetItem item) {
    widget.activeKey.value = item.key;
  }

  BackheaderBudgetItem? _defaultBudgetEditorItem() {
    final items = widget.store.backheaderBudgetItems;
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.overview != null) return item;
    }
    return items.first;
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
