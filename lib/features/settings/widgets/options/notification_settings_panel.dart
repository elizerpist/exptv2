import 'package:flutter/material.dart';

import '../../models/notification_settings.dart';
import 'settings_option_widgets.dart';

class NotificationSettingsPanel extends StatelessWidget {
  const NotificationSettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('notification-settings-panel'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'Megjelenítés',
          children: [
            SettingsOptionItem(
              title: 'Android push',
              subtitle: 'Rendszerszintű értesítés küldése',
              trailing: Switch(
                value: settings.androidPushEnabled,
                onChanged: (value) => onChanged(
                  settings.copyWith(androidPushEnabled: value),
                ),
              ),
            ),
            SettingsOptionItem(
              title: 'Appon belüli kártyák',
              subtitle: 'Értesítések megjelenítése az értesítés menüben',
              trailing: Switch(
                value: settings.inAppCardsEnabled,
                onChanged: (value) => onChanged(
                  settings.copyWith(inAppCardsEnabled: value),
                ),
              ),
              isLast: true,
            ),
          ],
        ),
        SettingsSection(
          title: 'Típusok',
          children: [
            SettingsOptionItem(
              title: 'Limit riasztások',
              subtitle: '75% és túllépés jelzése időszakkal',
              trailing: Switch(
                value: settings.limitAlertsEnabled,
                onChanged: (value) => onChanged(
                  settings.copyWith(limitAlertsEnabled: value),
                ),
              ),
            ),
            SettingsOptionItem(
              title: 'Ismétlődő tranzakciók',
              subtitle: 'Aktivált ismétlődő költések jelzése',
              trailing: Switch(
                value: settings.recurringAlertsEnabled,
                onChanged: (value) => onChanged(
                  settings.copyWith(recurringAlertsEnabled: value),
                ),
              ),
            ),
            SettingsOptionItem(
              title: 'Új tranzakciók',
              subtitle: 'Manuális és automatikus rögzítések jelzése',
              trailing: Switch(
                value: settings.transactionAlertsEnabled,
                onChanged: (value) => onChanged(
                  settings.copyWith(transactionAlertsEnabled: value),
                ),
              ),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}
