import 'package:flutter/material.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../core/categories/presentation/category_icon_view.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import 'partner_editor_popup.dart';
import 'manual_transaction_editor_field_rows.dart';
import 'manual_transaction_inline_picker_panel.dart';

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
  final FocusNode _searchFocus = FocusNode();
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
    _searchFocus.dispose();
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
                key: const ValueKey('manual-partner-search'),
                controller: _search,
                focusNode: _searchFocus,
                // The full-screen selector should open like the category
                // selector: show results first, and let an explicit tap start
                // a text session and show the native keyboard.
                autofocus: false,
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
                          leading: PartnerCategoryAvatar(partner: partner),
                          title: Text(partner.displayName),
                          subtitle: Text(partner.defaultCategoryName),
                          onTap: () => Navigator.of(context).pop(
                            ExistingManualPartner(
                              partner.partnerId,
                              directoryEntry: partner,
                            ),
                          ),
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

/// The one partner-default avatar used by both picker rows and selected
/// partner fields. Transaction category overrides intentionally never reach
/// this component.
final class PartnerCategoryAvatar extends StatelessWidget {
  const PartnerCategoryAvatar({
    super.key,
    required this.partner,
    this.size = 40,
    this.iconSize = 20,
    this.roundedSquare = false,
  });

  final PartnerDirectoryEntry partner;
  final double size;
  final double iconSize;
  final bool roundedSquare;

  @override
  Widget build(BuildContext context) {
    final colorHandle = CategoryColorCatalog.handleOf(partner.categoryColorId);
    final iconHandle = CategoryIconCatalog.handleOf(partner.categoryIconId);
    final atlas = PreparedVectorAssetAtlas.instance;
    final semanticName = CategoryIconCatalog.tokenForHandle(
      iconHandle,
    ).semanticName;
    return Semantics(
      label: '$semanticName · ${partner.defaultCategoryName}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: atlas.categoryGradient(
            colorHandle,
            profile: CategoryAvatarColorProfileScope.profileOf(context),
          ),
          shape: roundedSquare ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: roundedSquare
              ? BorderRadius.circular(size * .28)
              : null,
        ),
        alignment: Alignment.center,
        child: CategoryIconView(
          picture: atlas.categoryIcon(iconHandle),
          size: iconSize,
          color: Colors.white,
          semanticsLabel: semanticName,
        ),
      ),
    );
  }
}

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// In-flow counterpart to [PartnerSelector]. It shares its repository, avatar
/// and editor route, but deliberately lives in the editor's scroll content.
final class PartnerDropdown extends StatefulWidget {
  const PartnerDropdown({
    super.key,
    required this.repository,
    required this.categories,
    required this.selectedPartnerId,
    required this.onSelected,
    this.selectedPartner,
    this.enabled = true,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final String? selectedPartnerId;
  final PartnerDirectoryEntry? selectedPartner;
  final ValueChanged<ManualPartnerSelection> onSelected;
  final bool enabled;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  State<PartnerDropdown> createState() => PartnerDropdownState();
}

final class PartnerDropdownState extends State<PartnerDropdown> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<PartnerDirectoryEntry>? _partners;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    // An amount/note field may have been active before the anchor was tapped.
    // Clear it synchronously before the in-flow results appear, so the
    // keyboard never remains open underneath the partner list.
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onExpandedChanged(true);
    if (_partners != null) return;
    await _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final partners = await widget.repository.listPartners();
      if (mounted) setState(() => _partners = partners);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<PartnerDirectoryEntry> get _visible {
    final query = _normalize(_search.text);
    final source = _partners ?? const <PartnerDirectoryEntry>[];
    if (query.isEmpty) return source;
    return source
        .where((partner) {
          final names = <String>[
            partner.displayName,
            partner.originalName,
            ...partner.searchNames,
          ];
          return names.any((name) => _normalize(name).contains(query));
        })
        .toList(growable: false);
  }

  PartnerDirectoryEntry? get _selectedPartner {
    for (final partner in _partners ?? const <PartnerDirectoryEntry>[]) {
      if (partner.partnerId == widget.selectedPartnerId) return partner;
    }
    return widget.selectedPartner;
  }

  Future<void> _newPartner() async {
    widget.onExpandedChanged(false);
    final result = await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      initialName: _search.text.trim(),
    );
    if (mounted && result != null) widget.onSelected(result);
  }

  Future<void> _edit(PartnerDirectoryEntry partner) async {
    widget.onExpandedChanged(false);
    final result = await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      existing: partner,
    );
    if (!mounted) return;
    setState(() => _partners = null);
    await _load();
    if (mounted &&
        result is ExistingManualPartner &&
        result.partnerId == widget.selectedPartnerId) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = _selectedPartner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManualEditorSelectionRow(
          key: const ValueKey('manual-partner-dropdown-anchor'),
          label: 'Partner',
          value: partner?.displayName ?? 'Partner kiválasztása',
          valueSemantics: partner == null
              ? 'Partner kiválasztása legördülő listából'
              : 'Partner: ${partner.displayName}',
          leading: partner == null
              ? const ManualEditorIconSurface(
                  icon: Icons.storefront_outlined,
                  color: Color(0xff64748b),
                  background: Color(0xfff1f5f9),
                )
              : PartnerCategoryAvatar(
                  partner: partner,
                  size: 40,
                  iconSize: 20,
                  roundedSquare: true,
                ),
          enabled: widget.enabled,
          expanded: widget.expanded,
          onTap: () {
            if (widget.expanded) {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.onExpandedChanged(false);
            } else {
              _open();
            }
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: widget.expanded
              ? ManualTransactionInlinePickerPanel(
                  searchController: _search,
                  searchFocusNode: _searchFocus,
                  searchFieldKey: const ValueKey('manual-partner-search'),
                  searchHint: 'Partner keresése',
                  emptyMessage: 'Nincs találat.',
                  itemCount: _visible.length,
                  itemExtent: 64,
                  loading: _partners == null,
                  error: _error,
                  createLabel: 'Új partner',
                  createActionKey: const ValueKey(
                    'manual-partner-create-action',
                  ),
                  onCreate: _newPartner,
                  itemBuilder: (context, index) {
                    final item = _visible[index];
                    return _PartnerPickerRow(
                      key: ValueKey('manual-partner-${item.partnerId}'),
                      partner: item,
                      selected: item.partnerId == widget.selectedPartnerId,
                      onSelect: () {
                        widget.onExpandedChanged(false);
                        widget.onSelected(
                          ExistingManualPartner(
                            item.partnerId,
                            directoryEntry: item,
                          ),
                        );
                      },
                      onEdit: () => _edit(item),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

final class _PartnerPickerRow extends StatelessWidget {
  const _PartnerPickerRow({
    super.key,
    required this.partner,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final PartnerDirectoryEntry partner;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xffe6faf2) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            PartnerCategoryAvatar(
              partner: partner,
              size: 40,
              iconSize: 19,
              roundedSquare: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff172554),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    partner.defaultCategoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const ManualTransactionPickerCheck(),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                tooltip: 'Partner szerkesztése',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: Color(0xff64748b),
                ),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
