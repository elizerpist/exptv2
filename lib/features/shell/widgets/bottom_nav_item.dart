import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';
import '../app_tab.dart';

class BottomNavItem extends StatefulWidget {
  const BottomNavItem({
    super.key,
    required this.tab,
    required this.active,
    required this.onTap,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
    this.accentLightColor = AppColors.primaryLight,
    this.activeBackgroundColor = AppColors.primaryActiveBackground,
    this.onPointerDown,
    this.badgeCount = 0,
    this.label,
    this.icon,
    this.iconGlyph,
    this.horizontalMargin = AppDimensions.navItemHorizontalMargin,
    this.radius = AppDimensions.navItemRadius,
    this.iconSize = AppDimensions.navIconSize,
    this.iconBoxWidth = 34,
    this.iconBoxHeight = AppDimensions.navIconSize,
    this.labelFontSize = 12,
    this.itemHeight,
    this.fontFamily,
    this.iconFontFamily,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color accentColor;
  final Color accentLightColor;
  final Color activeBackgroundColor;
  final VoidCallback? onPointerDown;
  final int badgeCount;
  final String? label;
  final IconData? icon;
  final String? iconGlyph;
  final double horizontalMargin;
  final double radius;
  final double iconSize;
  final double iconBoxWidth;
  final double iconBoxHeight;
  final double labelFontSize;
  final double? itemHeight;
  final String? fontFamily;
  final String? iconFontFamily;

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> {
  var _pressed = false;
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final active = widget.active;
    final surfaceStyle = widget.surfaceStyle;
    final activeSurfaceStyle =
        active && surfaceStyle == ExpenseSurfaceInteraction.neutralInset
        ? ExpenseSurfaceInteraction.insetInset
        : surfaceStyle;
    final surfaceColor = widget.surfaceColor;
    final badgeCount = widget.badgeCount;
    final icon = widget.icon ?? tab.icon;
    final label = widget.label ?? tab.label;
    final color = active ? widget.accentColor : tab.inactiveColor;
    final radius = BorderRadius.circular(widget.radius);
    final surfaceTint =
        active && activeSurfaceStyle != ExpenseSurfaceInteraction.neutralNeutral
        ? Color.lerp(surfaceColor, widget.accentLightColor, 0.16)!
        : surfaceColor;
    final materialFeedback = ExpenseSurface.materialFeedbackEnabled(
      activeSurfaceStyle,
    );

    final surface = ExpensePressable(
      enabled: activeSurfaceStyle.hasPressEffect,
      forcePressed: _pressed,
      builder: (context, pressed) {
        final resolvedColor =
            active &&
                activeSurfaceStyle == ExpenseSurfaceInteraction.neutralNeutral
            ? widget.activeBackgroundColor
            : surfaceTint;
        return ExpenseSurfaceContainer(
          surfaceKey: ValueKey('bottom-nav-${tab.id}-surface'),
          style: activeSurfaceStyle,
          color: resolvedColor,
          primaryColor: widget.accentColor,
          borderRadius: radius,
          pressed: pressed,
          neutralShadow: null,
          profile: active
              ? ExpenseSurfaceProfile.activeNavItem
              : ExpenseSurfaceProfile.standard,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                _releaseTimer?.cancel();
                _setPressed(true);
                widget.onPointerDown?.call();
              },
              onPointerUp: (_) => _releasePressedSoon(),
              onPointerCancel: (_) => _releasePressedSoon(),
              child: Semantics(
                label: label,
                button: true,
                selected: active,
                excludeSemantics: true,
                onTap: widget.onTap,
                child: InkWell(
                  key: ValueKey('bottom-nav-${tab.id}'),
                  borderRadius: radius,
                  overlayColor: materialFeedback
                      ? null
                      : ExpenseSurface.transparentOverlayColor,
                  splashColor: materialFeedback ? null : Colors.transparent,
                  highlightColor: materialFeedback ? null : Colors.transparent,
                  onHighlightChanged: activeSurfaceStyle.hasPressEffect
                      ? _handleHighlightChanged
                      : null,
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.navItemVerticalPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: widget.iconBoxWidth,
                          height: widget.iconBoxHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if (widget.iconGlyph case final glyph?)
                                ExcludeSemantics(
                                  child: Text(
                                    glyph,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: color,
                                      fontFamily:
                                          widget.iconFontFamily ??
                                          widget.fontFamily,
                                      fontSize: widget.iconSize,
                                      height: 1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              else
                                ExcludeSemantics(
                                  child: Icon(
                                    icon,
                                    size: widget.iconSize,
                                    color: color,
                                  ),
                                ),
                              if (badgeCount > 0)
                                Positioned(
                                  top: -5,
                                  right: 0,
                                  child: _UnreadBadge(
                                    tabId: tab.id,
                                    count: badgeCount,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.navLabelTopMargin),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontFamily: widget.fontFamily,
                            fontSize: widget.labelFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    final paddedSurface = Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
      child: widget.itemHeight == null
          ? surface
          : SizedBox(
              height: widget.itemHeight,
              width: double.infinity,
              child: surface,
            ),
    );
    return Expanded(child: paddedSurface);
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _releasePressedSoon() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(milliseconds: 120), () {
      _setPressed(false);
    });
  }

  void _handleHighlightChanged(bool highlighted) {
    if (highlighted) {
      _releaseTimer?.cancel();
      _setPressed(true);
      return;
    }
    _releasePressedSoon();
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.tabId, required this.count});

  final String tabId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      key: ValueKey('bottom-nav-$tabId-unread-badge'),
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.expense,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
