import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_global_appearance.dart';
import '../../dashboard/query/domain/ledger_direction.dart';

enum CreationSelectorAction {
  manualTransaction,
  recurringTransaction,
  pushProfile,
}

/// The compact action panel launched by the centre Ledger FAB. It owns only
/// the action choice; direction and subsequent navigation stay with the shell.
Future<CreationSelectorAction?> showCreationSelectorSheet(
  BuildContext context, {
  required LedgerDirection direction,
  FluviDirectionColorProfile directionColorProfile =
      FluviDirectionColorProfile.original,
}) => showModalBottomSheet<CreationSelectorAction>(
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
  ),
);

final class _CreationSelectorSheet extends StatelessWidget {
  const _CreationSelectorSheet({
    required this.direction,
    required this.directionColorProfile,
  });

  final LedgerDirection direction;
  final FluviDirectionColorProfile directionColorProfile;

  @override
  Widget build(BuildContext context) {
    final directionGradient = direction == LedgerDirection.income
        ? FluviDirectionColorPaletteCatalog.income(directionColorProfile)
        : FluviDirectionColorPaletteCatalog.expense(directionColorProfile);
    final accent = directionGradient.colors.first;
    final subtitle = direction == LedgerDirection.income
        ? 'Egyszeri bevétel rögzítése.'
        : 'Egyszeri kiadás rögzítése.';
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffbac5d5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    direction == LedgerDirection.income
                        ? 'Új bevétel'
                        : 'Új kiadás',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CreationActionRow(
                    key: const ValueKey('creation-action-manual'),
                    icon: Icons.edit_note_rounded,
                    title: 'Manuális tranzakció',
                    subtitle: subtitle,
                    iconGradient: directionGradient,
                    highlighted: true,
                    tint: accent,
                    onTap: () => Navigator.pop(
                      context,
                      CreationSelectorAction.manualTransaction,
                    ),
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
                    onTap: () => Navigator.pop(
                      context,
                      CreationSelectorAction.pushProfile,
                    ),
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

/// Every row uses the same hit target, icon geometry, type hierarchy and
/// chevron alignment. Only the manual action has an intentional soft tint.
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
