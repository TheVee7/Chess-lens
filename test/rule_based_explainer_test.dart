import 'package:flutter_test/flutter_test.dart';
import 'package:chess_lens/ai/rule_based_explainer.dart';
import 'package:chess_lens/models/move_analysis.dart';

MoveAnalysis _createMove({
  int plyIndex = 0,
  int moveNumber = 1,
  bool isWhite = true,
  String san = 'e4',
  double evalBefore = 0,
  double evalAfter = 0,
  bool isMateBefore = false,
  bool isMateAfter = false,
  int? mateBefore,
  int? mateAfter,
  String? bestMoveSan,
  List<String> pv = const [],
  double evalLoss = 0,
  MoveClassification classification = MoveClassification.book,
}) {
  return MoveAnalysis(
    plyIndex: plyIndex,
    moveNumber: moveNumber,
    isWhite: isWhite,
    san: san,
    fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    fenAfter: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
    evalBefore: evalBefore,
    evalAfter: evalAfter,
    isMateBefore: isMateBefore,
    isMateAfter: isMateAfter,
    mateBefore: mateBefore,
    mateAfter: mateAfter,
    bestMoveSan: bestMoveSan,
    pv: pv,
    evalLoss: evalLoss,
    classification: classification,
  );
}

void main() {
  group('RuleBasedExplainer.explain', () {
    test('Rule 1: Missed forced mate (White perspective)', () {
      final move = _createMove(
        isWhite: true,
        san: 'Qe5',
        bestMoveSan: 'Qxf7',
        isMateBefore: true,
        mateBefore: 3,
        isMateAfter: false,
        mateAfter: null,
        evalBefore: 10000,
        evalAfter: 0,
        evalLoss: 10000,
        classification: MoveClassification.blunder,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Missed forced mate');
      expect(exp.explanation,
          'You had a forced checkmate in 3, but Qe5 let it slip.');
      expect(exp.lesson,
          'When the enemy king looks exposed, check every check and capture first.');
    });

    test('Rule 1: Missed forced mate (Black perspective)', () {
      final move = _createMove(
        isWhite: false,
        san: 'Qd4',
        bestMoveSan: 'Qxf2',
        isMateBefore: true,
        mateBefore: -4, // -4 from White's perspective = Black mating in 4
        isMateAfter: false,
        mateAfter: null,
        evalBefore: -10000,
        evalAfter: 0,
        evalLoss: 10000,
        classification: MoveClassification.blunder,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Missed forced mate');
      expect(exp.explanation,
          'You had a forced checkmate in 4, but Qd4 let it slip.');
      expect(exp.lesson,
          'When the enemy king looks exposed, check every check and capture first.');
    });

    test('Rule 2: Allowed forced mate', () {
      final move = _createMove(
        isWhite: true,
        san: 'Kh1',
        bestMoveSan: 'Kf1',
        isMateBefore: false,
        mateBefore: null,
        isMateAfter: true,
        mateAfter: -2, // White is being mated in 2
        evalBefore: 0,
        evalAfter: -10000,
        evalLoss: 10000,
        classification: MoveClassification.blunder,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Allowed a forced mate');
      expect(exp.explanation, 'Kh1 walks into a forced checkmate in 2.');
      expect(exp.lesson,
          'Before you move, ask: can my opponent check me, and where does my king go?');
    });

    test('Rule 3: Missed checkmate', () {
      final move = _createMove(
        san: 'Qe2',
        bestMoveSan: 'Qxf7#',
        evalLoss: 500,
        classification: MoveClassification.blunder,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Missed checkmate');
      expect(exp.explanation, 'Qxf7# was checkmate. Qe2 missed it.');
      expect(exp.lesson,
          'Always look at every check before choosing a quiet move.');
    });

    test('Rule 4: Missed capture', () {
      final move = _createMove(
        san: 'Nf3',
        bestMoveSan: 'Nxe5',
        evalLoss: 150,
        classification: MoveClassification.mistake,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Missed a capture');
      expect(exp.explanation,
          'Nxe5 won material. Nf3 missed it and cost about 1.5 pawns.');
      expect(exp.lesson,
          "Before each move, list every capture available, yours and your opponent's.");
    });

    test('Rule 5: Missed check', () {
      final move = _createMove(
        san: 'Be2',
        bestMoveSan: 'Bb5+',
        evalLoss: 90,
        classification: MoveClassification.mistake,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Missed a strong check');
      expect(exp.explanation,
          'Bb5+ was a strong checking move. Be2 gave up about 0.9 pawns.');
      expect(exp.lesson,
          'Checks force a reply, so always consider them before quiet moves.');
    });

    test('Rule 6: Winning position slipped', () {
      final move = _createMove(
        isWhite: true,
        san: 'O-O',
        bestMoveSan: 'd4',
        evalBefore: 200,
        evalAfter: 20,
        evalLoss: 180,
        classification: MoveClassification.mistake,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Winning position slipped');
      expect(exp.explanation,
          'You were about 2.0 pawns ahead, but O-O brought the game back to roughly equal.');
      expect(exp.lesson,
          'When ahead, keep it simple: trade pieces and avoid unnecessary risks.');
    });

    test('Rule 7: Position turned bad', () {
      final move = _createMove(
        isWhite: true,
        moveNumber: 5,
        san: 'f3',
        bestMoveSan: 'Nf3',
        evalBefore: 0,
        evalAfter: -160,
        evalLoss: 160,
        classification: MoveClassification.blunder,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Position turned bad');
      expect(exp.explanation,
          'f3 turned a balanced game into a clearly worse one (about 1.6 pawns lost).');
      expect(exp.lesson,
          'In the opening, develop your pieces, fight for the center, and castle early.');
    });

    test('Rule 8: Harder to defend', () {
      final move = _createMove(
        isWhite: true,
        moveNumber: 20,
        san: 'Kh8',
        bestMoveSan: 'Kf8',
        evalBefore: -350,
        evalAfter: -450,
        evalLoss: 100,
        classification: MoveClassification.mistake,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.title, 'Harder to defend');
      expect(exp.explanation,
          'You were already under pressure, and Kh8 made it about 1.0 pawns worse.');
      expect(exp.lesson,
          'When behind, look for moves that set problems and avoid simple trades.');
    });

    test('Rule 9: Generic fallback (even and odd plyIndex)', () {
      final moveEven = _createMove(
        plyIndex: 12,
        moveNumber: 7,
        san: 'a3',
        bestMoveSan: 'd4',
        evalBefore: 60,
        evalAfter: 0,
        evalLoss: 60,
        classification: MoveClassification.inaccuracy,
      );

      final expEven = RuleBasedExplainer.explain(moveEven);
      expect(expEven.title, 'Inaccuracy');
      expect(expEven.explanation, 'a3 lost about 0.6 pawns of advantage.');

      final moveOdd = _createMove(
        plyIndex: 13,
        moveNumber: 7,
        san: 'a6',
        bestMoveSan: 'd5',
        evalBefore: 0,
        evalAfter: 60,
        evalLoss: 60,
        classification: MoveClassification.inaccuracy,
      );

      final expOdd = RuleBasedExplainer.explain(moveOdd);
      expect(expOdd.title, 'Inaccuracy');
      expect(expOdd.explanation,
          'With a6 you gave up roughly 0.6 pawns compared with the best move.');
    });

    test('Empty bestMoveSan gives empty betterMove', () {
      final move = _createMove(
        san: 'Nf3',
        bestMoveSan: null,
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.betterMove, '');
    });

    test('bestMoveSan with PV continuation format', () {
      final move = _createMove(
        san: 'Nf3',
        bestMoveSan: 'd4',
        pv: ['d4', 'd5', 'c4', 'e6', 'Nc3'],
      );

      final exp = RuleBasedExplainer.explain(move);
      expect(exp.betterMove,
          'The engine preferred d4. A likely continuation: d4 d5 c4 e6.');
    });
  });

  group('RuleBasedExplainer.review', () {
    test('Zero bad moves', () {
      final moves = [
        _createMove(san: 'e4', classification: MoveClassification.book),
        _createMove(san: 'e5', classification: MoveClassification.best),
        _createMove(san: 'Nf3', classification: MoveClassification.good),
      ];

      final review = RuleBasedExplainer.review(moves);
      expect(review.summary,
          'No blunders, mistakes or inaccuracies found. Clean game!');
      expect(review.keyLessons, ['Keep playing solid, purposeful moves.']);
    });

    test('Mixed counts and pluralisation, at most 3 lessons', () {
      final moves = [
        _createMove(
          moveNumber: 5, // opening
          san: 'f3',
          evalBefore: 0,
          evalAfter: -300,
          evalLoss: 300,
          classification: MoveClassification.blunder,
        ),
        _createMove(
          moveNumber: 6, // opening
          san: 'g4',
          bestMoveSan: 'Nxe5',
          evalLoss: 150,
          classification: MoveClassification.mistake,
        ),
        _createMove(
          moveNumber: 7, // opening
          san: 'h4',
          bestMoveSan: 'Nxd5',
          evalLoss: 120,
          classification: MoveClassification.mistake,
        ),
        _createMove(
          moveNumber: 8, // opening
          san: 'a3',
          bestMoveSan: 'd4',
          evalLoss: 60,
          classification: MoveClassification.inaccuracy,
        ),
      ];

      final review = RuleBasedExplainer.review(moves);
      expect(review.summary,
          contains('1 blunder, 2 mistakes, 1 inaccuracy, mostly in the opening.'));
      expect(review.summary, contains('The biggest swing was 5. f3, which cost about 3.0 pawns.'));
      expect(review.keyLessons.length, lessThanOrEqualTo(3));
    });
  });
}
