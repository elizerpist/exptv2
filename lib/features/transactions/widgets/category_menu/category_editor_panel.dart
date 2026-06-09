import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/transaction_category.dart';
import '../../slots/category_icon_manager.dart';
import '../themed_pill_field.dart';
import 'category_preview_pill.dart';
import 'category_slot_grid.dart';
import 'icon_selector_sheet.dart';

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.type,
    required this.colorSlot,
    required this.iconSlot,
    this.id,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final int colorSlot;
  final int iconSlot;
}

class CategoryEditorPanel extends StatefulWidget {
  const CategoryEditorPanel({
    super.key,
    required this.activeType,
    required this.onSave,
    required this.onClose,
    this.initialCategory,
    this.onDelete,
    this.surfaceColor = AppColors.white,
    this.bodySurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.buttonSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.selectedSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  });

  final TransactionType activeType;
  final TransactionCategory? initialCategory;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory>? onDelete;
  final VoidCallback onClose;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction bodySurfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
  final Color accentColor;

  @override
  State<CategoryEditorPanel> createState() => _CategoryEditorPanelState();
}

class _CategoryEditorPanelState extends State<CategoryEditorPanel> {
  late final TextEditingController _name;
  late final FocusNode _nameFocus;
  DateTime? _focusStartedAt;
  late int _colorSlot;
  late int _iconSlot;
  var _page = 0;
  String? _error;
  double _dragDx = 0;
  double _visualDx = 0;
  var _slotPageDragging = false;

  bool get _editing => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategory;
    _name = TextEditingController(text: category?.name ?? '');
    _nameFocus = FocusNode()..addListener(_handleNameFocusChanged);
    _colorSlot = category?.colorSlot ?? 0;
    _iconSlot = category?.iconSlot ?? 0;
  }

  @override
  void dispose() {
    _nameFocus
      ..removeListener(_handleNameFocusChanged)
      ..dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing
        ? 'Kategória módosítása'
        : widget.activeType == TransactionType.income
        ? 'Új bevételi kategória'
        : 'Új kiadási kategória';
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              if (_editing && widget.onDelete != null)
                Positioned(
                  right: 12,
                  child: IconButton(
                    key: const ValueKey('category-editor-delete-button'),
                    onPressed: () => widget.onDelete!(widget.initialCategory!),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                    ),
                    splashRadius: 22,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kategória neve',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ThemedPillField(
                  fieldKey: const ValueKey('category-name-input'),
                  debugLabel: 'CategoryEditor.name',
                  controller: _name,
                  focusNode: _nameFocus,
                  label: 'Kategória neve',
                  surfaceColor: widget.surfaceColor,
                  surfaceStyle: widget.bodySurfaceStyle,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      _page == 0 ? 'Válassz színt' : 'Válassz ikont',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 32,
                      child: IconButton(
                        key: const ValueKey('category-slot-toggle-button'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.gray100,
                          foregroundColor: AppColors.gray700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.gray200),
                          ),
                        ),
                        onPressed: _toggleSlotPage,
                        icon: Icon(
                          _page == 0
                              ? Icons.grid_view_rounded
                              : Icons.palette_outlined,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  key: const ValueKey('category-slot-page-view'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _startSlotPageDrag,
                  onHorizontalDragUpdate: _updateSlotPageDrag,
                  onHorizontalDragCancel: _resetSlotPageDrag,
                  onHorizontalDragEnd: _endSlotPageDrag,
                  child: SizedBox(
                    height: 170,
                    child: AnimatedContainer(
                      key: const ValueKey('category-slot-page-transform'),
                      duration: _slotPageDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(_visualDx, 0, 0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        child: _page == 0
                            ? CategorySlotGrid.colors(
                                key: const ValueKey('color-slot-grid'),
                                selectedSlot: _colorSlot,
                                surfaceStyle: widget.buttonSurfaceStyle,
                                selectedSurfaceStyle:
                                    widget.selectedSurfaceStyle,
                                accentColor: widget.accentColor,
                                onSelected: (slot) =>
                                    setState(() => _colorSlot = slot),
                              )
                            : CategorySlotGrid.icons(
                                key: const ValueKey('icon-slot-grid'),
                                selectedSlot: _iconSlot,
                                surfaceStyle: widget.buttonSurfaceStyle,
                                selectedSurfaceStyle:
                                    widget.selectedSurfaceStyle,
                                accentColor: widget.accentColor,
                                onSelected: (slot) =>
                                    setState(() => _iconSlot = slot),
                                onLongPressed: _openIconSelector,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Előnézet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                CategoryPreviewPill(
                  name: _name.text,
                  colorSlot: _colorSlot,
                  iconSlot: _iconSlot,
                  surfaceColor: widget.surfaceColor,
                  bodySurfaceStyle: widget.bodySurfaceStyle,
                  avatarSurfaceStyle: widget.buttonSurfaceStyle,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ],
                const SizedBox(height: 18),
                ExpenseSurfaceButton(
                  buttonKey: const ValueKey('category-save-button'),
                  label: 'Mentés',
                  onPressed: _save,
                  surfaceStyle: widget.buttonSurfaceStyle,
                  color: widget.accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleNameFocusChanged() {
    final label = _editing ? 'EditCategory' : 'AddCategory';
    if (_nameFocus.hasFocus) {
      _focusStartedAt = DateTime.now();
      DebugConsole.log('[Perf] $label focus field=name active=true');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_nameFocus.hasFocus) return;
        DebugConsole.log(
          '[Perf] $label focus frame field=name elapsed=${_elapsedMs(_focusStartedAt)}ms',
        );
      });
      return;
    }
    DebugConsole.log(
      '[Perf] $label focus field=name active=false elapsed=${_elapsedMs(_focusStartedAt)}ms',
    );
    _focusStartedAt = null;
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  void _toggleSlotPage() {
    setState(() => _page = _page == 0 ? 1 : 0);
  }

  void _startSlotPageDrag(DragStartDetails details) {
    setState(() {
      _dragDx = 0;
      _visualDx = 0;
      _slotPageDragging = true;
    });
  }

  void _updateSlotPageDrag(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
    setState(() {
      _visualDx = (_dragDx * 0.1).clamp(-18.0, 18.0).toDouble();
    });
  }

  void _endSlotPageDrag(DragEndDetails details) {
    final shouldSwitch = _dragDx.abs() > 80;
    setState(() {
      if (shouldSwitch) _page = _page == 0 ? 1 : 0;
      _dragDx = 0;
      _visualDx = 0;
      _slotPageDragging = false;
    });
    if (shouldSwitch) unawaited(HapticFeedback.selectionClick());
  }

  void _resetSlotPageDrag() {
    setState(() {
      _dragDx = 0;
      _visualDx = 0;
      _slotPageDragging = false;
    });
  }

  void _openIconSelector(int slot) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.24),
        builder: (sheetContext) {
          return IconSelectorSheet(
            selectedIconName: CategoryIconManager.iconNameForSlot(slot),
            accentColor: widget.accentColor,
            onSelected: (iconName) {
              unawaited(_applyIconSelection(sheetContext, slot, iconName));
            },
          );
        },
      ),
    );
  }

  Future<void> _applyIconSelection(
    BuildContext sheetContext,
    int slot,
    String iconName,
  ) async {
    await CategoryIconManager.assignIconToSlot(slot, iconName);
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    if (!mounted) return;
    setState(() {});
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'A kategória neve kötelező');
      return;
    }
    widget.onSave(
      CategoryDraft(
        id: widget.initialCategory?.transactionCategoryID,
        name: name,
        type: widget.initialCategory?.normalizedType ?? widget.activeType,
        colorSlot: _colorSlot,
        iconSlot: _iconSlot,
      ),
    );
  }
}
