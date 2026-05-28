import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/fast_info_config.dart';
import 'settings_option_widgets.dart';

class FastInfoOptionsPanel extends StatelessWidget {
  const FastInfoOptionsPanel({super.key, required this.config});

  final FastInfoConfig config;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Text(
          'FastInfo slotok',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800),
        ),
        const SizedBox(height: 12),
        SettingsSection(
          title: 'Pill slotok',
          children: List.generate(3, (index) {
            return _SlotRow(
              title: 'Pill slot ${index + 1}',
              slot: config.pills[index],
              isLast: index == 2,
            );
          }),
        ),
        SettingsSection(
          title: 'Box slotok',
          children: List.generate(3, (index) {
            return _SlotRow(
              title: 'Box slot ${index + 1}',
              slot: config.boxes[index],
              isLast: index == 2,
            );
          }),
        ),
        SettingsSection(
          title: 'Elérhető FastInfo elemek',
          children: const [
            SettingsOptionItem(title: 'Megtakarítás', trailing: SizedBox.shrink()),
            SettingsOptionItem(title: 'Mai nap', trailing: SizedBox.shrink()),
            SettingsOptionItem(title: 'Havi limit', trailing: SizedBox.shrink()),
            SettingsOptionItem(title: 'Trend', trailing: SizedBox.shrink(), isLast: true),
          ],
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.title, required this.slot, required this.isLast});

  final String title;
  final FastInfoSlot? slot;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SettingsOptionItem(
      title: title,
      isLast: isLast,
      trailing: Expanded(
        child: Text(
          slot == null ? 'Üres slot' : '${slot!.label}  ${slot!.value}',
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: const TextStyle(color: AppColors.gray500, fontSize: 13),
        ),
      ),
    );
  }
}
