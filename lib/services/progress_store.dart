import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';
import '../models/study_content.dart';
import 'study_planner.dart';

/// Keeps the learner's progress and saves it on the phone after each change.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._preferences, this.settings);

  static const _storageKey = 'cissp_progress_v1';

  final SharedPreferences _preferences;
  StudySettings settings;
  final Map<String, TopicProgress> topicProgress = {};
  final Map<String, QuizTally> quizTallies = {};
  final Set<String> answeredDomainQuestions = {};
  final Map<String, int> _listeningPositions = {};

  static DateTime get today => StudyPlanner.dayOnly(DateTime.now());

  /// Opens saved progress, or starts a new plan for the 1 March 2027 exam.
  static Future<ProgressStore> open() async {
    final preferences = await SharedPreferences.getInstance();
    final firstRunSettings = StudySettings(
      examDate: DateTime(2027, 3, 1),
      planStart: today,
    );
    final store = ProgressStore(preferences, firstRunSettings);
    store._restoreSavedProgress();
    return store;
  }

  /// Fills this store from what was saved earlier, if anything was.
  void _restoreSavedProgress() {
    final saved = _preferences.getString(_storageKey);
    if (saved == null) return;
    final json = jsonDecode(saved) as Map<String, dynamic>;
    settings = StudySettings.fromJson(json['settings'] as Map<String, dynamic>);
    (json['topics'] as Map<String, dynamic>).forEach((id, value) {
      topicProgress[id] = TopicProgress.fromJson(value as Map<String, dynamic>);
    });
    (json['tallies'] as Map<String, dynamic>).forEach((id, value) {
      quizTallies[id] = QuizTally.fromJson(value as Map<String, dynamic>);
    });
    answeredDomainQuestions.addAll(List<String>.from(json['answered'] as List));
    // Progress saved before whole-domain reading existed has no places yet.
    _listeningPositions.addAll(Map<String, int>.from(json['listening'] as Map? ?? const {}));
  }

  /// Writes everything to the phone and tells the screens to redraw.
  Future<void> _saveAndRefresh() async {
    notifyListeners();
    await _preferences.setString(
      _storageKey,
      jsonEncode({
        'settings': settings.toJson(),
        'topics': topicProgress.map((id, value) => MapEntry(id, value.toJson())),
        'tallies': quizTallies.map((id, value) => MapEntry(id, value.toJson())),
        'answered': answeredDomainQuestions.toList(),
        'listening': _listeningPositions,
      }),
    );
  }

  /// The learner's record for a topic. A new topic gets an empty record.
  TopicProgress progressOf(String topicId) =>
      topicProgress[topicId] ?? const TopicProgress();

  /// Number of topics first covered today.
  int get coveredToday => topicProgress.values
      .where((entry) => entry.coveredOn != null && entry.coveredOn == today)
      .length;

  /// Number of topics studied at least one time.
  int get coveredCount =>
      topicProgress.values.where((entry) => entry.isCovered).length;

  /// Saves one topic's new status.
  Future<void> setStatus(String topicId, TopicStatus status) async {
    _applyStatus(topicId, status);
    await _saveAndRefresh();
  }

  /// Saves the same status for many topics at once.
  Future<void> setStatusForTopics(Iterable<String> topicIds, TopicStatus status) async {
    for (final topicId in topicIds) {
      _applyStatus(topicId, status);
    }
    await _saveAndRefresh();
  }

  /// Updates a topic and keeps its first-covered date once it has one.
  void _applyStatus(String topicId, TopicStatus status) {
    final isStudied = status != TopicStatus.notStarted;
    topicProgress[topicId] = TopicProgress(
      status: status,
      coveredOn: isStudied ? (progressOf(topicId).coveredOn ?? today) : null,
      lastStudiedOn: isStudied ? today : null,
    );
  }

  /// Counts one answered question towards every topic it tests.
  Future<void> recordAnswer(PracticeQuestion question, {required bool wasCorrect}) =>
      recordAnswers([(question, wasCorrect)]);

  /// Counts many answers and saves once, as at the end of a mock exam.
  Future<void> recordAnswers(Iterable<(PracticeQuestion, bool)> answers) async {
    for (final (question, wasCorrect) in answers) {
      _tallyAnswer(question, wasCorrect);
    }
    await _saveAndRefresh();
  }

  /// Adds one answer to the tally of every topic it tests.
  void _tallyAnswer(PracticeQuestion question, bool wasCorrect) {
    for (final topicId in question.testedTopicIds) {
      final tally = quizTallies[topicId] ?? const QuizTally();
      quizTallies[topicId] = tally.withAnswer(wasCorrect: wasCorrect);
    }
    if (question.isDomainQuestion) answeredDomainQuestions.add(question.id);
  }

  /// How many different exam-related questions were done in a domain.
  int answeredCountForDomain(int domainNumber) => answeredDomainQuestions
      .where((id) => id.startsWith('D$domainNumber-'))
      .length;

  /// The part of a domain where whole-domain reading last stopped.
  int listeningPositionOf(int domainNumber) => _listeningPositions['$domainNumber'] ?? 0;

  /// Remembers the part of a domain being read now.
  Future<void> saveListeningPosition(int domainNumber, int partIndex) async {
    _listeningPositions['$domainNumber'] = partIndex;
    await _saveAndRefresh();
  }

  /// Saves changed settings.
  Future<void> updateSettings(StudySettings newSettings) async {
    settings = newSettings;
    await _saveAndRefresh();
  }
}
