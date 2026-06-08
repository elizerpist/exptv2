import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/debug/debug_console.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../services/recurring_alarm_service.dart';
import '../../state/event_store.dart';
import '../notifications/data/notification_repository.dart';
import '../notifications/notifications_page.dart';
import '../notifications/state/notification_store.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/models/fast_info_config.dart';
import '../settings/settings_page.dart';
import '../settings/theme/expense_theme.dart';
import '../stats/stats_page.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/models/backheader_budget_item.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/sync/google_sheets_sync_controller.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
import '../transactions/widgets/category_menu/category_editor_panel.dart';
import '../transactions/widgets/category_menu/category_editor_sheet.dart';
import '../transactions/widgets/header_card/budget_target_editor_sheet.dart';
import '../transactions/widgets/transaction_menu_metrics.dart';
import '../transactions/widgets/recurring_manager_sheet.dart';
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
  AppTab _activeTab = AppTab.home;
  late final TransactionStore _transactionStore;
  late final NotificationStore _notificationStore;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DebugConsole.log('[Shell] start');
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
    unawaited(_transactionStore.start());
    _transactionHomePage = _buildTransactionHomePage();
    _requestPostNotificationsOnFirstLaunch();
    unawaited(_notificationStore.start());
    unawaited(_syncRecurringAlarms());
    unawaited(_loadShellSettings());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _budgetEditorActiveKey.dispose();
    _transactionStore.dispose();
    _notificationStore.removeListener(_handleNotificationStoreChanged);
    _notificationStore.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_processRecurringOnResume());
  }

  @override
  void didChangeMetrics() {
    final startedAt = DateTime.now();
    final inset = _platformKeyboardInset();
    final previous = _lastKeyboardInset;
    _lastKeyboardInset = inset;
    DebugConsole.log(
      '[Perf] Keyboard metrics changed inset=${inset.toStringAsFixed(1)} '
      'previous=${previous.toStringAsFixed(1)} '
      'delta=${(inset - previous).toStringAsFixed(1)} '
      'activeTab=${_activeTab.id} homeOverlay=$_homeBlockingOverlayOpen',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[Perf] Keyboard metrics frame inset=${_platformKeyboardInset().toStringAsFixed(1)} '
        'elapsed=${_elapsedMs(startedAt)}ms activeTab=${_activeTab.id}',
      );
    });
  }

  double _platformKeyboardInset() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 0;
    final view = views.first;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  double _contextKeyboardInset() {
    return MediaQuery.maybeOf(context)?.viewInsets.bottom ?? _lastKeyboardInset;
  }

  int _elapsedMs(DateTime startedAt) {
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  TransactionHomePage _buildTransactionHomePage() {
    return TransactionHomePage(
      store: _transactionStore,
      expenseTheme: ExpenseTheme.fromSettings(_themeSettings),
      fastInfoConfig: _fastInfoConfig,
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
      onFocusedSheetDismissRequested: () {
        _sheetHostKey.currentState?.closeAll();
      },
      onAddCategoryEditorRequested: () {
        _sheetHostKey.currentState?.openCategory();
      },
      onEditCategoryEditorRequested: (category) {
        _sheetHostKey.currentState?.openCategory(initialCategory: category);
      },
      budgetEditorActiveKey: _budgetEditorActiveKey,
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
      await _transactionStore.refreshAfterRecurringProcessing();
    } catch (error) {
      DebugConsole.log('[RecurringAlarm] resume processing failed: $error');
    }
  }

  Future<void> _loadShellSettings() async {
    final payload = await widget.nativeBridge.expenseLoadSettings();
    if (!mounted) return;
    setState(() {
      _themeSettings = payload.themeSettings;
      _fastInfoConfig = payload.fastInfoConfig;
      _transactionHomePage = _buildTransactionHomePage();
    });
  }

  void _handleNotificationStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshNotificationsAfterTransactionChange() async {
    await _notificationStore.refresh();
    if (_activeTab == AppTab.notifications) {
      await _notificationStore.markAllUnreadRead();
    }
  }

  void _applyThemeSettings(AppThemeSettings settings) {
    setState(() {
      _themeSettings = settings;
      _transactionHomePage = _buildTransactionHomePage();
    });
    DebugConsole.log(
      '[ThemeSurface] shell apply ${_settingsSignature(settings)}',
    );
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
        'keyboard=${_contextKeyboardInset().toStringAsFixed(1)}',
      );
      return;
    }
    final requestedAt = DateTime.now();
    final previous = _activeTab;
    DebugConsole.log(
      '[Perf] BottomNav tap from=${previous.id} to=${tab.id} '
      'homeOverlay=$_homeBlockingOverlayOpen '
      'keyboard=${_contextKeyboardInset().toStringAsFixed(1)}',
    );
    _sheetHostKey.currentState?.closeAll();
    DebugConsole.log(
      '[Perf] BottomNav close sheets issued from=${previous.id} to=${tab.id} '
      'elapsed=${_elapsedMs(requestedAt)}ms',
    );
    setState(() {
      _activeTab = tab;
      _homeBlockingOverlayOpen = false;
    });
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
        'keyboard=${_contextKeyboardInset().toStringAsFixed(1)}',
      );
    });
  }

  void _jumpToTabPage(AppTab tab, DateTime requestedAt) {
    final pageIndex = appTabs.indexOf(tab);
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
          unreadNotificationCount: _notificationStore.unreadCount,
          onTabSelected: _selectTab,
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: AppDimensions.fabBottom,
        child: Center(
          child: ExptFab(
            primaryColor: expenseTheme.accent,
            surfaceStyle: expenseTheme.buttonSurfaceStyle,
            onPressed: _handleFabPressed,
            onLongPress: _handleFabLongPressed,
          ),
        ),
      ),
    ];
  }

  Widget _buildShellPage(AppTab tab, ExpenseTheme expenseTheme) {
    switch (tab) {
      case AppTab.home:
        return _transactionHomePage;
      case AppTab.stats:
        return StatsPage(store: _transactionStore, expenseTheme: expenseTheme);
      case AppTab.notifications:
        return NotificationsPage(
          nativeBridge: widget.nativeBridge,
          store: _notificationStore,
          expenseTheme: expenseTheme,
          active: false,
        );
      case AppTab.settings:
        return SettingsPage(
          store: widget.store,
          nativeBridge: widget.nativeBridge,
          googleSheetsSyncController: widget.googleSheetsSyncController,
          expenseTheme: expenseTheme,
          onThemeSettingsChanged: _applyThemeSettings,
          onFastInfoConfigChanged: _applyFastInfoConfig,
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
          ...shellNavigation,
          DebugFloatingButton(
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
}

class _ShellSheetHost extends StatefulWidget {
  const _ShellSheetHost({
    super.key,
    required this.store,
    required this.nativeBridge,
    required this.budgetEditorActiveKey,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final NativeBridge nativeBridge;
  final ValueNotifier<String?> budgetEditorActiveKey;
  final ExpenseTheme expenseTheme;

  @override
  State<_ShellSheetHost> createState() => _ShellSheetHostState();
}

class _ShellSheetHostState extends State<_ShellSheetHost> {
  final _transactionSlotKey = GlobalKey<_TransactionSheetSlotState>();
  final _categorySlotKey = GlobalKey<_CategorySheetSlotState>();
  final _recurringSlotKey = GlobalKey<_RecurringSheetSlotState>();
  final _budgetSlotKey = GlobalKey<_BudgetTargetSheetSlotState>();

  void openTransaction({
    required DateTime requestedAt,
    required String source,
    TransactionRecord? transaction,
  }) {
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _transactionSlotKey.currentState?.open(
      requestedAt: requestedAt,
      source: source,
      transaction: transaction,
    );
  }

  void openCategory({TransactionCategory? initialCategory}) {
    _transactionSlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _categorySlotKey.currentState?.open(initialCategory: initialCategory);
  }

  void openRecurring() {
    _transactionSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
    _recurringSlotKey.currentState?.open(requestedAt: DateTime.now());
  }

  void openBudgetTargetEditor(
    BackheaderBudgetItem item, {
    required DateTime requestedAt,
    required bool headerExpanded,
  }) {
    _transactionSlotKey.currentState?.close();
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
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
    _categorySlotKey.currentState?.close();
    _recurringSlotKey.currentState?.close();
    _budgetSlotKey.currentState?.close();
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
      ],
    );
  }
}

class _TransactionSheetSlot extends StatefulWidget {
  const _TransactionSheetSlot({
    super.key,
    required this.store,
    required this.expenseTheme,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;

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
      onClose: close,
    );
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
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
