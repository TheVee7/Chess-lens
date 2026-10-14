import '../models/game_explanation.dart';
import '../models/move_analysis.dart';

/// Instant, deterministic, offline rule-based chess explanation system.
///
/// Runs entirely client-side without network calls or asynchronous work.
/// Evaluates Stockfish evaluations and heuristics to explain moves and
/// generate game reviews. Never throws.
class RuleBasedExplainer {
  RuleBasedExplainer._();

  static String _phase(int moveNumber) {
    if (moveNumber <= 10) return 'opening';
    if (moveNumber >= 35) return 'endgame';
    return 'middlegame';
  }

  static String _phaseLesson(int moveNumber) {
    if (moveNumber <= 10) {
      return 'In the opening, develop your pieces, fight for the center, and castle early.';
    }
    if (moveNumber >= 35) {
      return 'In the endgame, activate your king and calculate pawn races carefully.';
    }
    return 'Before every move, check what your opponent is threatening.';
  }

  static String _phaseLessonByName(String phase) {
    switch (phase) {
      case 'opening':
        return 'In the opening, develop your pieces, fight for the center, and castle early.';
      case 'endgame':
        return 'In the endgame, activate your king and calculate pawn races carefully.';
      case 'middlegame':
      default:
        return 'Before every move, check what your opponent is threatening.';
    }
  }

  static String _classificationLabel(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.blunder:
        return 'Blunder';
      case MoveClassification.mistake:
        return 'Mistake';
      case MoveClassification.inaccuracy:
        return 'Inaccuracy';
      default:
        return 'Costly move';
    }
  }

  static String _pawns(double cp) => (cp / 100).toStringAsFixed(1);

  /// Explains a single move using deterministic heuristic rules.
  static MoveExplanation explain(MoveAnalysis m) {
    final played = m.san;
    final best = m.bestMoveSan ?? '';
    final hasBest = best.isNotEmpty && best != played;
    final defaultLesson = _phaseLesson(m.moveNumber);
    final loss = _pawns(m.evalLoss);

    // Mover-perspective centipawns
    final before = m.isWhite ? m.evalBefore : -m.evalBefore;
    final after = m.isWhite ? m.evalAfter : -m.evalAfter;

    // Mover-perspective mate (positive = mover is mating, negative = mover is getting mated)
    final int? moverMateBefore = (m.isMateBefore && m.mateBefore != null)
        ? (m.isWhite ? m.mateBefore : -m.mateBefore!)
        : null;
    final int? moverMateAfter = (m.isMateAfter && m.mateAfter != null)
        ? (m.isWhite ? m.mateAfter : -m.mateAfter!)
        : null;

    String title;
    String explanation;
    String lesson;

    // 1. Missed forced mate: moverMateBefore > 0 AND NOT (moverMateAfter > 0)
    if (moverMateBefore != null &&
        moverMateBefore > 0 &&
        !(moverMateAfter != null && moverMateAfter > 0)) {
      title = 'Missed forced mate';
      explanation =
          'You had a forced checkmate in ${moverMateBefore.abs()}, but $played let it slip.';
      lesson =
          'When the enemy king looks exposed, check every check and capture first.';
    }
    // 2. Allowed forced mate: moverMateAfter < 0 AND NOT (moverMateBefore < 0)
    else if (moverMateAfter != null &&
        moverMateAfter < 0 &&
        !(moverMateBefore != null && moverMateBefore < 0)) {
      title = 'Allowed a forced mate';
      explanation =
          '$played walks into a forced checkmate in ${moverMateAfter.abs()}.';
      lesson =
          'Before you move, ask: can my opponent check me, and where does my king go?';
    }
    // 3. Missed checkmate: best contains '#'
    else if (best.contains('#')) {
      title = 'Missed checkmate';
      explanation = '$best was checkmate. $played missed it.';
      lesson = 'Always look at every check before choosing a quiet move.';
    }
    // 4. Missed capture: best contains 'x' AND played does not AND evalLoss >= 80
    else if (best.contains('x') && !played.contains('x') && m.evalLoss >= 80) {
      title = 'Missed a capture';
      explanation =
          '$best won material. $played missed it and cost about $loss pawns.';
      lesson =
          "Before each move, list every capture available, yours and your opponent's.";
    }
    // 5. Missed check: best contains '+' AND played does not AND evalLoss >= 80
    else if (best.contains('+') && !played.contains('+') && m.evalLoss >= 80) {
      title = 'Missed a strong check';
      explanation =
          '$best was a strong checking move. $played gave up about $loss pawns.';
      lesson =
          'Checks force a reply, so always consider them before quiet moves.';
    }
    // 6. Winning position slipped: before >= 150 AND after < 50
    else if (before >= 150 && after < 50) {
      title = 'Winning position slipped';
      explanation =
          'You were about ${_pawns(before)} pawns ahead, but $played brought the game back to roughly equal.';
      lesson =
          'When ahead, keep it simple: trade pieces and avoid unnecessary risks.';
    }
    // 7. Position turned bad: before > -50 AND after <= -150
    else if (before > -50 && after <= -150) {
      title = 'Position turned bad';
      explanation =
          '$played turned a balanced game into a clearly worse one (about $loss pawns lost).';
      lesson = defaultLesson;
    }
    // 8. Harder to defend: before <= -300
    else if (before <= -300) {
      title = 'Harder to defend';
      explanation =
          'You were already under pressure, and $played made it about $loss pawns worse.';
      lesson =
          'When behind, look for moves that set problems and avoid simple trades.';
    }
    // 9. Generic
    else {
      title = _classificationLabel(m.classification);
      if (m.plyIndex.isEven) {
        explanation = '$played lost about $loss pawns of advantage.';
      } else {
        explanation =
            'With $played you gave up roughly $loss pawns compared with the best move.';
      }
      lesson = defaultLesson;
    }

    String betterMove = '';
    if (hasBest) {
      final buffer = StringBuffer('The engine preferred $best.');
      if (m.pv.length > 1) {
        buffer.write(' A likely continuation: ${m.pv.take(4).join(' ')}.');
      }
      betterMove = buffer.toString();
    }

    return MoveExplanation(
      moveNumber: m.moveNumber,
      title: title,
      explanation: explanation,
      betterMove: betterMove,
      lesson: lesson,
    );
  }

  /// Generates an offline game review summarizing bad moves across phases.
  static GameReview review(List<MoveAnalysis> all) {
    int blunderCount = 0;
    int mistakeCount = 0;
    int inaccuracyCount = 0;

    MoveAnalysis? worstMove;

    final phaseCounts = <String, int>{
      'opening': 0,
      'middlegame': 0,
      'endgame': 0,
    };

    final titleCounts = <String, int>{};
    final titleLessons = <String, String>{};

    for (final m in all) {
      if (m.classification != MoveClassification.blunder &&
          m.classification != MoveClassification.mistake &&
          m.classification != MoveClassification.inaccuracy) {
        continue;
      }

      if (m.classification == MoveClassification.blunder) blunderCount++;
      if (m.classification == MoveClassification.mistake) mistakeCount++;
      if (m.classification == MoveClassification.inaccuracy) inaccuracyCount++;

      if (worstMove == null || m.evalLoss > worstMove.evalLoss) {
        worstMove = m;
      }

      final phase = _phase(m.moveNumber);
      phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;

      final exp = explain(m);
      titleCounts[exp.title] = (titleCounts[exp.title] ?? 0) + 1;
      titleLessons[exp.title] = exp.lesson;
    }

    final totalBad = blunderCount + mistakeCount + inaccuracyCount;
    if (totalBad == 0) {
      return const GameReview(
        summary: 'No blunders, mistakes or inaccuracies found. Clean game!',
        keyLessons: ['Keep playing solid, purposeful moves.'],
      );
    }

    final parts = <String>[];
    if (blunderCount > 0) {
      parts.add(blunderCount == 1 ? '1 blunder' : '$blunderCount blunders');
    }
    if (mistakeCount > 0) {
      parts.add(mistakeCount == 1 ? '1 mistake' : '$mistakeCount mistakes');
    }
    if (inaccuracyCount > 0) {
      parts.add(inaccuracyCount == 1
          ? '1 inaccuracy'
          : '$inaccuracyCount inaccuracies');
    }

    // Determine phase with highest count
    String worstPhase = 'middlegame';
    int maxPhaseCount = -1;
    for (final entry in phaseCounts.entries) {
      if (entry.value > maxPhaseCount) {
        maxPhaseCount = entry.value;
        worstPhase = entry.key;
      }
    }

    final worst = worstMove!;
    final worstMoveStr =
        "${worst.moveNumber}${worst.isWhite ? '.' : '...'} ${worst.san}";
    final worstLoss = _pawns(worst.evalLoss);

    final summary =
        'Stockfish found ${parts.join(', ')}, mostly in the $worstPhase. '
        'The biggest swing was $worstMoveStr, which cost about $worstLoss pawns.';

    // Key lessons: top 2 titles deduplicated, then phaseLesson of worstPhase, max 3
    final sortedTitles = titleCounts.keys.toList()
      ..sort((a, b) => titleCounts[b]!.compareTo(titleCounts[a]!));

    final keyLessons = <String>[];
    for (final title in sortedTitles) {
      final lesson = titleLessons[title];
      if (lesson != null && !keyLessons.contains(lesson)) {
        keyLessons.add(lesson);
        if (keyLessons.length == 2) break;
      }
    }

    final phaseLesson = _phaseLessonByName(worstPhase);
    if (!keyLessons.contains(phaseLesson)) {
      keyLessons.add(phaseLesson);
    }

    return GameReview(
      summary: summary,
      keyLessons: keyLessons.take(3).toList(),
    );
  }
}
