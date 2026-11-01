import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_surface_fill.dart';
import 'fluvi_brand_mark.dart';

/// The locally owned Fluvi mark, wordmark, and motto as one reusable unit.
class FluviBrandLockup extends StatelessWidget {
  const FluviBrandLockup({
    super.key,
    required this.bounds,
    required this.appearance,
    this.onLogoTap,
  });

  final DashboardBounds bounds;
  final FluviBrandSurfaceAppearance appearance;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: onLogoTap != null,
            label: 'Fluvi logó testreszabása',
            child: FocusableActionDetector(
              enabled: onLogoTap != null,
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    onLogoTap?.call();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                key: const ValueKey('fluvi-brand-mark-tap'),
                behavior: HitTestBehavior.opaque,
                onTap: onLogoTap,
                child: FluviBrandMark(
                  key: const ValueKey('fluvi-brand-mark'),
                  appearance: appearance,
                  width: FluviVisualTokens.brandMarkSize,
                  height: FluviVisualTokens.brandMarkSize,
                ),
              ),
            ),
          ),
          const SizedBox(width: FluviVisualTokens.brandGap),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fluvi',
                    key: const ValueKey('fluvi-wordmark'),
                    style: FluviVisualTokens.brandWordmarkTextStyle,
                  ),
                  Text(
                    'your personal financial trainer',
                    key: const ValueKey('fluvi-motto'),
                    style: FluviVisualTokens.brandMottoTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark-sized interactive overlay used when the lockup itself must remain
/// below another full-header hit target. Keeping this separate prevents the
/// wordmark's otherwise inert render box from swallowing header gestures.
class FluviBrandEditorTapTarget extends StatelessWidget {
  const FluviBrandEditorTapTarget({super.key, required this.onActivate});

  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Fluvi logó testreszabása',
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onActivate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: const ValueKey('fluvi-brand-mark-tap'),
          behavior: HitTestBehavior.opaque,
          onTap: onActivate,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
