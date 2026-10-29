import 'package:flutter/material.dart';

/// Immutable authored colour scales shared by independent dashboard renderers.
///
/// These values deliberately contain only paint tokens.  They carry no Mind
/// score, Balance state, sampling policy, or animation ownership, so a caller
/// keeps its existing semantic and rendering behaviour while sharing the one
/// approved source of the authored stops.
abstract final class FluviSharedColorScales {
  static const List<Color> b3mMy3 = <Color>[
    Color(0xFFF4F7FB),
    Color(0xFFFFEEDA),
    Color(0xFFFFD5AF),
    Color(0xFFFFB15C),
    Color(0xFFFF8D64),
    Color(0xFFFF6B6B),
    Color(0xFFF536BD),
    Color(0xFFD03CB0),
    Color(0xFFA237BF),
    Color(0xFF821AC2),
  ];

  static const List<Color> dynamicRedB3mBridge = <Color>[
    Color(0xFFFFF0E4),
    Color(0xFFFFE0C8),
    Color(0xFFFEC7A6),
    Color(0xFFFDA77F),
    Color(0xFFF7866C),
    Color(0xFFF26862),
    Color(0xFFE95276),
    Color(0xFFD33F8D),
    Color(0xFFB433A0),
    Color(0xFF9227A8),
  ];
}
