import 'package:flutter/material.dart';

import 'debug_console.dart';

class DebugTextField extends StatefulWidget {
  const DebugTextField({
    super.key,
    required this.debugLabel,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.textAlign = TextAlign.start,
    this.style,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled,
    this.minLines,
    this.maxLines = 1,
  });

  final String debugLabel;
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool autofocus;
  final bool readOnly;
  final bool? enabled;
  final int? minLines;
  final int? maxLines;

  @override
  State<DebugTextField> createState() => _DebugTextFieldState();
}

class _DebugTextFieldState extends State<DebugTextField> {
  FocusNode? _ownedFocusNode;
  DateTime? _pointerDownAt;
  DateTime? _focusStartedAt;
  double? _lastLoggedKeyboardInset;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: widget.debugLabel);
    }
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(DebugTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    oldFocusNode?.removeListener(_handleFocusChanged);
    if (widget.focusNode == null && _ownedFocusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: widget.debugLabel);
    }
    _focusNode.addListener(_handleFocusChanged);
    _lastLoggedKeyboardInset = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _maybeLogKeyboardInset();
    return Listener(
      onPointerDown: _handlePointerDown,
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        onTapOutside: widget.onTapOutside,
        textAlign: widget.textAlign,
        style: widget.style,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownAt = DateTime.now();
    DebugConsole.log(
      '[Perf] TextInput pointer label=${widget.debugLabel} '
      'focused=${_focusNode.hasFocus} keyboard=${_keyboardInsetText()}',
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _focusStartedAt = DateTime.now();
      _lastLoggedKeyboardInset = null;
      DebugConsole.log(
        '[Perf] TextInput focus label=${widget.debugLabel} active=true '
        'requestElapsed=${_elapsedMs(_pointerDownAt)}ms '
        'keyboard=${_keyboardInsetText()}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        DebugConsole.log(
          '[Perf] TextInput focus frame label=${widget.debugLabel} '
          'elapsed=${_elapsedMs(_focusStartedAt)}ms '
          'keyboard=${_keyboardInsetText()}',
        );
      });
      return;
    }

    DebugConsole.log(
      '[Perf] TextInput focus label=${widget.debugLabel} active=false '
      'elapsed=${_elapsedMs(_focusStartedAt)}ms '
      'keyboard=${_keyboardInsetText()}',
    );
    _focusStartedAt = null;
    _lastLoggedKeyboardInset = null;
  }

  void _maybeLogKeyboardInset() {
    if (!_focusNode.hasFocus) return;
    final inset = _keyboardInset();
    final previous = _lastLoggedKeyboardInset;
    if (previous != null && (previous - inset).abs() < 0.5) return;
    _lastLoggedKeyboardInset = inset;
    DebugConsole.log(
      '[Perf] TextInput keyboard label=${widget.debugLabel} '
      'inset=${inset.toStringAsFixed(1)} active=true',
    );
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  double _keyboardInset() {
    return MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
  }

  String _keyboardInsetText() => _keyboardInset().toStringAsFixed(1);
}

class DebugTextFormField extends StatefulWidget {
  const DebugTextFormField({
    super.key,
    required this.debugLabel,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.decoration,
    this.onChanged,
    this.onTapOutside,
    this.validator,
    this.autofocus = false,
    this.enabled,
    this.minLines,
    this.maxLines = 1,
  });

  final String debugLabel;
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final TapRegionCallback? onTapOutside;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool? enabled;
  final int? minLines;
  final int? maxLines;

  @override
  State<DebugTextFormField> createState() => _DebugTextFormFieldState();
}

class _DebugTextFormFieldState extends State<DebugTextFormField> {
  FocusNode? _ownedFocusNode;
  DateTime? _pointerDownAt;
  DateTime? _focusStartedAt;
  double? _lastLoggedKeyboardInset;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: widget.debugLabel);
    }
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(DebugTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    oldFocusNode?.removeListener(_handleFocusChanged);
    if (widget.focusNode == null && _ownedFocusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: widget.debugLabel);
    }
    _focusNode.addListener(_handleFocusChanged);
    _lastLoggedKeyboardInset = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _maybeLogKeyboardInset();
    return Listener(
      onPointerDown: _handlePointerDown,
      child: TextFormField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        onTapOutside: widget.onTapOutside,
        validator: widget.validator,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownAt = DateTime.now();
    DebugConsole.log(
      '[Perf] TextInput pointer label=${widget.debugLabel} '
      'focused=${_focusNode.hasFocus} keyboard=${_keyboardInsetText()}',
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _focusStartedAt = DateTime.now();
      _lastLoggedKeyboardInset = null;
      DebugConsole.log(
        '[Perf] TextInput focus label=${widget.debugLabel} active=true '
        'requestElapsed=${_elapsedMs(_pointerDownAt)}ms '
        'keyboard=${_keyboardInsetText()}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        DebugConsole.log(
          '[Perf] TextInput focus frame label=${widget.debugLabel} '
          'elapsed=${_elapsedMs(_focusStartedAt)}ms '
          'keyboard=${_keyboardInsetText()}',
        );
      });
      return;
    }

    DebugConsole.log(
      '[Perf] TextInput focus label=${widget.debugLabel} active=false '
      'elapsed=${_elapsedMs(_focusStartedAt)}ms '
      'keyboard=${_keyboardInsetText()}',
    );
    _focusStartedAt = null;
    _lastLoggedKeyboardInset = null;
  }

  void _maybeLogKeyboardInset() {
    if (!_focusNode.hasFocus) return;
    final inset = _keyboardInset();
    final previous = _lastLoggedKeyboardInset;
    if (previous != null && (previous - inset).abs() < 0.5) return;
    _lastLoggedKeyboardInset = inset;
    DebugConsole.log(
      '[Perf] TextInput keyboard label=${widget.debugLabel} '
      'inset=${inset.toStringAsFixed(1)} active=true',
    );
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  double _keyboardInset() {
    return MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
  }

  String _keyboardInsetText() => _keyboardInset().toStringAsFixed(1);
}
