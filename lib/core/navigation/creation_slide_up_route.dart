import 'package:flutter/material.dart';

/// The shared creation route for full-screen editor flows.
///
/// Keeping this outside the app shell lets feature navigation use the exact
/// same vertical entrance and reverse exit without depending on shell state.
PageRouteBuilder<T> creationSlideUpRoute<T>({
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
}) => PageRouteBuilder<T>(
  fullscreenDialog: fullscreenDialog,
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      ),
);
