import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../state/event_store.dart';
import '../settings/settings_page.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _transactionStore = TransactionStore(
      TransactionRepository(widget.nativeBridge),
    );
  }

  @override
  void dispose() {
    _transactionStore.dispose();
    super.dispose();
  }

  void _selectTab(AppTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  void _handleFabPressed() {
    if (_activeTab != AppTab.home) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => AddTransactionSheet(store: _transactionStore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.bottomNavHeight,
              ),
              child: IndexedStack(
                index: appTabs.indexOf(_activeTab),
                children: [
                  TransactionHomePage(store: _transactionStore),
                  const BlankTabPage(tab: AppTab.groceries),
                  const BlankTabPage(tab: AppTab.notifications),
                  SettingsPage(store: widget.store),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ExptBottomNav(
              activeTab: _activeTab,
              onTabSelected: _selectTab,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppDimensions.fabBottom,
            child: Center(child: ExptFab(onPressed: _handleFabPressed)),
          ),
        ],
      ),
    );
  }
}
