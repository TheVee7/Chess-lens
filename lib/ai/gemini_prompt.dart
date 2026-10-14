import '../models/move_analysis.dart';

/// Builds the system prompt and per-move prompts for Gemini.
class GeminiPrompt {
  GeminiPrompt._();

  static const String systemPrompt = '''
You are a chess coach analysing a game for a student.
You receive Stockfish analysis data and must explain the position in simple, 
human-friendly language.

Rules:
- Never recalculate the engine evaluation. Trust the numbers provided.
- Focus on explaining WHY the move was good or bad.
- Keep explanations concise (2-4 sentences max).
- Always respond in valid JSON matching the requested schema.
- Do not use chess notation jargon without explaining it.
''';

  static String _sanitize(String s) {
    return s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', ' ');
  }

  /// Prompt for a single move explanation.
  static String moveExplanation(MoveAnalysis move) {
    final cleanSan = _sanitize(move.san);
    final cleanBestMove = _sanitize(move.bestMoveSan ?? 'N/A');
    final cleanFen = _sanitize(move.fenBefore);
    final cleanPv = move.pv.map((m) => '"${_sanitize(m)}"').toList();

    return '''
Analyse this chess move and respond in JSON.

Position data:
{
  "move_number": ${move.moveNumber},
  "side": "${move.isWhite ? 'White' : 'Black'}",
  "played_move": "$cleanSan",
  "best_move": "$cleanBestMove",
  "classification": "${move.classification.name}",
  "evaluation_before": ${(move.evalBefore / 100).toStringAsFixed(2)},
  "evaluation_after": ${(move.evalAfter / 100).toStringAsFixed(2)},
  "evaluation_loss": ${(move.evalLoss / 100).toStringAsFixed(2)},
  "principal_variation": $cleanPv,
  "fen": "$cleanFen"
}

Respond with ONLY this JSON (no markdown, no code fences):
{
  "move_number": <int>,
  "title": "<classification label, e.g. Mistake, Blunder, Inaccuracy>",
  "explanation": "<why was this move problematic or good? 2-3 sentences>",
  "better_move": "<what the better move does and why, 1-2 sentences>",
  "lesson": "<one concrete lesson the player can take away, 1 sentence>"
}
''';
  }

  /// Prompt for a batch of move explanations, optionally including a game review.
  static String movesBatch(List<MoveAnalysis> batch,
      {List<MoveAnalysis>? reviewMoves}) {
    final movesJson = batch.map((m) {
      final cleanSan = _sanitize(m.san);
      final cleanBestMove = _sanitize(m.bestMoveSan ?? 'N/A');
      final cleanFen = _sanitize(m.fenBefore);
      final pvCapped = m.pv.take(5).map((p) => '"${_sanitize(p)}"').toList();

      return '  {\n'
          '    "ply_index": ${m.plyIndex},\n'
          '    "move_number": ${m.moveNumber},\n'
          '    "side": "${m.isWhite ? 'White' : 'Black'}",\n'
          '    "played_move": "$cleanSan",\n'
          '    "best_move": "$cleanBestMove",\n'
          '    "classification": "${m.classification.name}",\n'
          '    "evaluation_before": ${(m.evalBefore / 100).toStringAsFixed(2)},\n'
          '    "evaluation_after": ${(m.evalAfter / 100).toStringAsFixed(2)},\n'
          '    "evaluation_loss": ${(m.evalLoss / 100).toStringAsFixed(2)},\n'
          '    "principal_variation": $pvCapped,\n'
          '    "fen": "$cleanFen"\n'
          '  }';
    }).join(',\n');

    final reviewSection = StringBuffer();
    if (reviewMoves != null) {
      reviewSection.writeln();
      reviewSection.writeln('Also generate an overall game review based on these critical moments:');
      if (reviewMoves.isEmpty) {
        reviewSection.writeln('No major blunders or mistakes detected. Solid overall play.');
      } else {
        for (final m in reviewMoves) {
          final cleanSan = _sanitize(m.san);
          reviewSection.writeln(
              '  ${m.moveNumber}${m.isWhite ? '.' : '...'} $cleanSan '
              '(${m.classification.name}, loss: ${(m.evalLoss / 100).toStringAsFixed(1)})');
        }
      }
      reviewSection.writeln();
      reviewSection.writeln('Include a "review" key in the JSON with: "summary" (3-4 sentences) and "key_lessons" (exactly 3 items).');
    }

    final reviewSchema = reviewMoves != null
        ? ',\n  "review": {\n    "summary": "<3-4 sentence overview>",\n    "key_lessons": ["<lesson 1>", "<lesson 2>", "<lesson 3>"]\n  }'
        : '';

    return '''
Analyze the following chess moves based on Stockfish engine responses and return human-friendly explanations.
Explain what happened in natural human words, suggest better alternatives, and respond strictly in predefined JSON.
Return exactly one entry per input move, keyed by ply_index.

Moves:
[
$movesJson
]
$reviewSection
Respond with ONLY this predefined JSON (no markdown, no code fences):
{
  "moves": [
    {
      "ply_index": <int copied from input>,
      "title": "<classification label, e.g. Blunder, Mistake, Inaccuracy, Good>",
      "explanation": "<explain in plain human words why this move was problematic or good, 2-3 sentences>",
      "better_move": "<human suggestion: what the better move accomplishes and why, 1-2 sentences>",
      "lesson": "<one concrete takeaway lesson in human words, 1 sentence>"
    }
  ]$reviewSchema
}
''';
  }

  /// Prompt for the overall game review.
  static String gameReview(List<MoveAnalysis> importantMoves) {
    final moveSummaries = importantMoves.isEmpty
        ? 'No major blunders or mistakes detected in this game. Solid overall play.'
        : importantMoves.map((m) {
            final cleanSan = _sanitize(m.san);
            return '  Move ${m.moveNumber}${m.isWhite ? '' : '...'}$cleanSan '
                '(${m.classification.name}, loss: ${(m.evalLoss / 100).toStringAsFixed(1)})';
          }).join('\n');

    return '''
Generate an overall game review based on these critical moments:

$moveSummaries

Respond with ONLY this JSON (no markdown, no code fences):
{
  "summary": "<3-4 sentence overview of the game, focusing on turning points>",
  "key_lessons": [
    "<lesson 1>",
    "<lesson 2>",
    "<lesson 3>"
  ]
}
''';
  }
}
