import 'package:flutter/material.dart';

import '../../../core/categories/domain/fluvi_category.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import 'category_dropdown.dart';

/// Opens the compact partner editor. Existing partners commit globally; a new
/// partner is returned as a draft and is persisted only with its transaction.
Future<ManualPartnerSelection?> showPartnerEditorPopup(
  BuildContext context, {
  required ManualTransactionRepository repository,
  required List<FluviCategory> categories,
  PartnerDirectoryEntry? existing,
  String initialName = '',
}) => showDialog<ManualPartnerSelection>(
  context: context,
  builder: (context) => _PartnerEditorPopup(
    repository: repository,
    categories: categories,
    existing: existing,
    initialName: initialName,
  ),
);

final class _PartnerEditorPopup extends StatefulWidget {
  const _PartnerEditorPopup({
    required this.repository,
    required this.categories,
    required this.existing,
    required this.initialName,
  });
  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final PartnerDirectoryEntry? existing;
  final String initialName;

  @override
  State<_PartnerEditorPopup> createState() => _PartnerEditorPopupState();
}

final class _PartnerEditorPopupState extends State<_PartnerEditorPopup> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? widget.initialName,
  );
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryId =
        widget.existing?.defaultCategoryId ??
        widget.categories
            .where((category) => category.isSystemUncategorized)
            .firstOrNull
            ?.id ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final categoryId = _categoryId;
    if (name.isEmpty || categoryId == null) {
      setState(() => _error = 'Adj meg nevet és alapértelmezett kategóriát.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing == null) {
        if (mounted) {
          Navigator.of(context).pop(
            NewManualPartner(displayName: name, defaultCategoryId: categoryId),
          );
        }
        return;
      }
      final updated = await widget.repository.updatePartner(
        partnerId: existing.partnerId,
        displayNameOverride: name == existing.originalName ? null : name,
        defaultCategoryId: categoryId,
      );
      if (mounted) {
        Navigator.of(context).pop(ExistingManualPartner(updated.partnerId));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'A partner mentése nem sikerült: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? 'Partner szerkesztése' : 'Új partner'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: !editing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Partner neve'),
              ),
              const SizedBox(height: 16),
              CategoryDropdown(
                categories: widget.categories,
                selectedCategoryId: _categoryId,
                onSelected: (value) => setState(() => _categoryId = value),
                label: 'Alapértelmezett kategória',
              ),
              if (editing) ...[
                const SizedBox(height: 16),
                const Text(
                  'A kategória módosítása a korábbi örökölt tranzakciókat és a kapcsolódó öröklő ismétlődő szabályokat is érintheti. Az egyedi kategóriafelülírások megmaradnak.',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? 'Mentés…'
                : editing
                ? 'Mentés'
                : 'Alkalmaz',
          ),
        ),
      ],
    );
  }
}

extension on Iterable<FluviCategory> {
  FluviCategory? get firstOrNull => isEmpty ? null : first;
}
