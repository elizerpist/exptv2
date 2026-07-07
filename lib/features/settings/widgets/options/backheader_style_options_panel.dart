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
              _CenterBadgeDiscToggle(
                enabled: settings.centerBadgeDiscEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(centerBadgeDiscEnabled: enabled),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12, top: 4),
                child: Text(
                  'Badge border',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final mode in CenterBadgeBorderMode.values)
                SettingsRadioOption(
                  title:
                      '${_centerBadgeBorderModeTitle(mode)}${settings.centerBadgeBorderMode == mode ? ' (jelenlegi)' : ''}',
                  description: _centerBadgeBorderModeDescription(mode),
                  selected: settings.centerBadgeBorderMode == mode,
                  onTap: () =>
                      onChanged(settings.copyWith(centerBadgeBorderMode: mode)),
                ),
              const SizedBox(height: 4),
              _CenterPartitionRingToggle(
                enabled: settings.centerPartitionRingEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(centerPartitionRingEnabled: enabled),
                ),
              ),
              const SizedBox(height: 12),
              _CenterBadgeOpacityControls(
                settings: settings,
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _centerBadgeBorderModeTitle(CenterBadgeBorderMode mode) {
  return switch (mode) {
    CenterBadgeBorderMode.limitOnly => 'Csak limites badgeken',
    CenterBadgeBorderMode.always => 'Mindig látszik',
  };
}

String _centerBadgeBorderModeDescription(CenterBadgeBorderMode mode) {
  return switch (mode) {
    CenterBadgeBorderMode.limitOnly =>
      'A progress border csak akkor jelenik meg, ha az adott badgehez van limit.',
    CenterBadgeBorderMode.always =>
      'Összehasonlításhoz a nem limites badgek is megtartják a tracket.',
  };
}

class _CenterBadgeOpacityControls extends StatelessWidget {
  const _CenterBadgeOpacityControls({
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  static const _distanceLabels = [
    'Közép',
    'Mellette',
    'Következő',
    'Távoli',
    'Szél',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Fehér opacity finomhangolás',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Csak a színes Center Badge fehér rétegeire vonatkozik.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildGroup(
            title: 'Korong',
            keyPrefix: 'disc',
            values: settings.centerBadgeWhiteDiscOpacities,
            onValueChanged: (index, value) => onChanged(
              settings.copyWith(
                centerBadgeWhiteDiscOpacities: _replaceAt(
                  settings.centerBadgeWhiteDiscOpacities,
                  index,
                  value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildGroup(
            title: 'Ikon',
            keyPrefix: 'icon',
            values: settings.centerBadgeWhiteIconOpacities,
            onValueChanged: (index, value) => onChanged(
              settings.copyWith(
                centerBadgeWhiteIconOpacities: _replaceAt(
                  settings.centerBadgeWhiteIconOpacities,
                  index,
                  value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildGroup(
            title: 'Progress circle',
            keyPrefix: 'progress',
            values: settings.centerBadgeWhiteProgressOpacities,
            onValueChanged: (index, value) => onChanged(
              settings.copyWith(
                centerBadgeWhiteProgressOpacities: _replaceAt(
                  settings.centerBadgeWhiteProgressOpacities,
                  index,
                  value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CenterBadgeOpacityRow(
            label: 'Háttér opacity',
            sliderKey: const ValueKey('center-badge-opacity-background-slider'),
            inputKey: const ValueKey('center-badge-opacity-background-input'),
            value: settings.centerBadgeColoredBackgroundOpacity,
            onChanged: (value) => onChanged(
              settings.copyWith(centerBadgeColoredBackgroundOpacity: value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup({
    required String title,
    required String keyPrefix,
    required List<int> values,
    required void Function(int index, int value) onValueChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (var index = 0; index < _distanceLabels.length; index += 1)
          _CenterBadgeOpacityRow(
            label: _distanceLabels[index],
            sliderKey: ValueKey(
              'center-badge-opacity-$keyPrefix-$index-slider',
            ),
            inputKey: ValueKey('center-badge-opacity-$keyPrefix-$index-input'),
            value: values[index],
            onChanged: (value) => onValueChanged(index, value),
          ),
      ],
    );
  }

  List<int> _replaceAt(List<int> values, int index, int value) {
    final next = List<int>.of(values);
    next[index] = _clampPercent(value);
    return next;
  }
}

int _clampPercent(int value) => value.clamp(0, 100).toInt();

class _CenterBadgeOpacityRow extends StatelessWidget {
  const _CenterBadgeOpacityRow({
    required this.label,
    required this.sliderKey,
    required this.inputKey,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Key sliderKey;
  final Key inputKey;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              key: sliderKey,
              min: 0,
              max: 100,
              divisions: 100,
              value: value.toDouble().clamp(0, 100).toDouble(),
              onChanged: (next) => onChanged(_clampPercent(next.round())),
            ),
          ),
          Container(
            width: 58,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextFormField(
              key: inputKey,
              initialValue: '$value',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 7,
                ),
              ),
              onFieldSubmitted: _submit,
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    onChanged(_clampPercent(parsed));
  }
}

class _CenterBadgeDiscToggle extends StatelessWidget {
  const _CenterBadgeDiscToggle({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('center-badge-disc-toggle'),
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
                    'Fehér korong',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Csak színes Center Badge módban tölti ki fehérrel a badge körét.',
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
