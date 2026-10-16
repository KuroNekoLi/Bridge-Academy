/// Original beginner-learning content. No game session or hidden Deal is used.
/// C3 persists progress separately; these public stable IDs are not UI indexes.
class AcademyText {
  const AcademyText(this.zhTw, this.en);

  final String zhTw;
  final String en;

  String localized(bool isEnglish) => isEnglish ? en : zhTw;

  Map<String, dynamic> toJson() => {'zhTw': zhTw, 'en': en};

  factory AcademyText.fromJson(Object? source) {
    final value = _object(source, 'localized text');
    return AcademyText(
      _string(value, 'zhTw'),
      _string(value, 'en'),
    );
  }

  void validate(String field) {
    if (zhTw.trim().isEmpty || en.trim().isEmpty) {
      throw FormatException('$field requires nonempty zh-TW and en');
    }
  }
}

class AcademyOption {
  const AcademyOption({required this.optionId, required this.label});

  final String optionId;
  final AcademyText label;

  Map<String, dynamic> toJson() =>
      {'optionId': optionId, 'label': label.toJson()};

  factory AcademyOption.fromJson(Object? source) {
    final value = _object(source, 'option');
    return AcademyOption(
      optionId: _string(value, 'optionId'),
      label: AcademyText.fromJson(value['label']),
    );
  }
}

class AcademyExplanation {
  const AcademyExplanation({
    required this.correct,
    required this.incorrect,
    required this.ruleReference,
  });

  final AcademyText correct;
  final AcademyText incorrect;

  /// Stable repository authority, not a claim of expert convention approval.
  final String ruleReference;

  Map<String, dynamic> toJson() => {
        'correct': correct.toJson(),
        'incorrect': incorrect.toJson(),
        'ruleReference': ruleReference,
      };

  factory AcademyExplanation.fromJson(Object? source) {
    final value = _object(source, 'explanation');
    return AcademyExplanation(
      correct: AcademyText.fromJson(value['correct']),
      incorrect: AcademyText.fromJson(value['incorrect']),
      ruleReference: _string(value, 'ruleReference'),
    );
  }
}

class AcademyQuestion {
  const AcademyQuestion({
    required this.questionId,
    required this.skillTag,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
  });

  final String questionId;
  final String skillTag;
  final AcademyText prompt;
  final List<AcademyOption> options;
  final String correctOptionId;
  final AcademyExplanation explanation;

  bool isCorrect(String optionId) => optionId == correctOptionId;

  bool hasOption(String optionId) =>
      options.any((option) => option.optionId == optionId);

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'skillTag': skillTag,
        'prompt': prompt.toJson(),
        'options': options.map((option) => option.toJson()).toList(),
        'correctOptionId': correctOptionId,
        'explanation': explanation.toJson(),
      };

  factory AcademyQuestion.fromJson(Object? source) {
    final value = _object(source, 'question');
    return AcademyQuestion(
      questionId: _string(value, 'questionId'),
      skillTag: _string(value, 'skillTag'),
      prompt: AcademyText.fromJson(value['prompt']),
      options: _array(value, 'options').map(AcademyOption.fromJson).toList(),
      correctOptionId: _string(value, 'correctOptionId'),
      explanation: AcademyExplanation.fromJson(value['explanation']),
    );
  }
}

class AcademyLesson {
  const AcademyLesson({
    required this.lessonId,
    required this.schemaVersion,
    required this.skillTag,
    required this.title,
    required this.summary,
    required this.introduction,
    required this.questions,
  });

  final String lessonId;
  final int schemaVersion;
  final String skillTag;
  final AcademyText title;
  final AcademyText summary;
  final AcademyText introduction;
  final List<AcademyQuestion> questions;

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'schemaVersion': schemaVersion,
        'skillTag': skillTag,
        'title': title.toJson(),
        'summary': summary.toJson(),
        'introduction': introduction.toJson(),
        'questions': questions.map((question) => question.toJson()).toList(),
      };

  factory AcademyLesson.fromJson(Object? source) {
    final value = _object(source, 'lesson');
    final version = value['schemaVersion'];
    if (version is! int) {
      throw const FormatException('schemaVersion must be an integer');
    }
    return AcademyLesson(
      lessonId: _string(value, 'lessonId'),
      schemaVersion: version,
      skillTag: _string(value, 'skillTag'),
      title: AcademyText.fromJson(value['title']),
      summary: AcademyText.fromJson(value['summary']),
      introduction: AcademyText.fromJson(value['introduction']),
      questions:
          _array(value, 'questions').map(AcademyQuestion.fromJson).toList(),
    );
  }
}

/// Stable attempt DTO for a future C3 adapter, not persisted by B4 itself.
class AcademyAnswer {
  const AcademyAnswer({
    required this.lessonId,
    required this.questionId,
    required this.skillTag,
    required this.schemaVersion,
    required this.selectedOptionId,
  });

  final String lessonId;
  final String questionId;
  final String skillTag;
  final int schemaVersion;
  final String selectedOptionId;

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'questionId': questionId,
        'skillTag': skillTag,
        'schemaVersion': schemaVersion,
        'selectedOptionId': selectedOptionId,
      };

  factory AcademyAnswer.fromJson(Object? source) {
    final value = _object(source, 'answer');
    if (value['schemaVersion'] is! int) {
      throw const FormatException('Answer requires schemaVersion integer');
    }
    return AcademyAnswer(
      lessonId: _string(value, 'lessonId'),
      questionId: _string(value, 'questionId'),
      skillTag: _string(value, 'skillTag'),
      schemaVersion: value['schemaVersion'] as int,
      selectedOptionId: _string(value, 'selectedOptionId'),
    );
  }
}

class AcademyFeedback {
  const AcademyFeedback({required this.correct, required this.newlyCompleted});
  final bool correct;
  final bool newlyCompleted;
}

/// In-memory, single-route practice only. Wrong submissions never count as
/// completions, nor can repeated correct submissions increase completion.
class AcademyPractice {
  final Set<String> _completed = <String>{};

  bool isCompleted(String questionId) => _completed.contains(questionId);

  int completedCount(AcademyLesson lesson) => lesson.questions
      .where((question) => _completed.contains(question.questionId))
      .length;

  AcademyFeedback submit({
    required AcademyLesson lesson,
    required AcademyQuestion question,
    required AcademyAnswer answer,
  }) {
    if (answer.lessonId != lesson.lessonId ||
        answer.schemaVersion != lesson.schemaVersion ||
        answer.questionId != question.questionId ||
        answer.skillTag != question.skillTag ||
        !lesson.questions.any((q) => q.questionId == question.questionId) ||
        !question.hasOption(answer.selectedOptionId)) {
      throw const FormatException('Stale, mismatched or invalid answer');
    }
    final correct = question.isCorrect(answer.selectedOptionId);
    return AcademyFeedback(
      correct: correct,
      newlyCompleted: correct && _completed.add(question.questionId),
    );
  }
}

abstract final class AcademyValidator {
  static const schemaVersion = 1;

  static void validate(List<AcademyLesson> lessons) {
    if (lessons.isEmpty) {
      throw const FormatException('At least one lesson is required');
    }
    final lessonIds = <String>{};
    final questionIds = <String>{};
    for (final lesson in lessons) {
      if (lesson.schemaVersion != schemaVersion ||
          lesson.lessonId.trim().isEmpty ||
          lesson.skillTag.trim().isEmpty ||
          !lessonIds.add(lesson.lessonId)) {
        throw const FormatException('Invalid version or duplicate lesson ID');
      }
      lesson.title.validate('lesson title');
      lesson.summary.validate('lesson summary');
      lesson.introduction.validate('lesson introduction');
      if (lesson.questions.isEmpty) {
        throw const FormatException('Every lesson needs questions');
      }
      for (final question in lesson.questions) {
        if (question.questionId.trim().isEmpty ||
            question.skillTag.trim().isEmpty ||
            question.skillTag != lesson.skillTag ||
            !questionIds.add(question.questionId)) {
          throw const FormatException('Duplicate question or invalid tag');
        }
        question.prompt.validate('question prompt');
        question.explanation.correct.validate('correct explanation');
        question.explanation.incorrect.validate('incorrect explanation');
        if (question.explanation.ruleReference.trim().isEmpty) {
          throw const FormatException('Answer needs a rule reference');
        }
        if (question.options.length < 2 ||
            !question.hasOption(question.correctOptionId)) {
          throw const FormatException('Missing or invalid correct answer');
        }
        final optionIds = <String>{};
        for (final option in question.options) {
          if (option.optionId.trim().isEmpty ||
              !optionIds.add(option.optionId)) {
            throw const FormatException('Duplicate or empty option ID');
          }
          option.label.validate('option label');
        }
      }
    }
  }
}

Map<String, dynamic> _object(Object? value, String description) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$description must be a JSON object');
  }
  return value;
}

String _string(Map<String, dynamic> value, String key) {
  final input = value[key];
  if (input is! String || input.trim().isEmpty) {
    throw FormatException('$key must be a nonempty string');
  }
  return input;
}

List<dynamic> _array(Map<String, dynamic> value, String key) {
  final input = value[key];
  if (input is! List) throw FormatException('$key must be an array');
  return input;
}
