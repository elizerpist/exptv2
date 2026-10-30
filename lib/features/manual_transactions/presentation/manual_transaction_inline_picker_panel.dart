import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';

/// Shared in-flow material for the editor's partner and category pickers.
///
/// This is deliberately not a [MenuAnchor]: the panel participates in the
/// editor's scrollable layout, so opening it pushes the later editor fields
/// down rather than covering them.
final class ManualTransactionInlinePickerPanel extends StatelessWidget {
  const ManualTransactionInlinePickerPanel({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchFieldKey,
    required this.searchHint,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    required this.createLabel,
    required this.createActionKey,
    required this.onCreate,
    this.loading = false,
    this.error,
    this.itemExtent = 60,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Key searchFieldKey;
  final String searchHint;
  final String emptyMessage;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String createLabel;
  final Key createActionKey;
  final VoidCallback? onCreate;
  final bool loading;
  final Object? error;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screen = MediaQuery.sizeOf(context).height;
    // The editor itself remains scrollable. This cap only prevents a long
    // result set from monopolising a short screen or an open keyboard.
    final maxListHeight = math.max(
      112.0,
      math.min(300.0, screen - keyboard - 300),
    );
    final wantedListHeight = loading || error != null || itemCount == 0
        ? 76.0
        : itemCount * itemExtent;
    final listHeight = math.min(wantedListHeight, maxListHeight);
    return Container(
      key: const ValueKey('manual-inline-picker-panel'),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14524b93),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: TextField(
              key: searchFieldKey,
              controller: searchController,
              focusNode: searchFocusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xfff1f5f9),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: FluviVisualTokens.textSecondary,
                ),
                hintText: searchHint,
                hintStyle: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Color(0xffcbd5e1)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: listHeight,
            child: loading
                ? const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'A lista most nem tölthető be: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: FluviVisualTokens.textSecondary,
                        ),
                      ),
                    ),
                  )
                : itemCount == 0
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                      ),
                    ),
                  )
                : Scrollbar(
                    child: ListView.separated(
                      key: const ValueKey('manual-inline-picker-results'),
                      primary: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: itemCount,
                      itemBuilder: itemBuilder,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(left: 52),
                        child: Divider(height: 1, color: Color(0xffeef2f7)),
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1, color: Color(0xffe2e8f0)),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: TextButton.icon(
              key: createActionKey,
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(createLabel),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: const Color(0xff6d28d9),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected-state affordance is shared across partner and category rows.
final class ManualTransactionPickerCheck extends StatelessWidget {
  const ManualTransactionPickerCheck({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('manual-inline-picker-selected-check'),
    width: 24,
    height: 24,
    decoration: const BoxDecoration(
      color: Color(0xff13a58c),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
  );
}
