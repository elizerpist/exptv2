import 'package:flutter/material.dart';

import '../../models/app_theme_settings.dart';
import 'backheader_style_preview.dart';
import 'settings_option_widgets.dart';

class BackheaderStyleOptionsPanel extends StatelessWidget {
  const BackheaderStyleOptionsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('settings-backheader-style-scroll'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final style in BackheaderStyle.selectableValues)
              SettingsRadioOption(
                title:
                    '${style.displayTitle}${settings.backheaderStyle == style ? ' (jelenlegi)' : ''}',
                description: style.description,
                selected: settings.backheaderStyle == style,
                onTap: () =>
                    onChanged(settings.copyWith(backheaderStyle: style)),
                preview: BackheaderStylePreview(style: style),
              ),
            if (settings.backheaderStyle ==
                BackheaderStyle.centerBadgeBudget) ...[
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12, top: 4),
                child: Text(
                  'Center Badge háttér',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final design in BackheaderCenterDesign.values)
                SettingsRadioOption(
                  title:
                      '${design.displayTitle}${settings.centerBackheaderDesign == design ? ' (jelenlegi)' : ''}',
                  description: design.description,
                  selected: settings.centerBackheaderDesign == design,
                  onTap: () => onChanged(
                    settings.copyWith(centerBackheaderDesign: design),
                  ),
                ),
              const SizedBox(height: 4),
              _CenterPartitionRingToggle(
                enabled: settings.centerPartitionRingEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(centerPartitionRingEnabled: enabled),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CenterPartitionRingToggle extends StatelessWidget {
  const _CenterPartitionRingToggle({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('center-partition-ring-toggle'),
      onTap: () => onChanged(!enabled),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Külső partition kör',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A lineáris partition progress kör alakú, külső gyűrűként.',
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
