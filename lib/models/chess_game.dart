/// Represents a parsed chess game from PGN.
class ChessGame {
  final Map<String, String> headers;
  final List<GameMove> moves;
  final String rawPgn;

  const ChessGame({
    required this.headers,
    required this.moves,
    required this.rawPgn,
  });

  String get event => headers['Event'] ?? 'Unknown Event';
  String get white => headers['White'] ?? 'White';
  String get black => headers['Black'] ?? 'Black';
  String get result => headers['Result'] ?? '*';
  String get date => headers['Date'] ?? '';
  String get site => headers['Site'] ?? '';
  String get whiteElo => headers['WhiteElo'] ?? '';
  String get blackElo => headers['BlackElo'] ?? '';

  int get totalMoves => (moves.length + 1) ~/ 2; // full moves (pairs)
  String get pgn => rawPgn;
}

/// A single half-move (ply) in the game.
class GameMove {
  final int plyIndex;       // 0-based ply
  final int moveNumber;     // 1-based full-move number
  final bool isWhite;
  final String san;         // e.g. "Nf3"
  final String? fen;        // position AFTER this move
  final String? uci;        // e.g. "g1f3"

  const GameMove({
    required this.plyIndex,
    required this.moveNumber,
    required this.isWhite,
    required this.san,
    this.fen,
    this.uci,
  });

  GameMove copyWith({String? fen, String? uci}) => GameMove(
        plyIndex: plyIndex,
        moveNumber: moveNumber,
        isWhite: isWhite,
        san: san,
        fen: fen ?? this.fen,
        uci: uci ?? this.uci,
      );
}
