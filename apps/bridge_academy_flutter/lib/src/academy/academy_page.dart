import 'package:flutter/material.dart';

import 'academy_catalog.dart';
import 'academy_models.dart';
import '../learning_progress/learner_progress.dart';
import '../learning_progress/learner_store.dart';
import '../learning_progress/learning_recommendations.dart';
import 'package:flutter/foundation.dart';

/// B4 reads authored questions only, not live BridgeSession/Deal/BEN state.
class AcademyPage extends StatefulWidget {
  const AcademyPage({super.key, required this.isEnglish, this.learnerStore});
  final LearnerStore? learnerStore;
  final bool isEnglish;

  @override
  State<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends State<AcademyPage> {
  AcademyPractice _practice = AcademyPractice();
  late bool _english;
  AcademyLesson? _lesson;
  int _index = 0;
  String? _selected;
  AcademyFeedback? _feedback;
  late final LearnerStore _store;
  LearnerProgress _history = LearnerProgress();
  bool _enabled = false;
  bool _savingEnabled = false;
  bool _persisting = false;
  bool _storageError = false;
  bool _loading = true;
  bool _dashboard = false;
  int _sequence = 0;

  @override
  void initState() {
    super.initState();
    _english = widget.isEnglish;
    _store = widget.learnerStore ??
      (kIsWeb ? EncryptedLearnerStore.browser() : EncryptedLearnerStore.native());
    _restore();
  }

  String _t(String id) => _ui[id]!.localized(_english);
  Future<void> _restore() async {
    try {
      final value = await _store.read();
      if (!mounted) return;
      setState(() {
        _enabled = value != null;
        _savingEnabled = value?.savingEnabled ?? false;
        _history = value ?? LearnerProgress();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _storageError = true; _loading = false; });
    }
  }
  Future<void> _enable() async {
    if (_persisting || _storageError || _loading) return;
    setState(() => _persisting = true);
    try {
      await _store.write(_history);
      if (mounted) setState(() { _enabled = true; _savingEnabled = true; });
    } catch (_) {
      if (mounted) setState(() { _storageError = true; _loading = false; });
    } finally {
      if (mounted) setState(() => _persisting = false);
    }
  }
  Future<void> _delete() async {
    final yes = await showDialog<bool>(context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('deleteHistory')),
        content: Text(_t('deleteWarning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text(_t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: Text(_t('deleteHistory'))),
        ],
      ));
    if (yes != true || _persisting) return;
    setState(() => _persisting = true);
    try {
      await _store.clear();
      if (mounted) {
        setState(() {
        _enabled = false;
        _savingEnabled = false;
        _history = LearnerProgress();
        _practice = AcademyPractice();
        _storageError = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _storageError = true; _loading = false; });
    } finally {
      if (mounted) setState(() => _persisting = false);
    }
  }
  Future<void> _setSavingEnabled(bool desired) async {
    if (!_enabled || _persisting || _storageError) return;
    final updated = LearnerProgress(_history.attempts)
      ..savingEnabled = desired;
    setState(() => _persisting = true);
    try {
      await _store.write(updated);
      if (mounted) {
        setState(() {
          _history = updated;
          _savingEnabled = desired;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _storageError = true);
    } finally {
      if (mounted) setState(() => _persisting = false);
    }
  }

  Future<void> _record(AcademyAnswer answer, AcademyFeedback result) async {
    if (!_enabled || !_savingEnabled || _persisting || _storageError) return;
    late final LearnerProgress updated;
    try {
      updated = LearnerProgress(_history.attempts);
      updated.record(LearnerAttempt(
        id: '${DateTime.now().toUtc().microsecondsSinceEpoch}-${_sequence++}',
        timestampUtc: DateTime.now().toUtc(),
        answer: answer,
        correct: result.correct,
      ));
    } catch (_) {
      if (mounted) setState(() => _storageError = true);
      return;
    }
    setState(() => _persisting = true);
    try {
      await _store.write(updated);
      if (mounted) setState(() => _history = updated);
    } catch (_) {
      if (mounted) setState(() { _storageError = true; _loading = false; });
    } finally {
      if (mounted) setState(() => _persisting = false);
    }
  }
  Widget _progressView() {
    final lessons = AcademyCatalog.validated();
    final questionCount = lessons.fold<int>(0, (n, l) => n + l.questions.length);
    return ListView(
      key: const Key('c3_dashboard'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(_t('progressTitle'), style: Theme.of(context).textTheme.titleLarge),
        Text('${_history.completedCount} / $questionCount ${_t('completedQuestions')}'),
        Text('${_t('attempts')}: ${_history.total}'),
        Text('${_t('accuracy')}: ${_history.accuracy == null ? _t('noData') : '${(_history.accuracy! * 100).round()}%'}'),
        for (final tag in lessons.map((l) => l.skillTag).toSet())
          ListTile(
            title: Text(tag),
            subtitle: Text(_history.skill(tag).accuracy == null
              ? _t('noData')
              : '${(_history.skill(tag).accuracy! * 100).round()}%'),
            trailing: Text('${_history.skill(tag).correct}/${_history.skill(tag).total}'),
          ),
        Text(_t('recentAttempts')),
        for (final a in _history.attempts.reversed.take(8))
          ListTile(title: Text(a.answer.questionId),
            subtitle: Text(a.timestampUtc.toIso8601String()),
            trailing: Icon(a.correct ? Icons.check_circle : Icons.cancel)),
        OutlinedButton(
          key: const Key('c3_toggle_saving'),
          onPressed: _persisting ? null
            : () => _setSavingEnabled(!_savingEnabled),
          child: Text(_t(_savingEnabled ? 'pauseHistory' : 'resumeHistory'))),
        OutlinedButton(
          key: const Key('c3_delete'),
          onPressed: _persisting ? null : _delete,
          child: Text(_t('deleteHistory'))),
        TextButton(
          key: const Key('c3_back'),
          onPressed: () => setState(() => _dashboard = false),
          child: Text(_t('allLessons'))),
      ],
    );
  }

  void _open(AcademyLesson lesson, {String? questionId}) => setState(() {
        _lesson = lesson;
        final i = lesson.questions.indexWhere((q) => q.questionId == questionId);
        _index = i < 0 ? 0 : i;
        _selected = null;
        _feedback = null;
      });

  void _backToCatalog() => setState(() {
        _lesson = null;
        _selected = null;
        _feedback = null;
      });

  void _submit(AcademyQuestion question) {
    if (_feedback != null || _selected == null || _lesson == null ||
        _persisting || _loading) {
      return;
    }
    final lesson = _lesson!;
    final result = _practice.submit(
      lesson: lesson,
      question: question,
      answer: AcademyAnswer(
        lessonId: lesson.lessonId,
        questionId: question.questionId,
        skillTag: question.skillTag,
        schemaVersion: lesson.schemaVersion,
        selectedOptionId: _selected!,
      ),
    );
    setState(() => _feedback = result);
    _record(AcademyAnswer(
      lessonId: lesson.lessonId, questionId: question.questionId,
      skillTag: question.skillTag, schemaVersion: lesson.schemaVersion,
      selectedOptionId: _selected!,
    ), result);
  }

  void _advance() {
    if (_feedback?.correct != true) return;
    setState(() {
      _index++;
      _feedback = null;
      _selected = null;
    });
  }

  void _retry() {
    if (_feedback?.correct != false) return;
    setState(() {
      _feedback = null;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _lesson?.title.localized(_english) ?? _t('title');
    return Scaffold(
      key: const Key('academy_page'),
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          key: const Key('academy_back'),
          tooltip: _lesson == null ? _t('exit') : _t('allLessons'),
          onPressed: _lesson == null
              ? () => Navigator.of(context).pop()
              : _backToCatalog,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            key: const Key('academy_toggle_locale'),
            tooltip: _t('language'),
            onPressed: () => setState(() => _english = !_english),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _dashboard ? _progressView() :
            _lesson == null ? _catalog() : _lessonFlow(_lesson!),
        ),
      ),
    );
  }

  Widget _recommendations(List<AcademyLesson> lessons) {
    final ranked = LearningRecommendationEngine.recommend(
      lessons: lessons, progress: _history,
      nowUtc: DateTime.now().toUtc(), hasConsent: _enabled,
    );
    return Column(
      key: const Key('c3_2_recommendations'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(_t('recTitle'), style: Theme.of(context).textTheme.titleLarge),
        Text(_t(_savingEnabled ? 'recDisclosure' : 'recPaused')),
        for (final item in ranked)
          Card(
            child: ListTile(
              key: Key('c3_2_recommend_${item.lesson.lessonId}'),
              title: Text(item.lesson.title.localized(_english)),
              subtitle: Text(
                '${_t(switch (item.reason) {
                  RecommendationReason.lowAccuracy => 'recLow',
                  RecommendationReason.recentMistake => 'recRecent',
                  RecommendationReason.notStarted => 'recNew',
                  RecommendationReason.unfinished => 'recIncomplete',
                  RecommendationReason.review => 'recReview',
                })} · ${_t('recSample')}: ${item.correct}/${item.attempts}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _persisting ? null : () =>
                _open(item.lesson, questionId: item.questionId),
            ),
          ),
        const Divider(),
      ],
    );
  }

  Widget _catalog() {
    return ListView(
      key: const Key('academy_lesson_list'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(_t('welcome'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(_t('scope')),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator(key: Key('c3_loading'))),
        if (_storageError) ...[
          Text(_t('storageError'), key: const Key('c3_storage_error')),
          OutlinedButton(key: const Key('c3_clear_invalid'),
            onPressed: _persisting ? null : _delete,
            child: Text(_t('deleteHistory'))),
        ],
        if (!_enabled && !_storageError && !_loading)
          FilledButton.tonal(
            key: const Key('c3_enable'),
            onPressed: _persisting ? null : _enable,
            child: Text(_t('enableHistory'))),
        if (_enabled)
          OutlinedButton.icon(
            key: const Key('c3_show_progress'),
            onPressed: () => setState(() => _dashboard = true),
            icon: const Icon(Icons.bar_chart),
            label: Text(_t('progressTitle'))),
        if (_enabled && !_storageError && !_loading)
          _recommendations(AcademyCatalog.validated()),
        for (final lesson in AcademyCatalog.validated())
          Card(
            key: Key('academy_lesson_${lesson.lessonId}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(lesson.title.localized(_english),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(lesson.summary.localized(_english)),
                  const SizedBox(height: 8),
                  Text(
                    '${_enabled ? lesson.questions.where((q) => _history.isCompleted(q.questionId)).length : _practice.completedCount(lesson)} / ${lesson.questions.length} ${_t('completedQuestions')}',
                    key: Key('academy_progress_${lesson.lessonId}'),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonal(
                      key: Key('academy_open_${lesson.lessonId}'),
                      onPressed: () => _open(lesson),
                      child: Text(_t('startLesson')),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _lessonFlow(AcademyLesson lesson) {
    if (_index >= lesson.questions.length) return _completion(lesson);
    final question = lesson.questions[_index];
    return ListView(
      key: const Key('academy_question_list'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(lesson.introduction.localized(_english),
            key: const Key('academy_introduction')),
        const SizedBox(height: 12),
        Text(
          '${_t('question')} ${_index + 1} / ${lesson.questions.length}',
          key: const Key('academy_question_progress'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(question.prompt.localized(_english),
                    key: Key('academy_question_${question.questionId}'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                for (final option in question.options) ...[
                  OutlinedButton(
                    key: Key('academy_option_${option.optionId}'),
                    onPressed: _feedback == null
                        ? () => setState(() => _selected = option.optionId)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      backgroundColor: _selected == option.optionId
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selected == option.optionId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(option.label.localized(_english))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_feedback == null)
                  FilledButton(
                    key: const Key('academy_submit'),
                    onPressed: _selected == null ? null : () => _submit(question),
                    child: Text(_t('submit')),
                  ),
                if (_storageError)
                  Text(_t('storageError'), key: const Key('c3_answer_storage_error')),
                if (_feedback case final result?) ...[
                  Text(
                    _t(result.correct ? 'correct' : 'incorrect'),
                    key: Key(result.correct
                        ? 'academy_correct' : 'academy_incorrect'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(result.correct
                      ? question.explanation.correct.localized(_english)
                      : question.explanation.incorrect.localized(_english),
                      key: const Key('academy_explanation')),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${_t('ruleReference')}: ${question.explanation.ruleReference}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: Key(result.correct
                        ? 'academy_next' : 'academy_retry'),
                    onPressed: result.correct ? _advance : _retry,
                    child: Text(_t(result.correct
                        ? 'nextQuestion' : 'tryAgain')),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('academy_all_lessons'),
          onPressed: _backToCatalog,
          icon: const Icon(Icons.menu_book),
          label: Text(_t('allLessons')),
        ),
      ],
    );
  }

  Widget _completion(AcademyLesson lesson) {
    return ListView(
      key: const Key('academy_completion'),
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_t('finished'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '${_enabled ? lesson.questions.where((q) => _history.isCompleted(q.questionId)).length : _practice.completedCount(lesson)} / ${lesson.questions.length} ${_t('completedQuestions')}',
                  key: const Key('academy_completed_count'),
                ),
                const SizedBox(height: 12),
                Text(_t('sessionOnly')),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('academy_to_catalog'),
                  onPressed: _backToCatalog,
                  child: Text(_t('allLessons')),
                ),
                OutlinedButton(
                  key: const Key('academy_repeat_lesson'),
                  onPressed: () => _open(lesson),
                  child: Text(_t('repeatLesson')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const Map<String, AcademyText> _ui = {
    'title': AcademyText('橋牌學院｜入門課程', 'Bridge Academy | Beginner lessons'),
    'welcome': AcademyText('選擇你的第一堂課', 'Choose your first lesson'),
    'scope': AcademyText(
      '原創規則練習；預設不儲存。只有主動同意後才會加密保留學習紀錄。',
      'Original rules quizzes. Saving is off by default; opt in to keep encrypted progress.',
    ),
    'startLesson': AcademyText('開始學習', 'Start lesson'),
    'question': AcademyText('第', 'Question'),
    'completedQuestions': AcademyText('題完成', 'questions completed'),
    'submit': AcademyText('提交答案', 'Submit answer'),
    'correct': AcademyText('答對了！', 'Correct!'),
    'incorrect': AcademyText('尚未答對', 'Not quite'),
    'ruleReference': AcademyText('規則依據', 'Rule reference'),
    'nextQuestion': AcademyText('下一題', 'Next question'),
    'tryAgain': AcademyText('再試一次', 'Try again'),
    'finished': AcademyText('本堂課完成', 'Lesson complete'),
    'repeatLesson': AcademyText('重做本堂課', 'Repeat lesson'),
    'allLessons': AcademyText('回課程列表', 'Back to lessons'),
    'exit': AcademyText('返回牌桌', 'Back to bridge table'),
    'language': AcademyText('切換為英文', 'Switch to Chinese'),
    'enableHistory': AcademyText('同意加密保存學習紀錄', 'Enable encrypted learning history'),
    'progressTitle': AcademyText('學習進度', 'Learning progress'),
    'attempts': AcademyText('答題次數', 'Attempts'),
    'accuracy': AcademyText('答題正確率', 'Accuracy'),
    'noData': AcademyText('尚無資料', 'No data'),
    'recentAttempts': AcademyText('最近練習', 'Recent attempts'),
    'recTitle': AcademyText('推薦下一堂練習', 'Recommended next lessons'),
    'recDisclosure': AcademyText(
      '依同意保留的本機答題紀錄排序；規則式推薦，不代表專業 AI 判定。',
      'Ranked from your opted-in local history; rules, not an AI diagnosis.'),
    'recPaused': AcademyText(
      '已暫停保存；僅用先前保留的答題紀錄，不記錄新作答。',
      'Saving is paused. Only previously kept local attempts are used.'),
    'recLow': AcademyText('至少三次作答且正確率偏低', 'Low accuracy across at least three attempts'),
    'recRecent': AcademyText('最近 14 天仍有未修正的錯題', 'Uncorrected wrong answer in the past 14 days'),
    'recNew': AcademyText('尚未開始的課程', 'Not started yet'),
    'recIncomplete': AcademyText('繼續未完成的課程', 'Continue an incomplete lesson'),
    'recReview': AcademyText('已完成，適合複習', 'Completed, available to review'),
    'recSample': AcademyText('答對／總作答', 'Correct / attempts'),
    'pauseHistory': AcademyText('暫停保存（保留現有紀錄）', 'Pause saving (keep history)'),
    'resumeHistory': AcademyText('繼續保存答題紀錄', 'Resume saving attempts'),
    'deleteHistory': AcademyText('清除所有學習紀錄', 'Delete all learning history'),
    'deleteWarning': AcademyText('所有本機紀錄將刪除且停止保存，無法復原。', 'All local history will be deleted and saving disabled. This cannot be undone.'),
    'cancel': AcademyText('取消', 'Cancel'),
    'storageError': AcademyText('讀寫加密資料失敗，舊資料未被清除。', 'Encrypted history unavailable; old data was not cleared.'),
    'sessionOnly': AcademyText(
      '未啟用保存時，關閉畫面後不會保留進度。',
      'Without opting in, progress resets when this page closes.',
    ),
  };
}
