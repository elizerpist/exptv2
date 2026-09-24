import 'package:flutter/widgets.dart';

import '../../design/fluvi_global_appearance.dart';

/// Publishes the selected category avatar treatment without altering semantic
/// category identity or introducing an additional data/settings owner.
class CategoryAvatarColorProfileScope extends InheritedWidget {
  const CategoryAvatarColorProfileScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final CategoryAvatarColorProfile profile;

  static CategoryAvatarColorProfile profileOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CategoryAvatarColorProfileScope>()
          ?.profile ??
      CategoryAvatarColorProfile.original;

  @override
  bool updateShouldNotify(CategoryAvatarColorProfileScope oldWidget) =>
      profile != oldWidget.profile;
}
