import 'package:flutter_test/flutter_test.dart';
import 'package:pushparserv2/models/notification_event.dart';

void main() {
  test('fromMap parses native event payload', () {
    final event = NotificationEvent.fromMap({
      'id': 7,
      'timestamp': 1710000000000,
      'source': 'notification_listener',
      'packageName': 'com.example.chat',
      'appLabel': 'Example Chat',
      'title': 'Alice',
      'text': 'Hello',
      'bigText': 'Hello there',
      'subText': '',
      'category': 'msg',
      'notificationKey': 'key-1',
      'accessibilityEventType': '',
      'hash': 'abc',
      'isDuplicate': true,
    });

    expect(event.id, 7);
    expect(event.sourceBadge, 'NL');
    expect(event.displayApp, 'Example Chat');
    expect(event.bodyText, contains('Hello'));
    expect(event.isDuplicate, isTrue);
  });

  test('matchesApp checks app label and package name only', () {
    final event = NotificationEvent.fromMap({
      'id': 1,
      'timestamp': 1710000000000,
      'source': 'accessibility',
      'packageName': 'org.telegram.messenger',
      'appLabel': 'Telegram',
      'title': 'Bank',
      'text': 'OTP message',
      'bigText': '',
      'subText': '',
      'category': '',
      'notificationKey': '',
      'accessibilityEventType': '64',
      'hash': 'hash',
      'isDuplicate': false,
    });

    expect(event.matchesApp(RegExp('Telegram')), isTrue);
    expect(event.matchesApp(RegExp('telegram\\.messenger')), isTrue);
    expect(event.matchesApp(RegExp('OTP')), isFalse);
  });
}
