import 'package:flutter/material.dart';

import '../../core/debug/debug_console.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../state/event_store.dart';
import '../notifications/notifications_page.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/settings_page.dart';
import '../settings/theme/expense_theme.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
import '../transactions/widgets/transaction_menu_metrics.dart';
import 'app_tab.dart';
import 'widgets/blank_tab_page.dart';
import 'widgets/expt_bottom_nav.dart';
import 'widgets/expt_fab.dart';

class ExptShell extends StatefulWidget {
  const ExptShell({super.key, required this.store, required this.nativeBridge});

  final EventStore store;
  final NativeBridge nativeBridge;

  @override
  State<ExptShell> createState() => _ExptShellState();
}

class _ExptShellState extends State<ExptShell> {
  AppTab _activeTab = AppTab.home;
  late final TransactionStore _transactionStore;
  var _transactionEditorOpen = false;
  var _homeBlockingOverlayOpen = false;
  TransactionRecord? _editingTransaction;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();

  @override
  void initState() {
    super.initState();
    DebugConsole.log('[Shell] start');
    _transactionStore = TransactionStore(
      TransactionRepository(widget.nativeBridge),
    );
    _loadThemeSettings();
  }

  @override
  void dispose() {
    _transactionStore.dispose();
    super.dispose();
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
      _homeBlockingOverlayOpen = false;
      _editingTransaction = null;
    });
  }

  void _handleFabPressed() {
    if (_activeTab != AppTab.home) return;
    setState(() {
      _transactionEditorOpen = true;
      _editingTransaction = null;
    });
  }

  void _openEditTransaction(TransactionRecord transaction) {
    setState(() {
      _transactionEditorOpen = true;
      _editingTransaction = transaction;
    });
  }

  void _closeTransactionEditor() {
    setState(() {
      _transactionEditorOpen = false;
      _editingTransaction = null;
    });
  }

  void _setHomeBlockingOverlay(bool open) {
    if (_homeBlockingOverlayOpen == open) return;
    setState(() => _homeBlockingOverlayOpen = open);
  }

  Future<void> _confirmDeleteTransaction(TransactionRecord transaction) async {
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
    if (confirmed != true) return;

    final deleted = await _transactionStore.deleteTransaction(transaction);
    if (!mounted || !deleted) return;
    if (_editingTransaction?.id == transaction.id) {
      _closeTransactionEditor();
    }
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
                  onEditTransaction: _openEditTransaction,
                  onDeleteTransactionRequested: _confirmDeleteTransaction,
                  onBlockingOverlayChanged: _setHomeBlockingOverlay,
                ),
                const BlankTabPage(tab: AppTab.groceries),
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
              child: Center(child: ExptFab(onPressed: _handleFabPressed)),
            ),
          if (_activeTab == AppTab.home && _transactionEditorOpen)
            Positioned(
              left: 0,
              right: 0,
              top: TransactionMenuMetrics.overlayTop,
              bottom: 0,
              child: AddTransactionSheet(
                store: _transactionStore,
                initialTransaction: _editingTransaction,
                onClose: _closeTransactionEditor,
              ),
            ),
          const DebugFloatingButton(),
        ],
      ),
    );
  }
}
