import 'package:flutter_test/flutter_test.dart';
import 'package:chess_lens/chess/pgn_parser.dart';

void main() {
  group('PgnParser', () {
    test('parses headers and simple moves correctly', () {
      const pgn = '''
[Event "FIDE World Championship"]
[Site "Dubai UAE"]
[Date "2021.12.03"]
[White "Carlsen, Magnus"]
[Black "Nepomniachtchi, Ian"]
[Result "1-0"]

1. d4 Nf6 2. Nf3 d5 3. g3 1-0
''';
      final game = PgnParser.parse(pgn);
      expect(game.white, 'Carlsen, Magnus');
      expect(game.black, 'Nepomniachtchi, Ian');
      expect(game.event, 'FIDE World Championship');
      expect(game.result, '1-0');
      expect(game.moves.length, 5);
      expect(game.moves[0].san, 'd4');
      expect(game.moves[0].uci, 'd2d4');
      expect(game.moves[1].san, 'Nf6');
      expect(game.moves[1].uci, 'g8f6');
    });

    test('strips comments including clock annotations', () {
      const pgn = '''
1. e4 {[%clk 1:30:00]} e5 {Best reply [%clk 1:29:45]} 2. Nf3 Nc6 *
''';
      final game = PgnParser.parse(pgn);
      expect(game.moves.length, 4);
      expect(game.moves.map((m) => m.san).toList(), ['e4', 'e5', 'Nf3', 'Nc6']);
    });

    test('strips nested variations cleanly without losing moves', () {
      const pgn = '''
1. e4 (1. d4 d5 (1... Nf6 2. c4)) 1... e5 2. Nf3 Nc6 *
''';
      final game = PgnParser.parse(pgn);
      expect(game.moves.length, 4);
      expect(game.moves.map((m) => m.san).toList(), ['e4', 'e5', 'Nf3', 'Nc6']);
    });

    test('strips NAGs and termination markers', () {
      const pgn = '''
1. e4! \$1 e5? \$2 2. Nf3 \$14 Nc6 1/2-1/2
''';
      final game = PgnParser.parse(pgn);
      expect(game.moves.length, 4);
      expect(game.moves.map((m) => m.san).toList(), ['e4', 'e5', 'Nf3', 'Nc6']);
    });

    test('normalizes numeric 0-0 and 0-0-0 castling', () {
      const pgn = '''
1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. 0-0 Nf6 5. d3 0-0 *
''';
      final game = PgnParser.parse(pgn);
      expect(game.moves[6].san, 'O-O');
      expect(game.moves[6].uci, 'e1g1');
      expect(game.moves[9].san, 'O-O');
      expect(game.moves[9].uci, 'e8g8');
    });

    test('handles custom start position with FEN', () {
      const customPgn = '''
[SetUp "1"]
[FEN "r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"]

4. d3 Bc5 5. O-O O-O *
''';
      final game = PgnParser.parse(customPgn);
      expect(game.startFen, startsWith('r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R'));
      expect(game.moves.length, 4);
      expect(game.moves[0].san, 'd3');
    });

    test('handles multi-game PGN by parsing the first game', () {
      const multiGame = '''
[Event "Game 1"]
[White "Player A"]
[Black "Player B"]

1. e4 e5 1-0

[Event "Game 2"]
[White "Player C"]
[Black "Player D"]

1. d4 d5 0-1
''';
      final game = PgnParser.parse(multiGame);
      expect(game.white, 'Player A');
      expect(game.black, 'Player B');
      expect(game.moves.length, 2);
      expect(game.moves[0].san, 'e4');
      expect(game.moves[1].san, 'e5');
    });

    test('throws FormatException with line and ply for invalid move', () {
      const pgn = '''
[White "Player"]
[Black "Opponent"]

1. e4 e5
2. Ke2 Ke7
3. InvalidMove d5
''';
      expect(
        () => PgnParser.parse(pgn),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Invalid move "InvalidMove"'), contains('ply 5')),
          ),
        ),
      );
    });

    test('throws FormatException on empty input', () {
      expect(() => PgnParser.parse('   '), throwsA(isA<FormatException>()));
    });

    test('handles 0-move game without throwing', () {
      const pgn = '''
[Event "Forfeited Game"]
[White "Player A"]
[Black "Player B"]
[Result "1-0"]

1-0
''';
      final game = PgnParser.parse(pgn);
      expect(game.moves, isEmpty);
      expect(game.result, '1-0');
    });
  });
}
