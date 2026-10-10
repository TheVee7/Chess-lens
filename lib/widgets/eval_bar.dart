import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Symmetrical horizontal evaluation bar positioned directly under the chessboard.
///
/// Shows White fill (light `#EDEFF2`) and Black fill (dark `#2A313A`) with a subtle
/// center tick, 250ms smooth transition, and contrasting tabular-figures evaluation text
/// positioned inside the bar on the side currently leading.
class EvalBar extends StatelessWidget {
  /// Centipawn evaluation from White's perspective.
  final double evalCp;
  final bool isMate;
  final int? mateIn;
  final bool flipped;
  final double height;

  const EvalBar({
    super.key,
    required this.evalCp,
    this.isMate = false,
    this.mateIn,
    this.flipped = false,
    this.height = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    // White fraction from 0.0 (all black) to 1.0 (all white).
    double whiteFraction;
    if (isMate && mateIn != null) {
      whiteFraction = mateIn! > 0 ? 1.0 : 0.0;
    } else {
      final cp = evalCp.clamp(-1000.0, 1000.0);
      whiteFraction = 0.5 + (cp / 2000.0);
      whiteFraction = whiteFraction.clamp(0.05, 0.95);
    }

    final bool whiteIsAhead = (isMate && mateIn != null) ? mateIn! > 0 : evalCp >= 0;

    // By default: White is on the left, Black is on the right.
    // When board is flipped: Black is on the left, White is on the right.
    final double leftFraction = flipped ? (1.0 - whiteFraction) : whiteFraction;
    final Color leftColor = flipped ? AppTheme.evalBlack : AppTheme.evalWhite;
    final Color rightColor = flipped ? AppTheme.evalWhite : AppTheme.evalBlack;

    // Evaluation text
    final String label = _formatLabel();
    final String semanticsLabel = _formatSemantics();

    // Alignment and text color for the leading side:
    // If White is ahead and White is on left: left align, dark text on white fill.
    // If White is ahead and White is on right: right align, dark text on white fill.
    // If Black is ahead and Black is on right: right align, light text on dark fill.
    // If Black is ahead and Black is on left: left align, light text on dark fill.
    final bool leadingIsOnLeft = whiteIsAhead ? !flipped : flipped;
    final Alignment labelAlignment = leadingIsOnLeft ? Alignment.centerLeft : Alignment.centerRight;
    final Color labelColor = whiteIsAhead ? AppTheme.evalBlack : AppTheme.evalWhite;

    final radius = BorderRadius.circular(height / 2);

    return Semantics(
      label: semanticsLabel,
      value: label,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppTheme.border, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: leftFraction),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, animLeftFraction, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
                final leftW = (totalW * animLeftFraction).clamp(0.0, totalW);
                final rightW = totalW - leftW;

                return Stack(
                  children: [
                    // Fill tracks
                    Row(
                      children: [
                        SizedBox(
                          width: leftW,
                          height: height,
                          child: ColoredBox(color: leftColor),
                        ),
                        SizedBox(
                          width: rightW,
                          height: height,
                          child: ColoredBox(color: rightColor),
                        ),
                      ],
                    ),

                    // Subtle center tick
                    Center(
                      child: Container(
                        width: 1.5,
                        height: height * 0.7,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),

                    // Evaluation text at the ahead end
                    Align(
                      alignment: labelAlignment,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatLabel() {
    if (isMate && mateIn != null) {
      return mateIn! > 0 ? 'M${mateIn!}' : '-M${mateIn!.abs()}';
    }
    final v = evalCp / 100;
    return v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);
  }

  String _formatSemantics() {
    if (isMate && mateIn != null) {
      if (mateIn! > 0) return 'White has checkmate in ${mateIn!}';
      if (mateIn! < 0) return 'Black has checkmate in ${mateIn!.abs()}';
      return 'Checkmate';
    }
    final v = evalCp / 100;
    if (v > 0) return 'White is better by ${v.toStringAsFixed(1)}';
    if (v < 0) return 'Black is better by ${(-v).toStringAsFixed(1)}';
    return 'Evaluation is even';
  }
}
