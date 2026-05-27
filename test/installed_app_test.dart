import 'package:flutter_test/flutter_test.dart';
import 'package:exptv2/models/installed_app.dart';

void main() {
  test('fromMap parses package label and icon payload', () {
    final app = InstalledApp.fromMap({
      'packageName': 'com.airbnb.android',
      'label': 'AirBnB',
      'iconBase64': 'abc123',
    });

    expect(app.packageName, 'com.airbnb.android');
    expect(app.displayName, 'AirBnB');
    expect(app.iconBase64, 'abc123');
    expect(app.hasIcon, isTrue);
  });
}
