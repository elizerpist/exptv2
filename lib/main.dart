import 'package:flutter/material.dart';

import 'exptv2_app.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

export 'exptv2_app.dart';

void main() {
  runApp(Exptv2App(store: EventStore(NativeBridge())));
}
