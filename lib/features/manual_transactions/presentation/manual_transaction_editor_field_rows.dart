import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';

/// The closed-state vocabulary used by the transaction editor.  Pickers may
/// have richer menus, but their anchors deliberately stay simple, borderless
/// information rows in both editor layouts.
final class ManualEditorSelectionRow extends StatelessWidget {
  const ManualEditorSelectionRow({
    super.key,
    required this.label,
    required this.value,
    required this.leading,
    required this.onTap,
    this.enabled = true,
    this.valueSemantics,
    this.expanded = false,
  });

  final String label;
  final String value;
  final Widget leading;
  final VoidCallback? onTap;
  final bool enabled;
  final String? valueSemantics;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: valueSemantics ?? '$label: $value',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FluviVisualTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.chevron_right_rounded,
                color: FluviVisualTokens.textSecondary,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Fixed icon geometry for the date, time, note and empty-partner states.
final class ManualEditorIconSurface extends StatelessWidget {
  const ManualEditorIconSurface({
    super.key,
    required this.icon,
    this.color = const Color(0xff6d28d9),
    this.background = const Color(0xfff1eaff),
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: 22),
  );
}

const manualEditorDivider = Divider(
  height: 1,
  thickness: 1,
  color: Color(0xffe6eaf1),
);
