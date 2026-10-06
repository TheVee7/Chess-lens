import 'package:chess/chess.dart' as chess_lib;

/// Manages board positions and provides FEN / legal-move queries.
class PositionManager {
  final chess_lib.Chess _chess = chess_lib.Chess();

  /// Current FEN.
  String get fen => _chess.fen;

  /// Load a FEN string.
  bool load(String fen) => _chess.load(fen);

  /// Reset to the starting position.
  void reset() => _chess.reset();

  /// Make a move given SAN notation. Returns `true` on success.
  bool makeMove(String san) => _chess.move(san);

  /// Make a move given UCI notation (e.g. "e2e4"). Returns `true` on success.
  bool makeMoveUci(String uci) {
    if (uci.length < 4) return false;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promotion = uci.length > 4 ? uci[4] : null;
    return _chess.move({
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    });
  }

  /// Undo the last move.
  void undo() => _chess.undo();

  /// Convert a UCI move (e.g. "e2e4") to SAN in the current position.
  String? uciToSan(String uci) {
    if (uci.length < 4) return null;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promotion = uci.length > 4 ? uci[4] : null;

    // Try the move and capture the SAN, then undo.
    final moveObj = _chess.move({
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    });
    if (moveObj == false) return null;
    final san = _chess.san_moves().last;
    _chess.undo();
    return san;
  }

  /// Whether it is White's turn.
  bool get isWhiteTurn => _chess.turn == chess_lib.Color.WHITE;

  /// Whether the game is over.
  bool get isGameOver => _chess.game_over;

  /// Whether the position is check.
  bool get isCheck => _chess.in_check;

  /// Whether the position is checkmate.
  bool get isCheckmate => _chess.in_checkmate;

  /// Whether the position is stalemate.
  bool get isStalemate => _chess.in_stalemate;

  /// Piece at a given square (e.g. "e4").
  chess_lib.Piece? pieceAt(String square) => _chess.get(square);
}
