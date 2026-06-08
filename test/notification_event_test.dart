import 'package:exptv2/features/settings/models/push_notification_log_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exptv2/models/notification_event.dart';

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

  test('push log event parses status and falls back to notification body', () {
    final event = PushNotificationLogEvent.fromMap({
      'id': 7,
      'timestamp': 1710000000000,
      'source': 'notification_listener',
      'packageName': 'com.bank',
      'appLabel': 'Bank',
      'title': 'Vásárlás',
      'text': 'Kártyás vásárlás',
      'bigText': 'Tesco - 12 345 HUF',
      'subText': '',
      'category': '',
      'notificationKey': 'key-1',
      'accessibilityEventType': '',
      'hash': 'abc',
      'isDuplicate': false,
      'manualStatus': '',
      'displayText': '',
      'status': 'linked',
      'statusText': 'Van tranzakció',
      'linkedTransactionId': '26060701',
    });

    expect(event.status, PushNotificationLogStatus.linked);
    expect(event.statusText, 'Van tranzakció');
    expect(event.linkedTransactionId, 26060701);
    expect(event.hasLinkedTransaction, isTrue);
    expect(event.fullText, contains('Tesco'));
  });

  test('push log query can clear nullable filters', () {
    const query = PushNotificationLogQuery(
      year: 2026,
      month: 6,
      packageName: 'hu.bank.app',
    );

    final cleared = query.copyWith(year: null, month: null, packageName: null);

    expect(cleared.year, isNull);
    expect(cleared.month, isNull);
    expect(cleared.packageName, isNull);
    expect(cleared.toMap(), containsPair('status', 'all'));
  });
}
