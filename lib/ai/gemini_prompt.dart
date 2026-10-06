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

  /// Prompt for a single move explanation.
  static String moveExplanation(MoveAnalysis move) {
    return '''
Analyse this chess move and respond in JSON.

Position data:
{
  "move_number": ${move.moveNumber},
  "side": "${move.isWhite ? 'White' : 'Black'}",
  "played_move": "${move.san}",
  "best_move": "${move.bestMoveSan ?? 'N/A'}",
  "classification": "${move.classification.name}",
  "evaluation_before": ${(move.evalBefore / 100).toStringAsFixed(2)},
  "evaluation_after": ${(move.evalAfter / 100).toStringAsFixed(2)},
  "evaluation_loss": ${(move.evalLoss / 100).toStringAsFixed(2)},
  "principal_variation": ${move.pv.map((s) => '"$s"').toList()},
  "fen": "${move.fenBefore}"
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

  /// Prompt for the overall game review.
  static String gameReview(List<MoveAnalysis> importantMoves) {
    final moveSummaries = importantMoves.map((m) {
      return '  Move ${m.moveNumber}${m.isWhite ? '' : '...'}${m.san} '
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
