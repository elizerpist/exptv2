import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/native_bridge.dart';
import 'settings_option_widgets.dart';

class PermissionsOptionsPanel extends StatelessWidget {
  const PermissionsOptionsPanel({super.key, required this.nativeBridge});

  final NativeBridge nativeBridge;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('permissions-options-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const SettingsSection(
          title: 'Használati útmutató',
          children: [
            _GuideText(
              '1. Engedélyezd az Android push értesítéseket, majd küldj teszt értesítést.',
            ),
            _GuideText(
              '2. Ha nem jelenik meg a teszt, nyisd meg az alkalmazás értesítési beállításait és kapcsold be az Exptv2 értesítéseket.',
            ),
            _GuideText(
              '3. Banki push feldolgozáshoz kapcsold be a Notification Listener hozzáférést. Accessibility csak tartalék capture módhoz kell.',
              isLast: true,
            ),
          ],
        ),
        SettingsSection(
          title: 'Android push értesítések',
          children: [
            SettingsOptionItem(
              key: const ValueKey('permissions-request-post'),
              title: 'Engedély kérése és teszt értesítés',
              trailing: const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
              ),
              onTap: () async {
                await nativeBridge.requestPostNotifications();
                await nativeBridge.sendTestNotification();
              },
            ),
            SettingsOptionItem(
              key: const ValueKey('permissions-app-notifications'),
              title: 'Alkalmazás értesítési beállításai',
              trailing: const Icon(Icons.open_in_new, color: AppColors.gray500),
              onTap: nativeBridge.openAppNotificationSettings,
            ),
            SettingsOptionItem(
              key: const ValueKey('permissions-app-info'),
              title: 'Android alkalmazásinfó',
              trailing: const Icon(
                Icons.settings_applications,
                color: AppColors.gray500,
              ),
              onTap: nativeBridge.openAppInfoSettings,
              isLast: true,
            ),
          ],
        ),
        SettingsSection(
          title: 'PushParser hozzáférések',
          children: [
            SettingsOptionItem(
              key: const ValueKey('permissions-notification-listener'),
              title: 'Notification Listener hozzáférés',
              trailing: const Icon(
                Icons.notifications_none,
                color: AppColors.gray500,
              ),
              onTap: nativeBridge.openNotificationAccessSettings,
            ),
            SettingsOptionItem(
              key: const ValueKey('permissions-accessibility'),
              title: 'Accessibility beállítások',
              trailing: const Icon(
                Icons.accessibility_new,
                color: AppColors.gray500,
              ),
              onTap: nativeBridge.openAccessibilitySettings,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _GuideText extends StatelessWidget {
  const _GuideText(this.text, {this.isLast = false});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.gray600,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}
