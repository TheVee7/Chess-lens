import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_game.dart';

/// Parses PGN text into a [ChessGame] model.
class PgnParser {
  PgnParser._();

  /// Parse a raw PGN string. Throws [FormatException] on invalid input.
  static ChessGame parse(String pgn) {
    final trimmed = pgn.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('PGN is empty');
    }

    // ── Headers ───────────────────────────────────────────────
    final headers = <String, String>{};
    final headerRegex = RegExp(r'\[(\w+)\s+"([^"]*)"\]');
    for (final match in headerRegex.allMatches(trimmed)) {
      headers[match.group(1)!] = match.group(2)!;
    }

    // ── Move text ─────────────────────────────────────────────
    // Remove headers, comments, NAGs, variations, and result markers.
    String movetext = trimmed.replaceAll(headerRegex, '').trim();
    movetext = movetext.replaceAll(RegExp(r'\{[^}]*\}'), ''); // comments
    movetext = movetext.replaceAll(RegExp(r'\([^)]*\)'), ''); // variations
    movetext = movetext.replaceAll(RegExp(r'\$\d+'), '');     // NAGs
    movetext = movetext.replaceAll(RegExp(r'(1-0|0-1|1/2-1/2|\*)'), '');
    movetext = movetext.replaceAll(RegExp(r'\d+\.\.\.'), ' '); // Black notation "1..."
    movetext = movetext.replaceAll(RegExp(r'\d+\.'), ' ');     // move numbers
    movetext = movetext.replaceAll(RegExp(r'\s+'), ' ').trim();

    final sanList =
        movetext.split(' ').where((s) => s.isNotEmpty).toList();

    if (sanList.isEmpty) {
      throw const FormatException('No moves found in PGN');
    }

    // ── Validate by replaying ─────────────────────────────────
    final board = chess_lib.Chess();
    final moves = <GameMove>[];

    for (int i = 0; i < sanList.length; i++) {
      final san = sanList[i];
      final ok = board.move(san);
      if (!ok) {
        throw FormatException(
          'Invalid move "$san" at ply ${i + 1}',
        );
      }
      final undoMap = board.undo();
      final from = undoMap?['from'] ?? '';
      final to = undoMap?['to'] ?? '';
      final promo = undoMap?['promotion'] != null ? undoMap!['promotion'].toString().toLowerCase() : '';
      final uci = '$from$to$promo';
      board.move(san);

      final moveNumber = (i ~/ 2) + 1;
      moves.add(GameMove(
        plyIndex: i,
        moveNumber: moveNumber,
        isWhite: i.isEven,
        san: san,
        fen: board.fen,
        uci: uci,
      ));
    }

    return ChessGame(
      headers: headers,
      moves: moves,
      rawPgn: trimmed,
    );
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
