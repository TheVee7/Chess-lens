import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Vertical evaluation bar shown next to the chessboard.
class EvalBar extends StatelessWidget {
  /// Centipawn evaluation from White's perspective.
  final double evalCp;
  final bool isMate;
  final int? mateIn;

  const EvalBar({
    super.key,
    required this.evalCp,
    this.isMate = false,
    this.mateIn,
  });

  @override
  Widget build(BuildContext context) {
    // White fraction: 0.0 (all black) to 1.0 (all white).
    double whiteFraction;
    if (isMate && mateIn != null) {
      whiteFraction = mateIn! > 0 ? 1.0 : 0.0;
    } else {
      // Sigmoid-like mapping.
      final cp = evalCp.clamp(-1000.0, 1000.0);
      whiteFraction = 0.5 + (cp / 2000.0);
      whiteFraction = whiteFraction.clamp(0.05, 0.95);
    }

    String label;
    if (isMate && mateIn != null) {
      label = mateIn! > 0 ? 'M${mateIn!}' : 'M${mateIn!.abs()}';
    } else {
      final v = evalCp / 100;
      label = v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);
    }

    return SizedBox(
      width: 28,
      child: Column(
        children: [
          // Black region (top).
          Expanded(
            flex: ((1 - whiteFraction) * 1000).round(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: const BoxDecoration(
                color: AppTheme.blackEval,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: whiteFraction < 0.5
                  ? Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.whiteEval,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // White region (bottom).
          Expanded(
            flex: (whiteFraction * 1000).round(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: const BoxDecoration(
                color: AppTheme.whiteEval,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              child: whiteFraction >= 0.5
                  ? Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.blackEval,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
