import 'package:flutter/material.dart';

const kAmbulanceHeaderVeilColor = Color(0xFFFFD84D);
const kAmbulanceHeaderVeilOpacity = 0.5;

class AmbulanceHeaderVeil extends StatelessWidget {
  const AmbulanceHeaderVeil({
    super.key,
    required this.opacityKey,
    required this.borderRadius,
  });

  final Key opacityKey;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Opacity(
          key: opacityKey,
          opacity: kAmbulanceHeaderVeilOpacity,
          child: const ColoredBox(color: kAmbulanceHeaderVeilColor),
        ),
      ),
    );
  }
}
