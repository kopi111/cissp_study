import 'package:cissp_study/models/progress.dart';
import 'package:cissp_study/services/study_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = StudyPlanner();
  final settings = StudySettings(
    examDate: DateTime(2027, 3, 1),
    planStart: DateTime(2026, 11, 9),
  );

  // A small helper so each test only states what matters to it.
  PaceReport assess(DateTime today, int covered, {int coveredToday = 0}) =>
      planner.assess(
        today: today,
        settings: settings,
        totalTopics: 73,
        coveredTopics: covered,
        coveredToday: coveredToday,
      );

  test('day one is on track with 112 days left and one topic to do', () {
    final report = assess(DateTime(2026, 11, 9), 0);
    expect(report.daysLeft, 112);
    expect(report.learningDaysLeft, 84);
    expect(report.status, PaceStatus.onTrack);
    expect(report.todayTarget, 1);
    expect(report.weekTarget, 6);
  });

  test('half way through the plan with nothing done is behind', () {
    final report = assess(DateTime(2026, 12, 21), 0);
    expect(report.expectedByNow, 36);
    expect(report.status, PaceStatus.behind);
    expect(report.topicsNeededPerDay, closeTo(73 / 42, 0.001));
  });

  test('being 2 topics late is slightly behind', () {
    final report = assess(DateTime(2026, 12, 21), 34);
    expect(report.status, PaceStatus.slightlyBehind);
    expect(report.topicsBehind, 2);
  });

  test('today target stays the same after finishing a topic today', () {
    final report = assess(DateTime(2026, 11, 9), 1, coveredToday: 1);
    expect(report.todayTarget, 1);
    expect(report.todayRemaining, 0);
  });

  test('during revision time, unfinished topics spread over the days left', () {
    final report = assess(DateTime(2027, 2, 15), 70);
    expect(report.learningDaysLeft, 14);
    expect(report.expectedByNow, 73);
  });

  test('after the exam date nothing divides by zero', () {
    final report = assess(DateTime(2027, 3, 10), 10);
    expect(report.daysLeft, 0);
    expect(report.learningDaysLeft, 1);
  });

  test('advice warns when the daily need is more than the study time', () {
    final report = assess(DateTime(2027, 1, 18), 0);
    final advice = planner.catchUpAdvice(report, hoursPerDay: 1);
    expect(advice, contains('add study time'));
  });
}
