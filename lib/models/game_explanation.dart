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
      moveNumber: _parseInt(json['move_number'] ?? json['moveNumber']) ?? 0,
      title: (json['title'] ?? json['classification'] ?? '').toString(),
      explanation: (json['explanation'] ?? json['reason'] ?? '').toString(),
      betterMove: (json['better_move'] ?? json['betterMove'] ?? '').toString(),
      lesson: (json['lesson'] ?? json['takeaway'] ?? '').toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
    final rawLessons =
        json['key_lessons'] ?? json['keyLessons'] ?? json['lessons'];
    final lessons = <String>[];
    if (rawLessons is List) {
      for (final item in rawLessons) {
        lessons.add(item.toString());
      }
    } else if (rawLessons is String) {
      lessons.add(rawLessons);
    }

    return GameReview(
      summary: (json['summary'] ?? json['overview'] ?? '').toString(),
      keyLessons: lessons,
    );
  }
}
