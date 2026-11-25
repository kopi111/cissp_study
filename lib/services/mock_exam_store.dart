import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mock_exam.dart';
import '../models/study_content.dart';

/// Saves the exam being sat and the scores of finished exams on the phone.
class MockExamStore {
  MockExamStore(this._preferences);

  static const _attemptKey = 'cissp_mock_attempt_v1';
  static const _historyKey = 'cissp_mock_history_v1';

  final SharedPreferences _preferences;

  /// Opens the phone's saved data.
  static Future<MockExamStore> open() async =>
      MockExamStore(await SharedPreferences.getInstance());

  /// The saved exam. Unreadable or out-of-date saves count as no exam at all.
  MockExamAttempt savedAttempt(StudyLibrary library) {
    final saved = _preferences.getString(_attemptKey);
    if (saved == null) return MockExamAttempt.none;
    try {
      final attempt = MockExamAttempt.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      return attempt.questionIds.every(library.hasQuestion) ? attempt : MockExamAttempt.none;
    } on Object catch (error) {
      // Keeps the technical detail in the log, and lets the learner start afresh.
      debugPrint('CISSP Study could not read the saved mock exam: $error');
      return MockExamAttempt.none;
    }
  }

  /// Saves the exam after each answer, so closing the app loses nothing.
  Future<void> saveAttempt(MockExamAttempt attempt) =>
      _preferences.setString(_attemptKey, jsonEncode(attempt.toJson()));

  /// Throws away the exam being sat.
  Future<void> discardAttempt() => _preferences.remove(_attemptKey);

  /// Adds a finished exam to the history and clears it from "in progress".
  Future<void> recordFinished(MockExamResult result, DateTime finishedOn) async {
    final record = MockExamRecord(
      finishedOn: finishedOn,
      correctCount: result.correctCount,
      questionCount: result.questionCount,
    );
    final history = [record, ...pastResults];
    await _preferences.setString(
        _historyKey, jsonEncode(history.map((entry) => entry.toJson()).toList()));
    await discardAttempt();
  }

  /// Finished exams, newest first.
  List<MockExamRecord> get pastResults {
    final saved = _preferences.getString(_historyKey);
    if (saved == null) return const [];
    return (jsonDecode(saved) as List)
        .map((entry) => MockExamRecord.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
