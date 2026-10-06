import 'move_analysis.dart';

/// The complete Stockfish analysis of a game.
class GameAnalysis {
  final List<MoveAnalysis> moves;
  final double whiteAccuracy;
  final double blackAccuracy;
  final Map<MoveClassification, int> whiteClassifications;
  final Map<MoveClassification, int> blackClassifications;

  const GameAnalysis({
    required this.moves,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteClassifications,
    required this.blackClassifications,
  });

  /// All critical moments (important moves worth explaining).
  List<MoveAnalysis> get criticalMoments =>
      moves.where((m) => m.isImportant).toList();

  /// Evaluations for the graph (white-perspective centipawns).
  List<double> get evaluations => moves.map((m) => m.evalAfter).toList();
}
