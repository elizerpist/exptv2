import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_visual_resolver.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import 'partner_editor_popup.dart';

/// Fullscreen partner picker. It queries once, then filters its immutable
/// in-memory snapshot for every keystroke.
final class PartnerSelector extends StatefulWidget {
  const PartnerSelector({
    super.key,
    required this.repository,
    required this.categories,
  });
  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;

  @override
  State<PartnerSelector> createState() => _PartnerSelectorState();
}

final class _PartnerSelectorState extends State<PartnerSelector> {
  final TextEditingController _search = TextEditingController();
  List<PartnerDirectoryEntry>? _partners;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.repository.listPartners();
      if (mounted) setState(() => _partners = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<PartnerDirectoryEntry> get _visible {
    final source = _partners ?? const <PartnerDirectoryEntry>[];
    final query = _normalize(_search.text);
    if (query.isEmpty) return source;
    final exact = <PartnerDirectoryEntry>[];
    final partial = <PartnerDirectoryEntry>[];
    for (final partner in source) {
      final display = _normalize(partner.displayName);
      final original = _normalize(partner.originalName);
      final aliases = partner.searchNames.map(_normalize);
      if (display.startsWith(query) ||
          original.startsWith(query) ||
          aliases.any((alias) => alias.startsWith(query))) {
        exact.add(partner);
      } else if (display.contains(query) ||
          original.contains(query) ||
          aliases.any((alias) => alias.contains(query))) {
        partial.add(partner);
      }
    }
    return [...exact, ...partial];
  }

  Future<void> _edit(PartnerDirectoryEntry partner) async {
    await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      existing: partner,
    );
    await _load();
  }

  Future<void> _newPartner() async {
    final result = await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      initialName: _search.text.trim(),
    );
    if (!mounted || result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final partners = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner kiválasztása'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Partner keresése',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Text('A partnerlista nem tölthető be: $_error'),
                    )
                  : _partners == null
                  ? const Center(child: CircularProgressIndicator())
                  : partners.isEmpty
                  ? Center(
                      child: Text(
                        _search.text.trim().isEmpty
                            ? 'Még nincs partner.'
                            : 'Nincs találat.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: partners.length,
                      itemBuilder: (context, index) {
                        final partner = partners[index];
                        return ListTile(
                          key: ValueKey('manual-partner-${partner.partnerId}'),
                          leading: _PartnerAvatar(partner: partner),
                          title: Text(partner.displayName),
                          subtitle: Text(partner.defaultCategoryName),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(ExistingManualPartner(partner.partnerId)),
                          trailing: IconButton(
                            tooltip: 'Partner szerkesztése',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(partner),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _newPartner,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Új partner'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.partner});
  final PartnerDirectoryEntry partner;
  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisualResolver.resolve(
      colorId: partner.categoryColorId,
      iconId: partner.categoryIconId,
    );
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: visual.gradient.gradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white),
    );
  }
}

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
