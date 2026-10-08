import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_game.dart';

class _ParsedToken {
  final String san;
  final int lineNumber;

  const _ParsedToken(this.san, this.lineNumber);
}

/// Robust parser for PGN text into a [ChessGame] model.
class PgnParser {
  PgnParser._();

  /// Parse a raw PGN string. Throws [FormatException] on invalid input.
  static ChessGame parse(String pgn) {
    final trimmed = pgn.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('PGN is empty');
    }

    // ── Handle multi-game PGNs (take the first game) ───────────
    final firstGamePgn = _extractFirstGame(trimmed);

    // ── Headers ───────────────────────────────────────────────
    final headers = <String, String>{};
    final headerRegex = RegExp(r'\[(\w+)\s+"([^"]*)"\]');
    for (final match in headerRegex.allMatches(firstGamePgn)) {
      headers[match.group(1)!] = match.group(2)!;
    }

    // ── Move text extraction ───────────────────────────────────
    final tokens = _tokenizeMovetext(firstGamePgn);

    // ── Validate by replaying ─────────────────────────────────
    final board = chess_lib.Chess();
    final customFen = headers['FEN'];
    if (customFen != null && customFen.trim().isNotEmpty) {
      final loaded = board.load(customFen.trim());
      if (!loaded) {
        throw FormatException('Invalid start FEN in PGN: "$customFen"');
      }
    }

    final moves = <GameMove>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final ok = board.move(token.san);
      if (!ok) {
        throw FormatException(
          'Invalid move "${token.san}" at line ${token.lineNumber}, ply ${i + 1}',
        );
      }
      final undoMap = board.undo();
      final from = undoMap?['from'] ?? '';
      final to = undoMap?['to'] ?? '';
      final promo = undoMap?['promotion'] != null
          ? undoMap!['promotion'].toString().toLowerCase()
          : '';
      final uci = '$from$to$promo';
      board.move(token.san);

      final isWhite = board.turn == chess_lib.Color.BLACK; // Turn just flipped to opponent
      final moveNumber = board.move_number;

      moves.add(GameMove(
        plyIndex: i,
        moveNumber: moveNumber,
        isWhite: isWhite,
        san: token.san,
        fen: board.fen,
        uci: uci,
      ));
    }

    return ChessGame(
      headers: headers,
      moves: moves,
      rawPgn: firstGamePgn,
    );
  }

  /// Extracts the first game from a multi-game PGN string.
  static String _extractFirstGame(String pgn) {
    final lines = pgn.split('\n');
    final firstGameLines = <String>[];
    bool hasSeenMoves = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[')) {
        if (hasSeenMoves) {
          // A header tag encountered after move text begins indicates game 2
          break;
        }
        firstGameLines.add(line);
      } else {
        if (trimmed.isNotEmpty) {
          hasSeenMoves = true;
        }
        firstGameLines.add(line);
      }
    }
    return firstGameLines.join('\n').trim();
  }

  /// Strips comments with bracket depth counting to support clock comments like {[%clk 0:03:00]}
  /// and multi-line comments.
  static String _removeComments(String text) {
    final buffer = StringBuffer();
    int depth = 0;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        if (depth > 0) depth--;
      } else if (depth == 0) {
        buffer.write(c);
      }
    }
    return buffer.toString();
  }

  /// Strips variations with parentheses depth counting to support arbitrarily nested variations.
  static String _removeVariations(String text) {
    final buffer = StringBuffer();
    int depth = 0;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        if (depth > 0) depth--;
      } else if (depth == 0) {
        buffer.write(c);
      }
    }
    return buffer.toString();
  }

  /// Normalizes castling notation using digit zeros (0-0, 0-0-0) into capital letters (O-O, O-O-O).
  static String _normalizeCastling(String san) {
    if (san.startsWith('0-0-0')) {
      return 'O-O-O${san.substring(5)}';
    }
    if (san.startsWith('0-0')) {
      return 'O-O${san.substring(3)}';
    }
    return san;
  }

  /// Tokenizes the movetext into SAN moves while preserving original 1-based line numbers.
  static List<_ParsedToken> _tokenizeMovetext(String pgn) {
    // Process line-by-line while tracking line numbers
    final lines = pgn.split('\n');
    final rawTokens = <_ParsedToken>[];

    // Filter out header lines first
    final nonHeaderLines = <int, String>{};
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.trim().startsWith('[')) {
        nonHeaderLines[i + 1] = line;
      }
    }

    // Join non-header text and strip comments/variations while keeping line count structure
    final joined = StringBuffer();
    final lineMapping = <int>[]; // Character index to line number

    for (final entry in nonHeaderLines.entries) {
      final lineNum = entry.key;
      final text = entry.value;
      for (int i = 0; i < text.length; i++) {
        joined.write(text[i]);
        lineMapping.add(lineNum);
      }
      joined.write(' ');
      lineMapping.add(lineNum);
    }

    final rawText = joined.toString();
    final withoutComments = _removeComments(rawText);
    final cleanText = _removeVariations(withoutComments);

    // Tokenize
    final whitespaceRegex = RegExp(r'\s+');
    final words = cleanText.split(whitespaceRegex);

    for (final word in words) {
      var token = word.trim();
      if (token.isEmpty) continue;

      // Skip NAG annotations like $1, $14, etc.
      if (token.startsWith(r'$')) continue;

      // Skip game results
      if (token == '1-0' || token == '0-1' || token == '1/2-1/2' || token == '*') {
        continue;
      }

      // Strip leading move numbers such as "1." or "1..." or "14." without stripping move text
      token = token.replaceFirst(RegExp(r'^\d+\.+'), '');
      if (token.isEmpty) continue;

      // Skip dangling results if attached
      if (token == '1-0' || token == '0-1' || token == '1/2-1/2' || token == '*') {
        continue;
      }

      // Strip trailing annotation glyphs like !, ?, !?, ?!
      token = token.replaceAll(RegExp(r'[!?]+$'), '');
      if (token.isEmpty) continue;

      // Normalize 0-0 castling
      token = _normalizeCastling(token);

      // Estimate line number from non-header lines
      int lineNum = 1;
      for (final entry in nonHeaderLines.entries) {
        if (entry.value.contains(token)) {
          lineNum = entry.key;
          break;
        }
      }

      rawTokens.add(_ParsedToken(token, lineNum));
    }

    return rawTokens;
  }

  /// Quick validation – returns null if valid, or an error message.
  static String? validate(String pgn) {
    try {
      parse(pgn);
      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not parse PGN: $e';
    }
  }
}
