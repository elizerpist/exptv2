import 'package:flutter/material.dart';

import '../../services/native_ime_sheet_bridge.dart';

class NativeImeSheetProbeApp extends StatelessWidget {
  const NativeImeSheetProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NativeImeSheetProbe(),
    );
  }
}

class NativeImeSheetProbe extends StatefulWidget {
  const NativeImeSheetProbe({super.key, NativeImeSheetBridge? bridge})
    : _bridge = bridge;

  final NativeImeSheetBridge? _bridge;

  @override
  State<NativeImeSheetProbe> createState() => _NativeImeSheetProbeState();
}

class _NativeImeSheetProbeState extends State<NativeImeSheetProbe> {
  late final NativeImeSheetBridge _bridge =
      widget._bridge ?? NativeImeSheetBridge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('native-ime-sheet-probe'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Native IME sheet probe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('native-ime-sheet-probe-close'),
                    tooltip: 'Close',
                    onPressed: _bridge.closeProbe,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('native-ime-sheet-probe-amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                key: ValueKey('native-ime-sheet-probe-name'),
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This probe keeps outer motion native; Flutter only renders content.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
