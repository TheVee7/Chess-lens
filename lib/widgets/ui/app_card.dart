import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable card/tile: surface color (#121A22), radius 20, 1px border,
/// padding 16, optional title/header row, optional tap handler.
class AppCard extends StatelessWidget {
  final Widget? child;
  final Widget? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(AppTheme.tilePadding),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = AppTheme.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child ?? const SizedBox.shrink();
    if (title != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null) Expanded(child: title!),
              ?trailing,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      );
    }

    final decoration = BoxDecoration(
      color: backgroundColor ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppTheme.border,
        width: 1,
      ),
    );

    if (onTap != null) {
      return Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: decoration,
      child: content,
    );
  }
}
