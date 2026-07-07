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
              const SizedBox(height: 8),
              _CenterBadgeOverlapMaskToggle(
                enabled: settings.centerBadgeOverlapMaskEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(centerBadgeOverlapMaskEnabled: enabled),
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
    'Második pár',
    'Harmadik pár',
    'Szél',
  ];
  static const _centerSlotIndex = 4;

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fehér opacity finomhangolás',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('center-badge-tuning-reset-button'),
                onPressed: _resetTuning,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Csak a színes Center Badge fehér rétegeire vonatkozik. A vezérlők páronként, a középtől mért távolság szerint állítanak.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _CenterBadgeRelativeScaleSection(
            settings: settings,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          _CenterBadgeOpacityRow(
            label: 'Háttér opacity',
            sliderKey: const ValueKey('center-badge-opacity-background-slider'),
            inputKey: const ValueKey('center-badge-opacity-background-input'),
            value: settings.centerBadgeColoredBackgroundOpacity,
            onChanged: (value) => onChanged(
              settings.copyWith(centerBadgeColoredBackgroundOpacity: value),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Színes badge opacity',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A nem fehér badge fill, ikon és progress rétegeire vonatkozik.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text(
            'Badge méret és pozíció',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Öt távolsági szekció: közép, majd a bal-jobb badge párok. A távolság érték pozitívan kifelé, negatívan befelé mozgat.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (
            var distance = 0;
            distance < _distanceLabels.length;
            distance += 1
          )
            _buildDistanceSection(distance),
        ],
      ),
    );
  }

  Widget _buildDistanceSection(int distance) {
    return Container(
      key: ValueKey('center-badge-tuning-section-$distance'),
      margin: EdgeInsets.only(
        bottom: distance == _distanceLabels.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _distanceLabels[distance],
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _buildOpacityRow(
            label: 'Fehér korong',
            keyName: 'opacity-disc',
            values: settings.centerBadgeWhiteDiscOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeWhiteDiscOpacities: values),
            ),
          ),
          _buildOpacityRow(
            label: 'Fehér ikon',
            keyName: 'opacity-icon',
            values: settings.centerBadgeWhiteIconOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeWhiteIconOpacities: values),
            ),
          ),
          _buildOpacityRow(
            label: 'Fehér progress',
            keyName: 'opacity-progress',
            values: settings.centerBadgeWhiteProgressOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeWhiteProgressOpacities: values),
            ),
          ),
          _buildOpacityRow(
            label: 'Színes fill',
            keyName: 'colored-opacity-fill',
            values: settings.centerBadgeColoredFillOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeColoredFillOpacities: values),
            ),
          ),
          _buildOpacityRow(
            label: 'Színes ikon',
            keyName: 'colored-opacity-icon',
            values: settings.centerBadgeColoredIconOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeColoredIconOpacities: values),
            ),
          ),
          _buildOpacityRow(
            label: 'Színes progress',
            keyName: 'colored-opacity-progress',
            values: settings.centerBadgeColoredProgressOpacities,
            distance: distance,
            onValuesChanged: (values) => onChanged(
              settings.copyWith(centerBadgeColoredProgressOpacities: values),
            ),
          ),
          _CenterBadgeOpacityRow(
            label: 'Méret',
            sliderKey: ValueKey('center-badge-pair-size-$distance-slider'),
            inputKey: ValueKey('center-badge-pair-size-$distance-input'),
            value: _pairSizeValue(distance),
            min: kCenterBadgeSlotSizePercentMin,
            max: kCenterBadgeSlotSizePercentMax,
            onChanged: (value) => onChanged(
              settings.copyWith(
                centerBadgeSlotSizePercents: _replacePairDistance(
                  settings.centerBadgeSlotSizePercents,
                  distance,
                  value,
                  min: kCenterBadgeSlotSizePercentMin,
                  max: kCenterBadgeSlotSizePercentMax,
                ),
              ),
            ),
          ),
          if (distance > 0)
            _CenterBadgeOpacityRow(
              label: 'Távolság',
              sliderKey: ValueKey(
                'center-badge-distance-offset-$distance-slider',
              ),
              inputKey: ValueKey(
                'center-badge-distance-offset-$distance-input',
              ),
              value: _pairDistanceOffsetValue(distance),
              min: kCenterBadgeSlotXOffsetMin,
              max: kCenterBadgeSlotXOffsetMax,
              onChanged: (value) => onChanged(
                settings.copyWith(
                  centerBadgeSlotXOffsets: _replaceDistanceOffset(
                    settings.centerBadgeSlotXOffsets,
                    distance,
                    value,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpacityRow({
    required String label,
    required String keyName,
    required List<int> values,
    required int distance,
    required ValueChanged<List<int>> onValuesChanged,
  }) {
    return _CenterBadgeOpacityRow(
      label: label,
      sliderKey: ValueKey('center-badge-$keyName-$distance-slider'),
      inputKey: ValueKey('center-badge-$keyName-$distance-input'),
      value: values[distance],
      onChanged: (value) => onValuesChanged(
        _replaceAtBounded(values, distance, value, min: 0, max: 100),
      ),
    );
  }

  int _pairSizeValue(int distance) {
    if (distance == 0) {
      return settings.centerBadgeSlotSizePercents[_centerSlotIndex];
    }
    return settings.centerBadgeSlotSizePercents[_centerSlotIndex + distance];
  }

  int _pairDistanceOffsetValue(int distance) {
    final left = settings.centerBadgeSlotXOffsets[_centerSlotIndex - distance];
    final right = settings.centerBadgeSlotXOffsets[_centerSlotIndex + distance];
    return ((right - left) / 2).round();
  }

  List<int> _replacePairDistance(
    List<int> values,
    int distance,
    int value, {
    required int min,
    required int max,
  }) {
    final next = List<int>.of(values);
    final clamped = _clampNumber(value, min: min, max: max);
    if (distance == 0) {
      next[_centerSlotIndex] = clamped;
      return next;
    }
    next[_centerSlotIndex - distance] = clamped;
    next[_centerSlotIndex + distance] = clamped;
    return next;
  }

  List<int> _replaceDistanceOffset(List<int> values, int distance, int value) {
    final next = List<int>.of(values);
    final clamped = _clampNumber(
      value,
      min: kCenterBadgeSlotXOffsetMin,
      max: kCenterBadgeSlotXOffsetMax,
    );
    next[_centerSlotIndex - distance] = -clamped;
    next[_centerSlotIndex + distance] = clamped;
    return next;
  }

  void _resetTuning() {
    onChanged(
      settings.copyWith(
        centerPartitionRingEnabled: false,
        centerBadgeDiscEnabled: true,
        centerBadgeBorderMode: CenterBadgeBorderMode.limitOnly,
        centerBadgeOverlapMaskEnabled: false,
        centerBadgeWhiteDiscOpacities: kCenterBadgeWhiteDiscOpacityDefaults,
        centerBadgeWhiteIconOpacities: kCenterBadgeWhiteIconOpacityDefaults,
        centerBadgeWhiteProgressOpacities:
            kCenterBadgeWhiteProgressOpacityDefaults,
        centerBadgeColoredFillOpacities: kCenterBadgeColoredFillOpacityDefaults,
        centerBadgeColoredIconOpacities: kCenterBadgeColoredIconOpacityDefaults,
        centerBadgeColoredProgressOpacities:
            kCenterBadgeColoredProgressOpacityDefaults,
        centerBadgeSlotSizePercents: kCenterBadgeSlotSizePercentDefaults,
        centerBadgeSlotXOffsets: kCenterBadgeSlotXOffsetDefaults,
        centerBadgeColoredBackgroundOpacity:
            kCenterBadgeColoredBackgroundOpacityDefault,
      ),
    );
  }

  List<int> _replaceAtBounded(
    List<int> values,
    int index,
    int value, {
    required int min,
    required int max,
  }) {
    final next = List<int>.of(values);
    next[index] = _clampNumber(value, min: min, max: max);
    return next;
  }
}

class _CenterBadgeRelativeScaleSection extends StatefulWidget {
  const _CenterBadgeRelativeScaleSection({
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  @override
  State<_CenterBadgeRelativeScaleSection> createState() =>
      _CenterBadgeRelativeScaleSectionState();
}

class _CenterBadgeRelativeScaleSectionState
    extends State<_CenterBadgeRelativeScaleSection> {
  var _sizePercent = 100;
  var _opacityPercent = 100;
  var _discOpacityPercent = 100;
  late List<int> _baseSizes;
  late List<int> _baseWhiteDiscOpacities;
  late List<int> _baseWhiteIconOpacities;
  late List<int> _baseWhiteProgressOpacities;
  late List<int> _baseColoredFillOpacities;
  late List<int> _baseColoredIconOpacities;
  late List<int> _baseColoredProgressOpacities;

  @override
  void initState() {
    super.initState();
    _captureSizeBaseline();
    _captureBadgeOpacityBaseline();
    _captureDiscOpacityBaseline();
  }

  @override
  void didUpdateWidget(covariant _CenterBadgeRelativeScaleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sizePercent == 100) _captureSizeBaseline();
    if (_opacityPercent == 100) _captureBadgeOpacityBaseline();
    if (_discOpacityPercent == 100) _captureDiscOpacityBaseline();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('center-badge-relative-section'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Relatív beállítás',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A középállás az aktuális, kézzel beállított érték. Felfelé növel, lefelé csökkent.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
          const SizedBox(height: 8),
          _CenterBadgeOpacityRow(
            label: 'Relatív méret',
            sliderKey: const ValueKey('center-badge-relative-size-slider'),
            inputKey: const ValueKey('center-badge-relative-size-input'),
            value: _sizePercent,
            min: 50,
            max: 150,
            onChanged: _scaleSize,
          ),
          _CenterBadgeOpacityRow(
            label: 'Relatív badge opacity',
            sliderKey: const ValueKey('center-badge-relative-opacity-slider'),
            inputKey: const ValueKey('center-badge-relative-opacity-input'),
            value: _opacityPercent,
            min: 50,
            max: 150,
            onChanged: _scaleBadgeOpacity,
          ),
          _CenterBadgeOpacityRow(
            label: 'Relatív korong opacity',
            sliderKey: const ValueKey(
              'center-badge-relative-disc-opacity-slider',
            ),
            inputKey: const ValueKey(
              'center-badge-relative-disc-opacity-input',
            ),
            value: _discOpacityPercent,
            min: 50,
            max: 150,
            onChanged: _scaleDiscOpacity,
          ),
        ],
      ),
    );
  }

  void _captureSizeBaseline() {
    _baseSizes = List<int>.of(widget.settings.centerBadgeSlotSizePercents);
  }

  void _captureBadgeOpacityBaseline() {
    final settings = widget.settings;
    _baseWhiteIconOpacities = List<int>.of(
      settings.centerBadgeWhiteIconOpacities,
    );
    _baseWhiteProgressOpacities = List<int>.of(
      settings.centerBadgeWhiteProgressOpacities,
    );
    _baseColoredIconOpacities = List<int>.of(
      settings.centerBadgeColoredIconOpacities,
    );
    _baseColoredProgressOpacities = List<int>.of(
      settings.centerBadgeColoredProgressOpacities,
    );
  }

  void _captureDiscOpacityBaseline() {
    final settings = widget.settings;
    _baseWhiteDiscOpacities = List<int>.of(
      settings.centerBadgeWhiteDiscOpacities,
    );
    _baseColoredFillOpacities = List<int>.of(
      settings.centerBadgeColoredFillOpacities,
    );
  }

  void _scaleSize(int nextPercent) {
    setState(() => _sizePercent = nextPercent);
    widget.onChanged(
      widget.settings.copyWith(
        centerBadgeSlotSizePercents: _scaleList(
          _baseSizes,
          nextPercent / 100,
          min: kCenterBadgeSlotSizePercentMin,
          max: kCenterBadgeSlotSizePercentMax,
        ),
      ),
    );
  }

  void _scaleBadgeOpacity(int nextPercent) {
    setState(() => _opacityPercent = nextPercent);
    widget.onChanged(
      widget.settings.copyWith(
        centerBadgeWhiteIconOpacities: _scaleList(
          _baseWhiteIconOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
        centerBadgeWhiteProgressOpacities: _scaleList(
          _baseWhiteProgressOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
        centerBadgeColoredIconOpacities: _scaleList(
          _baseColoredIconOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
        centerBadgeColoredProgressOpacities: _scaleList(
          _baseColoredProgressOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
      ),
    );
  }

  void _scaleDiscOpacity(int nextPercent) {
    setState(() => _discOpacityPercent = nextPercent);
    widget.onChanged(
      widget.settings.copyWith(
        centerBadgeWhiteDiscOpacities: _scaleList(
          _baseWhiteDiscOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
        centerBadgeColoredFillOpacities: _scaleList(
          _baseColoredFillOpacities,
          nextPercent / 100,
          min: 0,
          max: 100,
        ),
      ),
    );
  }

  List<int> _scaleList(
    List<int> values,
    double factor, {
    required int min,
    required int max,
  }) {
    return [
      for (final value in values) _scaleInt(value, factor, min: min, max: max),
    ];
  }

  int _scaleInt(
    int value,
    double factor, {
    required int min,
    required int max,
  }) {
    return _clampNumber((value * factor).round(), min: min, max: max);
  }
}

int _clampNumber(int value, {required int min, required int max}) {
  return value.clamp(min, max).toInt();
}

class _CenterBadgeOpacityRow extends StatefulWidget {
  const _CenterBadgeOpacityRow({
    required this.label,
    required this.sliderKey,
    required this.inputKey,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
  });

  final String label;
  final Key sliderKey;
  final Key inputKey;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_CenterBadgeOpacityRow> createState() => _CenterBadgeOpacityRowState();
}

class _CenterBadgeOpacityRowState extends State<_CenterBadgeOpacityRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  int get _clampedValue =>
      _clampNumber(widget.value, min: widget.min, max: widget.max);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '$_clampedValue');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _CenterBadgeOpacityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = '$_clampedValue';
    if (!_focusNode.hasFocus && _controller.text != nextText) {
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedValue = _clampedValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              widget.label,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              key: widget.sliderKey,
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
              value: clampedValue.toDouble(),
              onChanged: (next) => widget.onChanged(
                _clampNumber(next.round(), min: widget.min, max: widget.max),
              ),
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
              key: widget.inputKey,
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(
                signed: widget.min < 0,
              ),
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
    final clamped = _clampNumber(parsed, min: widget.min, max: widget.max);
    _controller.value = TextEditingValue(
      text: '$clamped',
      selection: TextSelection.collapsed(offset: '$clamped'.length),
    );
    widget.onChanged(clamped);
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

class _CenterBadgeOverlapMaskToggle extends StatelessWidget {
  const _CenterBadgeOverlapMaskToggle({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('center-badge-overlap-mask-toggle'),
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
                    'Átfedés maszkolás',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Csak színes Center Badge módban takarja ki az egymás alá csúszó badgeket.',
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
