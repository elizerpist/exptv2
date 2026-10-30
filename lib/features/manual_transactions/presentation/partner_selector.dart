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
  });

  final PartnerDirectoryEntry partner;
  final double size;
  final double iconSize;

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
          shape: BoxShape.circle,
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

/// Anchored counterpart to [PartnerSelector]. It deliberately shares the
/// repository, row avatar and partner-editor route with the fullscreen picker;
/// only its presentation differs.
final class PartnerDropdown extends StatefulWidget {
  const PartnerDropdown({
    super.key,
    required this.repository,
    required this.categories,
    required this.selectedPartnerId,
    required this.onSelected,
    this.selectedPartner,
    this.enabled = true,
  });

  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final String? selectedPartnerId;
  final PartnerDirectoryEntry? selectedPartner;
  final ValueChanged<ManualPartnerSelection> onSelected;
  final bool enabled;

  @override
  State<PartnerDropdown> createState() => PartnerDropdownState();
}

final class PartnerDropdownState extends State<PartnerDropdown> {
  final MenuController _controller = MenuController();
  final TextEditingController _search = TextEditingController();
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
    super.dispose();
  }

  void close() => _controller.close();

  Future<void> _open() async {
    _controller.open();
    if (_partners != null) return;
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
    _controller.close();
    final result = await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      initialName: _search.text.trim(),
    );
    if (mounted && result != null) widget.onSelected(result);
  }

  Future<void> _edit(PartnerDirectoryEntry partner) async {
    _controller.close();
    await showPartnerEditorPopup(
      context,
      repository: widget.repository,
      categories: widget.categories,
      existing: partner,
    );
    if (mounted) setState(() => _partners = null);
  }

  @override
  Widget build(BuildContext context) {
    final partner = _selectedPartner;
    final availableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                24)
            .clamp(220, 420)
            .toDouble();
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: availableHeight,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
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
                    : _visible.isEmpty
                    ? const Center(child: Text('Nincs találat.'))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _visible.length,
                        itemBuilder: (context, index) {
                          final partner = _visible[index];
                          return ListTile(
                            dense: true,
                            leading: PartnerCategoryAvatar(
                              partner: partner,
                              size: 32,
                              iconSize: 16,
                            ),
                            title: Text(partner.displayName),
                            subtitle: Text(partner.defaultCategoryName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (partner.partnerId ==
                                    widget.selectedPartnerId)
                                  const Icon(Icons.check_rounded),
                                IconButton(
                                  tooltip: 'Partner szerkesztése',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(partner),
                                ),
                              ],
                            ),
                            onTap: () {
                              _controller.close();
                              widget.onSelected(
                                ExistingManualPartner(
                                  partner.partnerId,
                                  directoryEntry: partner,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: const Text('Új partner'),
                onTap: _newPartner,
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) => Semantics(
        button: true,
        label: 'Partner kiválasztása legördülő listából',
        child: InkWell(
          key: const ValueKey('manual-partner-dropdown-anchor'),
          borderRadius: BorderRadius.circular(16),
          onTap: widget.enabled
              ? () => controller.isOpen ? controller.close() : _open()
              : null,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Partner',
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: partner == null
                ? const Text('Partner kiválasztása')
                : Row(
                    children: [
                      PartnerCategoryAvatar(
                        partner: partner,
                        size: 28,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partner.displayName),
                            Text(
                              partner.defaultCategoryName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
