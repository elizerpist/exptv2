enum NotificationSmallIconStyle {
  outline('outline'),
  filled('filled');

  const NotificationSmallIconStyle(this.storageValue);

  final String storageValue;

  static NotificationSmallIconStyle fromStorage(Object? value) =>
      NotificationSmallIconStyle.values.firstWhere(
        (style) => style.storageValue == value,
        orElse: () => NotificationSmallIconStyle.outline,
      );
}

abstract interface class NotificationAppearanceRepository {
  Future<NotificationSmallIconStyle> smallIconStyle();

  /// Resolves only after native durable storage accepted the final choice.
  Future<NotificationSmallIconStyle> setSmallIconStyle(
    NotificationSmallIconStyle style,
  );
}
