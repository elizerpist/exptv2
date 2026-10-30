import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_global_appearance.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../application/creation_selector_preferences.dart';

enum CreationSelectorAction {
  manualTransaction,
  recurringTransaction,
  pushProfile,
}

/// Compact centre-FAB action selector. It owns only presentation and the
/// selected action; direction and all subsequent navigation stay in the shell.
Future<CreationSelectorAction?> showCreationSelectorSheet(
  BuildContext context, {
  required LedgerDirection direction,
  FluviDirectionColorProfile directionColorProfile =
      FluviDirectionColorProfile.original,
  CreationSelectorPreferencesStore? preferencesStore,
}) async {
  final store =
      preferencesStore ?? MethodChannelCreationSelectorPreferencesStore();
  final initialDesign = await store.read();
  if (!context.mounted) return null;
  return showModalBottomSheet<CreationSelectorAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x9909172B),
    builder: (context) => _CreationSelectorSheet(
      direction: direction,
      directionColorProfile: directionColorProfile,
      preferencesStore: store,
      initialDesign: initialDesign,
    ),
  );
}

final class _CreationSelectorSheet extends StatefulWidget {
  const _CreationSelectorSheet({
    required this.direction,
    required this.directionColorProfile,
    required this.preferencesStore,
    required this.initialDesign,
  });

  final LedgerDirection direction;
  final FluviDirectionColorProfile directionColorProfile;
  final CreationSelectorPreferencesStore preferencesStore;
  final CreationSelectorDesign initialDesign;

  @override
  State<_CreationSelectorSheet> createState() => _CreationSelectorSheetState();
}

final class _CreationSelectorSheetState extends State<_CreationSelectorSheet> {
  late CreationSelectorDesign _design = widget.initialDesign;
  bool _writingDesign = false;

  Future<void> _toggleDesign() async {
    if (_writingDesign) return;
    final next = _design == CreationSelectorDesign.refreshed
        ? CreationSelectorDesign.previous
        : CreationSelectorDesign.refreshed;
    setState(() {
      _design = next;
      _writingDesign = true;
    });
    await widget.preferencesStore.write(next);
    if (mounted) setState(() => _writingDesign = false);
  }

  @override
  Widget build(BuildContext context) {
    final directionGradient = widget.direction == LedgerDirection.income
        ? FluviDirectionColorPaletteCatalog.income(widget.directionColorProfile)
        : FluviDirectionColorPaletteCatalog.expense(
            widget.directionColorProfile,
          );
    return RepaintBoundary(
      key: const ValueKey('creation-selector-sheet-boundary'),
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: _design == CreationSelectorDesign.refreshed
                  ? _RefreshedCreationSelector(
                      direction: widget.direction,
                      directionGradient: directionGradient,
                      onToggleDesign: _writingDesign ? null : _toggleDesign,
                    )
                  : _PreviousCreationSelector(
                      direction: widget.direction,
                      onToggleDesign: _writingDesign ? null : _toggleDesign,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _RefreshedCreationSelector extends StatelessWidget {
  const _RefreshedCreationSelector({
    required this.direction,
    required this.directionGradient,
    required this.onToggleDesign,
  });

  final LedgerDirection direction;
  final LinearGradient directionGradient;
  final VoidCallback? onToggleDesign;

  @override
  Widget build(BuildContext context) {
    final accent = directionGradient.colors.first;
    final subtitle = direction == LedgerDirection.income
        ? 'Egyszeri bevétel rögzítése.'
        : 'Egyszeri kiadás rögzítése.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetHandle(),
        const SizedBox(height: 18),
        _SelectorTitle(
          title: direction == LedgerDirection.income
              ? 'Új bevétel'
              : 'Új kiadás',
          targetTooltip: 'Korábbi FAB-menü',
          icon: Icons.view_list_outlined,
          onToggleDesign: onToggleDesign,
        ),
        const SizedBox(height: 14),
        _CreationActionRow(
          key: const ValueKey('creation-action-manual'),
          icon: Icons.edit_note_rounded,
          title: 'Manuális tranzakció',
          subtitle: subtitle,
          iconGradient: directionGradient,
          highlighted: true,
          tint: accent,
          onTap: () =>
              Navigator.pop(context, CreationSelectorAction.manualTransaction),
        ),
        const SizedBox(height: 8),
        _CreationActionRow(
          key: const ValueKey('creation-action-recurring'),
          icon: Icons.repeat_rounded,
          title: 'Ismétlődő tranzakció',
          subtitle: 'Időzítve vagy banki értesítés alapján.',
          tint: accent,
          onTap: () => Navigator.pop(
            context,
            CreationSelectorAction.recurringTransaction,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xffe3e8f1)),
        ),
        _CreationActionRow(
          key: const ValueKey('creation-action-push-profile'),
          icon: Icons.notifications_none_rounded,
          title: 'Push profil létrehozása',
          subtitle: 'Banki értesítések felismerésének beállítása.',
          tint: const Color(0xff304ee8),
          iconBackground: const Color(0xffe8ebff),
          onTap: () =>
              Navigator.pop(context, CreationSelectorAction.pushProfile),
        ),
      ],
    );
  }
}

/// The original, deliberately plain three-row sheet remains available for
/// people who prefer it. It uses the exact same action values as the refreshed
/// presentation above.
final class _PreviousCreationSelector extends StatelessWidget {
  const _PreviousCreationSelector({
    required this.direction,
    required this.onToggleDesign,
  });

  final LedgerDirection direction;
  final VoidCallback? onToggleDesign;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SheetHandle(width: 36, height: 4),
      const SizedBox(height: 16),
      _SelectorTitle(
        title: direction == LedgerDirection.income
            ? 'Új bevételi tranzakció létrehozása'
            : 'Új kiadási tranzakció létrehozása',
        targetTooltip: 'Új FAB-menü',
        icon: Icons.dashboard_customize_outlined,
        onToggleDesign: onToggleDesign,
      ),
      const SizedBox(height: 8),
      _PreviousActionRow(
        key: const ValueKey('creation-action-manual'),
        icon: Icons.edit_note_rounded,
        title: 'Manuális tranzakció',
        subtitle: 'Új bevétel vagy kiadás rögzítése.',
        onTap: () =>
            Navigator.pop(context, CreationSelectorAction.manualTransaction),
      ),
      _PreviousActionRow(
        key: const ValueKey('creation-action-recurring'),
        icon: Icons.repeat_rounded,
        title: 'Ismétlődő tranzakció',
        subtitle: 'Idő- vagy push-alapú ismétlődés.',
        onTap: () =>
            Navigator.pop(context, CreationSelectorAction.recurringTransaction),
      ),
      _PreviousActionRow(
        key: const ValueKey('creation-action-push-profile'),
        icon: Icons.notifications_active_outlined,
        title: 'Push profil',
        subtitle: 'Banki értesítések megfigyelése és tanítása.',
        onTap: () => Navigator.pop(context, CreationSelectorAction.pushProfile),
      ),
    ],
  );
}

final class _SheetHandle extends StatelessWidget {
  const _SheetHandle({this.width = 42, this.height = 5});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffbac5d5),
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

final class _SelectorTitle extends StatelessWidget {
  const _SelectorTitle({
    required this.title,
    required this.targetTooltip,
    required this.icon,
    required this.onToggleDesign,
  });

  final String title;
  final String targetTooltip;
  final IconData icon;
  final VoidCallback? onToggleDesign;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -.45,
          ),
        ),
      ),
      Semantics(
        button: true,
        label: targetTooltip,
        child: Tooltip(
          message: targetTooltip,
          child: IconButton(
            key: const ValueKey('creation-selector-design-toggle'),
            onPressed: onToggleDesign,
            icon: Icon(icon),
            color: FluviVisualTokens.textPrimary,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: const Color(0xfff1f5f9),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Every refreshed row uses the same hit target, icon geometry, type hierarchy
/// and chevron alignment. Only the manual action gets the intentional tint.
final class _CreationActionRow extends StatelessWidget {
  const _CreationActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
    this.iconGradient,
    this.iconBackground,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  final LinearGradient? iconGradient;
  final Color? iconBackground;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final iconSurface = iconBackground ?? tint.withValues(alpha: .13);
    final rowBackground = highlighted
        ? tint.withValues(alpha: .105)
        : Colors.transparent;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: rowBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconGradient == null ? iconSurface : null,
                      gradient: iconGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 26,
                      color: iconGradient == null ? tint : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: FluviVisualTokens.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.2,
                                fontSize: 18,
                                height: 1.1,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: FluviVisualTokens.textSecondary,
                                fontSize: 13,
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 30,
                    color: FluviVisualTokens.textPrimary,
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

final class _PreviousActionRow extends StatelessWidget {
  const _PreviousActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $subtitle',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              SizedBox(width: 48, child: Icon(icon, size: 25)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}
