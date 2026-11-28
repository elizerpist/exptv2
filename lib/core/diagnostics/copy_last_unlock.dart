import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies the requested lockscreen receipt without opening or changing the recorder.
class CopyLastUnlock extends StatefulWidget {
  const CopyLastUnlock({super.key, this.feedbackStyle, this.ambient = false});

  final TextStyle? feedbackStyle;
  final bool ambient;

  @override
  State<CopyLastUnlock> createState() => _CopyLastUnlockState();
}

class _CopyLastUnlockState extends State<CopyLastUnlock> {
  static const _channel = MethodChannel('fluvi/wa_lockscreen_capture');
  bool _copying = false;
  String? _feedback;
  String get _receiptKey =>
      widget.ambient ? 'wa-last-ambient' : 'wa-last-unlock';
  String get _readFailed => widget.ambient
      ? 'Az AOD-napló nem olvasható. Próbáld újra.'
      : 'A feloldási napló nem olvasható. Próbáld újra.';

  Future<void> _copy() async {
    if (_copying) return;
    setState(() {
      _copying = true;
      _feedback = null;
    });
    String message;
    try {
      final snapshot = await _channel.invokeMapMethod<String, Object?>(
        widget.ambient ? 'getLastAmbient' : 'getLastUnlock',
      );
      final text = snapshot?['text'];
      message = switch (snapshot?['status']) {
        'EMPTY' =>
          widget.ambient
              ? 'Még nincs AOD-napló. Sötétítsd vissza a lezárt kijelzőt.'
              : 'Még nincs napló. Oldd fel a telefont látható ORB mellett.',
        'INACTIVE' => 'Az ORB-szolgáltatásra várunk.',
        _ => _readFailed,
      };
      if (snapshot?['status'] == 'READY' &&
          text is String &&
          text.trim().isNotEmpty) {
        message = 'A másolás sikertelen. Próbáld újra.';
        try {
          if (!mounted) return;
          await Clipboard.setData(ClipboardData(text: text));
          message = widget.ambient
              ? 'Az AOD-napló a vágólapon van.'
              : 'A feloldási napló a vágólapon van.';
        } on PlatformException {
          // A stored report is available for another attempt.
        } on MissingPluginException {
          // Clipboard access is unavailable.
        }
      }
    } on PlatformException {
      message = _readFailed;
    } on MissingPluginException {
      message = _readFailed;
    }
    if (mounted) {
      setState(() {
        _copying = false;
        _feedback = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton(
        key: ValueKey('$_receiptKey-copy'),
        onPressed: _copying ? null : _copy,
        child: Text(
          widget.ambient
              ? 'Legutóbbi AOD-próba másolása'
              : 'Legutóbbi feloldás másolása',
        ),
      ),
      if (_feedback case final feedback?)
        Text(
          feedback,
          style: widget.feedbackStyle,
          key: ValueKey('$_receiptKey-feedback'),
        ),
    ],
  );
}
