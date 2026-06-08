import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../settings/theme/expense_theme.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/widgets/calendar_menu/calendar_menu_overlay.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.store, this.expenseTheme});

  final TransactionStore store;
  final ExpenseTheme? expenseTheme;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin<StatsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      key: const ValueKey('stats-page'),
      color: widget.expenseTheme?.appBackground ?? AppColors.white,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.bottomNavHeight),
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            if (widget.store.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (widget.store.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    widget.store.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              );
            }
            return CalendarMenuOverlay(
              fullScreen: true,
              transactions: widget.store.transactions,
              categories: widget.store.categories,
              onClose: () {},
              onMonthSelect: (_, _) {},
            );
          },
        ),
      ),
    );
  }
}
