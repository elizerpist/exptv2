import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/widgets/calendar_menu/calendar_menu_overlay.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.store});

  final TransactionStore store;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('stats-page'),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.bottomNavHeight),
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            if (store.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (store.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    store.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              );
            }
            return CalendarMenuOverlay(
              fullScreen: true,
              transactions: store.transactions,
              categories: store.categories,
              onClose: () {},
              onMonthSelect: (_, _) {},
            );
          },
        ),
      ),
    );
  }
}
