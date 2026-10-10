import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Primary call-to-action button: mint green fill (#61E486), dark label (#0B1117),
/// optional trailing arrow, height 52, radius 14.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool showTrailingArrow;
  final IconData? leadingIcon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.showTrailingArrow = false,
    this.leadingIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        height: AppTheme.buttonHeight,
        child: Material(
          color: enabled ? AppTheme.primary : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(
                              leadingIcon,
                              size: 18,
                              color: enabled
                                  ? AppTheme.onPrimary
                                  : AppTheme.textDisabled,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: enabled
                                      ? AppTheme.onPrimary
                                      : AppTheme.textDisabled,
                                ),
                              ),
                            ),
                          ),
                          if (showTrailingArrow) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: enabled
                                  ? AppTheme.onPrimary
                                  : AppTheme.textDisabled,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button: surfaceRaised fill, 1px border, textPrimary label,
/// height 52, radius 14.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        height: AppTheme.buttonHeight,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(
              color: AppTheme.border,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leadingIcon != null) ...[
                              Icon(
                                leadingIcon,
                                size: 18,
                                color: enabled
                                    ? AppTheme.textPrimary
                                    : AppTheme.textDisabled,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: enabled
                                        ? AppTheme.textPrimary
                                        : AppTheme.textDisabled,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet text button with minimum 48 tap target.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
