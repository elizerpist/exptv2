import 'package:flutter/material.dart';

/// Shared visual language for the category and partner child editors.
abstract final class ChildEditorSheetTokens {
  static const primary = Color(0xff19264d);
  static const secondary = Color(0xff718096);
  static const border = Color(0xffdde2ec);
  static const neutralSurface = Color(0xfff2f4f8);
  static const save = Color(0xff7552b8);
  static const scrim = Color(0x6619264d);
}

/// Opens a child editor without inheriting a tinted Material bottom-sheet
/// surface. The frame itself owns the single keyboard and system-inset path.
Future<T?> showFluviChildEditorSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: false,
  backgroundColor: Colors.transparent,
  barrierColor: ChildEditorSheetTokens.scrim,
  elevation: 0,
  builder: builder,
);

/// Generic sibling of [ChildEditorSheetFrame] for a child panel that has no
/// avatar/name row (for example recurrence timing and bank-link settings).
/// It owns exactly one keyboard/system-inset path and shares the same footer
/// buttons and un-clipped outer button shadows as the category/partner panel.
final class ChildEditorSheetScaffold extends StatelessWidget {
  const ChildEditorSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onApply,
    required this.applying,
    this.applyLabel = 'Alkalmaz',
    this.cancelKey,
    this.applyKey,
  });

  final String title;
  final Widget body;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;
  final bool applying;
  final String applyLabel;
  final Key? cancelKey;
  final Key? applyKey;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maximumHeight =
        (media.size.height - media.viewInsets.bottom - media.padding.top - 12)
            .clamp(220.0, double.infinity)
            .toDouble();
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maximumHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Material(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.none,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: SizedBox(
                              width: 32,
                              height: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xffcdd2dd),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: const TextStyle(
                              color: ChildEditorSheetTokens.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          body,
                        ],
                      ),
                    ),
                  ),
                  _ChildEditorFooter(
                    cancelKey: cancelKey,
                    saveKey: applyKey,
                    saving: applying,
                    onCancel: onCancel,
                    onSave: onApply,
                    saveLabel: applyLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The common bottom-sheet shell used by the two equal-level child editors.
/// Drafts, validation and persistence deliberately stay with their caller.
final class ChildEditorSheetFrame extends StatelessWidget {
  const ChildEditorSheetFrame({
    super.key,
    required this.title,
    required this.avatar,
    required this.nameController,
    required this.nameLabel,
    required this.body,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    this.nameFieldKey,
    this.cancelKey,
    this.saveKey,
    this.nameError,
    this.onNameChanged,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String title;
  final Widget avatar;
  final TextEditingController nameController;
  final String nameLabel;
  final Widget body;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;
  final Key? nameFieldKey;
  final Key? cancelKey;
  final Key? saveKey;
  final String? nameError;
  final ValueChanged<String>? onNameChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maximumHeight =
        (media.size.height - media.viewInsets.bottom - media.padding.top - 12)
            .clamp(240.0, double.infinity)
            .toDouble();
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maximumHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Material(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.none,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: SizedBox(
                              width: 32,
                              height: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xffcdd2dd),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: const TextStyle(
                              color: ChildEditorSheetTokens.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 72, height: 72, child: avatar),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  key: nameFieldKey,
                                  controller: nameController,
                                  autofocus: false,
                                  textCapitalization: textCapitalization,
                                  style: const TextStyle(
                                    color: ChildEditorSheetTokens.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: nameLabel,
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelStyle: const TextStyle(
                                      color: ChildEditorSheetTokens.secondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    errorText: nameError,
                                    filled: true,
                                    fillColor: Colors.white,
                                    isDense: true,
                                    constraints: const BoxConstraints(
                                      minHeight: 56,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      borderSide: BorderSide(
                                        color: ChildEditorSheetTokens.border,
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      borderSide: BorderSide(
                                        color: ChildEditorSheetTokens.save,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      borderSide: BorderSide(
                                        color: Color(0xffc9465c),
                                      ),
                                    ),
                                    focusedErrorBorder:
                                        const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xffc9465c),
                                            width: 1.5,
                                          ),
                                        ),
                                  ),
                                  onChanged: onNameChanged,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          body,
                        ],
                      ),
                    ),
                  ),
                  _ChildEditorFooter(
                    cancelKey: cancelKey,
                    saveKey: saveKey,
                    saving: saving,
                    onCancel: onCancel,
                    onSave: onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ChildEditorFooter extends StatelessWidget {
  const _ChildEditorFooter({
    this.cancelKey,
    this.saveKey,
    required this.saving,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Mentés',
  });

  final Key? cancelKey;
  final Key? saveKey;
  final bool saving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xffeef1f5))),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _ChildEditorButton(
              key: cancelKey,
              label: 'Mégse',
              minimumWidth: 96,
              primary: false,
              onPressed: saving ? null : onCancel,
            ),
            _ChildEditorButton(
              key: saveKey,
              label: saving ? '$saveLabel…' : saveLabel,
              minimumWidth: 108,
              primary: true,
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Its outer shadow intentionally paints outside the button-sized Material.
final class _ChildEditorButton extends StatelessWidget {
  const _ChildEditorButton({
    super.key,
    required this.label,
    required this.minimumWidth,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final double minimumWidth;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: minimumWidth, minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2619264d),
              offset: Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              color: primary ? ChildEditorSheetTokens.save : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: primary
                  ? null
                  : Border.all(color: ChildEditorSheetTokens.border),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primary
                          ? Colors.white
                          : ChildEditorSheetTokens.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
