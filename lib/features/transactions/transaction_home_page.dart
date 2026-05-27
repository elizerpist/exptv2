import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/transaction_category.dart';
import 'state/transaction_store.dart';
import 'widgets/search_pill.dart';
import 'widgets/summary_pill.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({super.key, required this.store});

  final TransactionStore store;

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage> {
  @override
  void initState() {
    super.initState();
    widget.store.start();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
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

          return Column(
            children: [
              const SizedBox(height: 185),
              TransactionTypePills(
                activeType: widget.store.activeType,
                onChanged: widget.store.setActiveType,
              ),
              SummaryPill(
                title: widget.store.activeType == TransactionType.income
                    ? 'Bevételek'
                    : 'Kiadások',
                value: widget.store.activeSummary.formattedFor(
                  widget.store.activeType,
                ),
                onSwipe: widget.store.cycleSummaryWindow,
              ),
              SearchPill(
                query: widget.store.searchQuery,
                onQueryChanged: widget.store.setSearchQuery,
                merchantFilter: widget.store.merchantFilter,
                filteredCount: widget.store.visibleTransactions.length,
                onClearMerchant: widget.store.clearMerchantFilter,
              ),
              Expanded(
                child: TransactionLogList(
                  records: widget.store.visibleTransactions,
                  categories: widget.store.categories,
                  onFastFilter: widget.store.setMerchantFilter,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
