/// Classification of a move's quality.
enum MoveClassification {
  best,
  excellent,
  good,
  book,
  inaccuracy,
  mistake,
  blunder,
  forced,
}

/// Analysis result for a single move / position.
class MoveAnalysis {
  final int plyIndex;
  final int moveNumber;
  final bool isWhite;
  final String san;             // played move SAN
  final String fenBefore;       // position before the move
  final String fenAfter;        // position after the move

  // Stockfish data
  final double evalBefore;      // centipawn from White's perspective
  final double evalAfter;
  final bool isMateBefore;
  final bool isMateAfter;
  final int? mateBefore;        // mate-in-N (signed)
  final int? mateAfter;
  final String? bestMoveSan;    // engine best move (SAN)
  final String? bestMoveUci;    // engine best move (UCI)
  final List<String> pv;        // principal variation

  // Derived
  final double evalLoss;        // always >= 0, from the side-to-move's view
  final MoveClassification classification;
  final bool engineTimedOut;

  const MoveAnalysis({
    required this.plyIndex,
    required this.moveNumber,
    required this.isWhite,
    required this.san,
    required this.fenBefore,
    required this.fenAfter,
    required this.evalBefore,
    required this.evalAfter,
    this.isMateBefore = false,
    this.isMateAfter = false,
    this.mateBefore,
    this.mateAfter,
    this.bestMoveSan,
    this.bestMoveUci,
    this.pv = const [],
    required this.evalLoss,
    required this.classification,
    this.engineTimedOut = false,
  });

  /// Human-readable eval string (e.g., "+1.5" or "M3").
  String get evalBeforeStr => _formatEval(evalBefore, isMateBefore, mateBefore);
  String get evalAfterStr  => _formatEval(evalAfter, isMateAfter, mateAfter);

  static String _formatEval(double cp, bool isMate, int? mateIn) {
    if (isMate && mateIn != null) {
      return mateIn > 0 ? 'M$mateIn' : '-M${mateIn.abs()}';
    }
    final v = cp / 100;
    return v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);
  }

  /// Is this move interesting enough to warrant a Gemini explanation?
  bool get isImportant =>
      classification == MoveClassification.blunder ||
      classification == MoveClassification.mistake ||
      classification == MoveClassification.inaccuracy ||
      evalLoss >= 40;
}
