/// Gemini-generated explanation for a single move.
class MoveExplanation {
  final int moveNumber;
  final String title;
  final String explanation;
  final String betterMove;
  final String lesson;

  const MoveExplanation({
    required this.moveNumber,
    required this.title,
    required this.explanation,
    required this.betterMove,
    required this.lesson,
  });

  factory MoveExplanation.fromJson(Map<String, dynamic> json) {
    return MoveExplanation(
      moveNumber: json['move_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      betterMove: json['better_move'] as String? ?? '',
      lesson: json['lesson'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'move_number': moveNumber,
        'title': title,
        'explanation': explanation,
        'better_move': betterMove,
        'lesson': lesson,
      };
}

/// Gemini-generated overall game review.
class GameReview {
  final String summary;
  final List<String> keyLessons;

  const GameReview({
    required this.summary,
    required this.keyLessons,
  });

  factory GameReview.fromJson(Map<String, dynamic> json) {
    return GameReview(
      summary: json['summary'] as String? ?? '',
      keyLessons: (json['key_lessons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
