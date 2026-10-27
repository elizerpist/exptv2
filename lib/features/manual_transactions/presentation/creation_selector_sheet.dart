import 'package:flutter/material.dart';

import '../../dashboard/query/domain/ledger_direction.dart';

enum CreationSelectorAction {
  manualTransaction,
  recurringTransaction,
  pushProfile,
}

/// Compact, content-height selector. It intentionally does not reuse the
/// query sheet's Expanded body contract.
Future<CreationSelectorAction?> showCreationSelectorSheet(
  BuildContext context, {
  required LedgerDirection direction,
}) => showModalBottomSheet<CreationSelectorAction>(
  context: context,
  useSafeArea: true,
  isScrollControlled: false,
  backgroundColor: Colors.transparent,
  builder: (context) => _CreationSelectorSheet(direction: direction),
);

final class _CreationSelectorSheet extends StatelessWidget {
  const _CreationSelectorSheet({required this.direction});

  final LedgerDirection direction;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C2D3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              direction == LedgerDirection.income
                  ? 'Új bevételi tranzakció létrehozása'
                  : 'Új kiadási tranzakció létrehozása',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.edit_note_rounded,
              title: 'Manuális tranzakció',
              subtitle: 'Új bevétel vagy kiadás rögzítése.',
              onTap: () => Navigator.pop(
                context,
                CreationSelectorAction.manualTransaction,
              ),
            ),
            _ActionRow(
              icon: Icons.repeat_rounded,
              title: 'Ismétlődő tranzakció',
              subtitle: 'Idő- vagy push-alapú ismétlődés.',
              onTap: () => Navigator.pop(
                context,
                CreationSelectorAction.recurringTransaction,
              ),
            ),
            _ActionRow(
              icon: Icons.notifications_active_outlined,
              title: 'Push profil',
              subtitle: 'Banki értesítések megfigyelése és tanítása.',
              onTap: () =>
                  Navigator.pop(context, CreationSelectorAction.pushProfile),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 72,
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
