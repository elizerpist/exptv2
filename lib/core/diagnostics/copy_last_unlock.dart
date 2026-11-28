import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies the ordinary unlock receipt without opening or changing the recorder.
class CopyLastUnlock extends StatefulWidget {
  const CopyLastUnlock({super.key, this.feedbackStyle});

  final TextStyle? feedbackStyle;

  @override
  State<CopyLastUnlock> createState() => _CopyLastUnlockState();
}

class _CopyLastUnlockState extends State<CopyLastUnlock> {
  static const _channel = MethodChannel('fluvi/wa_lockscreen_capture');
  bool _copying = false;
  String? _feedback;

  Future<void> _copy() async {
    if (_copying) return;
    setState(() {
      _copying = true;
      _feedback = null;
    });
    String message;
    try {
      final snapshot = await _channel.invokeMapMethod<String, Object?>(
        'getLastUnlock',
      );
      final text = snapshot?['text'];
      message = switch (snapshot?['status']) {
        'EMPTY' => 'Még nincs napló. Oldd fel a telefont látható ORB mellett.',
        'INACTIVE' => 'Az ORB-szolgáltatásra várunk.',
        _ => 'A feloldási napló nem olvasható. Próbáld újra.',
      };
      if (snapshot?['status'] == 'READY' &&
          text is String &&
          text.trim().isNotEmpty) {
        message = 'A másolás sikertelen. Próbáld újra.';
        try {
          if (!mounted) return;
          await Clipboard.setData(ClipboardData(text: text));
          message = 'A feloldási napló a vágólapon van.';
        } on PlatformException {
          // A stored report is available for another attempt.
        } on MissingPluginException {
          // Clipboard access is unavailable.
        }
      }
    } on PlatformException {
      message = 'A feloldási napló nem olvasható. Próbáld újra.';
    } on MissingPluginException {
      message = 'A feloldási napló nem olvasható. Próbáld újra.';
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
        key: const ValueKey('wa-last-unlock-copy'),
        onPressed: _copying ? null : _copy,
        child: const Text('Legutóbbi feloldás másolása'),
      ),
      if (_feedback case final feedback?)
        Text(
          feedback,
          style: widget.feedbackStyle,
          key: const ValueKey('wa-last-unlock-feedback'),
        ),
    ],
  );
}
