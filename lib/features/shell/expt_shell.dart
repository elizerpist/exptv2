import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/debug/debug_console.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../services/recurring_alarm_service.dart';
import '../../state/event_store.dart';
import '../notifications/notifications_page.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/settings_page.dart';
import '../settings/theme/expense_theme.dart';
import '../stats/stats_page.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
import '../transactions/widgets/category_menu/category_editor_panel.dart';
import '../transactions/widgets/category_menu/category_editor_sheet.dart';
import 'app_tab.dart';
import 'widgets/expt_bottom_nav.dart';
import 'widgets/expt_fab.dart';

class ExptShell extends StatefulWidget {
  const ExptShell({super.key, required this.store, required this.nativeBridge});

  final EventStore store;
  final NativeBridge nativeBridge;

  @override
  State<ExptShell> createState() => _ExptShellState();
}

class _ExptShellState extends State<ExptShell> with WidgetsBindingObserver {
  AppTab _activeTab = AppTab.home;
  late final TransactionStore _transactionStore;
  late final RecurringAlarmService _recurringAlarmService;
  var _transactionEditorOpen = false;
  var _categoryEditorOpen = false;
  var _homeBlockingOverlayOpen = false;
  var _budgetEditorOpenRequest = 0;
  TransactionRecord? _editingTransaction;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DebugConsole.log('[Shell] start');
    _recurringAlarmService = RecurringAlarmService();
    _transactionStore = TransactionStore(
      TransactionRepository(widget.nativeBridge),
    );
    unawaited(_syncRecurringAlarms());
    unawaited(_loadThemeSettings());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transactionStore.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_processRecurringOnResume());
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

  Future<void> _loadThemeSettings() async {
    final payload = await widget.nativeBridge.expenseLoadSettings();
    if (!mounted) return;
    setState(() => _themeSettings = payload.themeSettings);
  }

  void _applyThemeSettings(AppThemeSettings settings) {
    setState(() => _themeSettings = settings);
  }

  void _selectTab(AppTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _transactionEditorOpen = false;
      _categoryEditorOpen = false;
      _homeBlockingOverlayOpen = false;
      _editingTransaction = null;
    });
  }

  void _handleFabPressed() {
    setState(() {
      _transactionEditorOpen = true;
      _categoryEditorOpen = false;
      _editingTransaction = null;
    });
  }

  void _handleFabLongPressed() {
    setState(() {
      _transactionEditorOpen = false;
      _categoryEditorOpen = true;
      _editingTransaction = null;
    });
  }

  void _handleFabDoubleTapped() {
    setState(() {
      _activeTab = AppTab.home;
      _transactionEditorOpen = false;
      _categoryEditorOpen = false;
      _editingTransaction = null;
      _homeBlockingOverlayOpen = true;
      _budgetEditorOpenRequest += 1;
    });
  }

  void _openEditTransaction(TransactionRecord transaction) {
    setState(() {
      _transactionEditorOpen = true;
      _categoryEditorOpen = false;
      _editingTransaction = transaction;
    });
  }

  void _closeTransactionEditor() {
    setState(() {
      _transactionEditorOpen = false;
      _editingTransaction = null;
    });
  }

  void _closeCategoryEditor() {
    setState(() => _categoryEditorOpen = false);
  }

  Future<void> _saveCategory(CategoryDraft draft) async {
    await _transactionStore.addCategory(
      name: draft.name,
      type: draft.type,
      colorSlot: draft.colorSlot,
      iconSlot: draft.iconSlot,
    );
    if (!mounted) return;
    setState(() => _categoryEditorOpen = false);
  }

  void _setHomeBlockingOverlay(bool open) {
    if (_homeBlockingOverlayOpen == open) return;
    setState(() => _homeBlockingOverlayOpen = open);
  }


  double _menuPanelHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final requested = screenHeight * 0.55;
    final compactHeight = requested < 520.0 ? requested : 520.0;
    return compactHeight.clamp(0.0, screenHeight).toDouble();
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
    if (_editingTransaction?.id == transaction.id) {
      _closeTransactionEditor();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final expenseTheme = ExpenseTheme.fromSettings(_themeSettings);
    final hideShellNavigation =
        _activeTab == AppTab.home && _homeBlockingOverlayOpen;
    return Scaffold(
      backgroundColor: expenseTheme.appBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: appTabs.indexOf(_activeTab),
              children: [
                TransactionHomePage(
                  store: _transactionStore,
                  expenseTheme: expenseTheme,
                  budgetEditorOpenRequest: _budgetEditorOpenRequest,
                  onEditTransaction: _openEditTransaction,
                  onDeleteTransactionRequested: _confirmDeleteTransaction,
                  onBlockingOverlayChanged: _setHomeBlockingOverlay,
                ),
                StatsPage(store: _transactionStore),
                NotificationsPage(nativeBridge: widget.nativeBridge),
                SettingsPage(
                  store: widget.store,
                  nativeBridge: widget.nativeBridge,
                  expenseTheme: expenseTheme,
                  onThemeSettingsChanged: _applyThemeSettings,
                ),
              ],
            ),
          ),
          if (!hideShellNavigation)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ExptBottomNav(
                activeTab: _activeTab,
                onTabSelected: _selectTab,
              ),
            ),
          if (!hideShellNavigation)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppDimensions.fabBottom,
              child: Center(
                child: ExptFab(
                  onPressed: _handleFabPressed,
                  onLongPress: _handleFabLongPressed,
                  onDoubleTap: _handleFabDoubleTapped,
                ),
              ),
            ),
          DebugFloatingButton(
            recurringAlarmService: _recurringAlarmService,
            onRecurringChanged: _transactionStore.refreshAfterRecurringProcessing,
          ),
          if (_transactionEditorOpen)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: AddTransactionSheet(
                store: _transactionStore,
                initialTransaction: _editingTransaction,
                onClose: _closeTransactionEditor,
              ),
            ),
          if (_categoryEditorOpen)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: CategoryEditorSheet(
                activeType: _transactionStore.activeType,
                panelHeight: _menuPanelHeight(context),
                onClose: _closeCategoryEditor,
                onSave: _saveCategory,
              ),
            ),
        ],
      ),
    );
  }
}
