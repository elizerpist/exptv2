import 'app/fluvi_app.dart';
import 'core/diagnostics/fluvi_build_identity.dart';
import 'package:flutter/widgets.dart';

void main() {
  verifyFluviHumanBuildIntegrity();
  runApp(const FluviApp());
}
