import '../academy/academy_models.dart';

final class LearnerAttempt {
  const LearnerAttempt({required this.id, required this.timestampUtc,
    required this.answer, required this.correct});
  final String id;
  final DateTime timestampUtc;
  final AcademyAnswer answer;
  final bool correct;
  Map<String, dynamic> toJson() => {
    'id': id, 'utc': timestampUtc.toUtc().toIso8601String(),
    'answer': answer.toJson(), 'correct': correct,
  };
  factory LearnerAttempt.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> || raw.length != 4 ||
        raw['id'] is! String || raw['utc'] is! String ||
        raw['correct'] is! bool || raw['answer'] is! Map) {
      throw const FormatException('Invalid learner attempt');
    }
    final time = DateTime.tryParse(raw['utc'] as String);
    if (time == null || !time.isUtc || (raw['id'] as String).isEmpty) {
      throw const FormatException('Invalid attempt timestamp or id');
    }
    final answer = AcademyAnswer.fromJson(raw['answer']);
    if (answer.schemaVersion != 1 || answer.lessonId.isEmpty ||
        answer.questionId.isEmpty || answer.skillTag.isEmpty ||
        answer.selectedOptionId.isEmpty) {
      throw const FormatException('Unsupported academy answer');
    }
    return LearnerAttempt(id: raw['id'] as String, timestampUtc: time,
      answer: answer, correct: raw['correct'] as bool);
  }
}

final class LearnerProgress {
  LearnerProgress([Iterable<LearnerAttempt> items = const []]) {
    for (final item in items) {
      if (!record(item)) throw const FormatException('Duplicate attempt');
    }
  }
  static const maxAttempts = 500;
  bool savingEnabled = true;
  final List<LearnerAttempt> _items = [];
  final Set<String> _ids = {};
  final Set<String> _completed = {};
  List<LearnerAttempt> get attempts => List.unmodifiable(_items);
  int get total => _items.length;
  int get correct => _items.where((a) => a.correct).length;
  int get completedCount => _completed.length;
  bool isCompleted(String questionId) => _completed.contains(questionId);
  double? get accuracy => total == 0 ? null : correct / total;
  ({int correct, int total, double? accuracy}) skill(String tag) {
    final matches = _items.where((a) => a.answer.skillTag == tag).toList();
    final wins = matches.where((a) => a.correct).length;
    return (correct: wins, total: matches.length,
      accuracy: matches.isEmpty ? null : wins / matches.length);
  }
  bool record(LearnerAttempt item) {
    if (_ids.contains(item.id)) return false;
    if (_items.length == maxAttempts) throw const FormatException('History full');
    if (item.id.isEmpty || !item.timestampUtc.isUtc ||
        item.answer.schemaVersion != 1 || item.answer.lessonId.isEmpty ||
        item.answer.questionId.isEmpty || item.answer.skillTag.isEmpty ||
        item.answer.selectedOptionId.isEmpty) {
      throw const FormatException('Invalid learner attempt');
    }
    _items.add(item);
    _ids.add(item.id);
    if (item.correct) _completed.add(item.answer.questionId);
    return true;
  }
  Map<String, dynamic> toJson() => {
    'v': 2,
    'savingEnabled': savingEnabled,
    'items': _items.map((a) => a.toJson()).toList(),
  };
  factory LearnerProgress.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> || raw['items'] is! List ||
        (raw['items'] as List).length > maxAttempts) {
      throw const FormatException('Invalid learner history');
    }
    final version = raw['v'];
    if ((version != 1 && version != 2) ||
        (version == 1 && raw.length != 2) ||
        (version == 2 && (raw.length != 3 ||
            raw['savingEnabled'] is! bool))) {
      throw const FormatException('Unknown learner history version');
    }
    return LearnerProgress((raw['items'] as List).map(LearnerAttempt.fromJson))
      ..savingEnabled = version == 1 || raw['savingEnabled'] as bool;
  }
}
