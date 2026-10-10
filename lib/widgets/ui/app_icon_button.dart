import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Icon button with 48x48 minimum tap target, surfaceRaised fill, 1px border.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.size = 48.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusInner),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusInner),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: enabled
                  ? (iconColor ?? AppTheme.textPrimary)
                  : AppTheme.textDisabled,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(child: button),
      ),
    );
  }
}
