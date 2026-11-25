import 'dart:math';

import '../models/progress.dart';
import '../models/study_content.dart';

/// Whether the learner is keeping up with the plan.
enum PaceStatus {
  onTrack('On track'),
  slightlyBehind('Slightly behind'),
  behind('Behind');

  const PaceStatus(this.label);

  final String label;
}

/// All the numbers shown on the dashboard.
class PaceReport {
  const PaceReport({
    required this.daysLeft,
    required this.totalTopics,
    required this.coveredTopics,
    required this.expectedByNow,
    required this.learningDaysLeft,
    required this.todayTarget,
    required this.todayRemaining,
    required this.weekTarget,
    required this.topicsNeededPerDay,
    required this.status,
    required this.revisionStart,
  });

  final int daysLeft;
  final int totalTopics;
  final int coveredTopics;
  final int expectedByNow;
  final int learningDaysLeft;
  final int todayTarget;
  final int todayRemaining;
  final int weekTarget;
  final double topicsNeededPerDay;
  final PaceStatus status;
  final DateTime revisionStart;

  int get remainingTopics => totalTopics - coveredTopics;
  int get topicsBehind => max(0, expectedByNow - coveredTopics);
  int get percentComplete =>
      totalTopics == 0 ? 0 : (coveredTopics * 100 / totalTopics).round();
}

/// One block of the study plan.
class PlanWeek {
  const PlanWeek({required this.startsOn, required this.topics});

  final DateTime startsOn;
  final List<Topic> topics;
}

/// A topic that is due for another look.
class RevisionItem {
  const RevisionItem({required this.topic, required this.dueOn});

  final Topic topic;
  final DateTime dueOn;
}

/// A topic with too many wrong answers.
class WeakArea {
  const WeakArea({required this.topic, required this.tally});

  final Topic topic;
  final QuizTally tally;
}

/// Works out pace, targets, revision and weak areas. It only does sums,
/// so it can be tested without opening the app.
class StudyPlanner {
  const StudyPlanner();

  /// The last 4 weeks before the exam are kept for revision only.
  static const revisionDays = 28;

  /// Up to this many topics late still counts as slightly behind.
  static const slightlyBehindLimit = 3;

  /// Answers below this score make a topic a weak area.
  static const weakAccuracy = 0.7;

  /// Removes the time from a date so day counts stay exact.
  static DateTime dayOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// Counts whole calendar days between two dates, safe across clock changes.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;

  /// Builds the full dashboard report for today.
  PaceReport assess({
    required DateTime today,
    required StudySettings settings,
    required int totalTopics,
    required int coveredTopics,
    required int coveredToday,
  }) {
    final daysLeft = max(0, daysBetween(today, settings.examDate));
    final revisionStart = settings.examDate.subtract(const Duration(days: revisionDays));
    final learningDaysLeft = _learningDaysLeft(today, revisionStart, daysLeft);
    final remaining = totalTopics - coveredTopics;
    final remainingAtDayStart = remaining + coveredToday;
    final todayTarget = min(remainingAtDayStart,
        (remainingAtDayStart / learningDaysLeft).ceil());
    final expectedByNow =
        _expectedByNow(today, settings.planStart, revisionStart, totalTopics);

    return PaceReport(
      daysLeft: daysLeft,
      totalTopics: totalTopics,
      coveredTopics: coveredTopics,
      expectedByNow: expectedByNow,
      learningDaysLeft: learningDaysLeft,
      todayTarget: todayTarget,
      todayRemaining: max(0, todayTarget - coveredToday),
      weekTarget: _weekTarget(remaining, learningDaysLeft),
      topicsNeededPerDay: remaining / learningDaysLeft,
      status: _paceStatus(expectedByNow - coveredTopics),
      revisionStart: revisionStart,
    );
  }

  /// Days left for new topics. Once revision time starts, every remaining
  /// day may be used. It is never below 1, so the sums cannot divide by zero.
  int _learningDaysLeft(DateTime today, DateTime revisionStart, int daysLeft) {
    final beforeRevision = daysBetween(today, revisionStart);
    return max(1, beforeRevision > 0 ? beforeRevision : daysLeft);
  }

  /// How many topics should be finished before today's study begins.
  int _expectedByNow(
      DateTime today, DateTime planStart, DateTime revisionStart, int totalTopics) {
    final planLength = max(1, daysBetween(planStart, revisionStart));
    final daysPassed = daysBetween(planStart, today).clamp(0, planLength);
    return totalTopics * daysPassed ~/ planLength;
  }

  /// A week's share of the remaining topics, never more than what is left.
  int _weekTarget(int remaining, int learningDaysLeft) {
    if (remaining == 0) return 0;
    final weeklyShare = (remaining * 7 / learningDaysLeft).round();
    return min(remaining, max(1, weeklyShare));
  }

  /// Turns the number of late topics into a simple label.
  PaceStatus _paceStatus(int topicsLate) {
    if (topicsLate <= 0) return PaceStatus.onTrack;
    if (topicsLate <= slightlyBehindLimit) return PaceStatus.slightlyBehind;
    return PaceStatus.behind;
  }

  /// A plain sentence that says exactly what to do to stay on or get back on track.
  String catchUpAdvice(PaceReport report, {required int hoursPerDay}) {
    if (report.remainingTopics == 0) {
      return 'All topics are covered. Spend your time on revision and quizzes.';
    }
    final perDay = report.topicsNeededPerDay.toStringAsFixed(1);
    final base = 'Cover $perDay topics a day for ${report.learningDaysLeft} days '
        'to finish all ${report.remainingTopics} topics left.';
    final late = report.topicsBehind == 0
        ? ''
        : ' You are ${report.topicsBehind} topics behind today.';
    final overload = report.topicsNeededPerDay > hoursPerDay
        ? ' That is more than your $hoursPerDay hour a day, so add study time.'
        : '';
    return '$base$late$overload';
  }

  /// The next topics to study, in order.
  List<Topic> nextTopics(
      List<Topic> topics, Map<String, TopicProgress> progress, {int count = 3}) {
    return topics
        .where((topic) => !(progress[topic.id]?.isCovered ?? false))
        .take(count)
        .toList();
  }

  /// Topics due for revision, with the most overdue first.
  /// Weak topics come back sooner than confident ones.
  List<RevisionItem> revisionQueue(
      List<Topic> topics, Map<String, TopicProgress> progress, DateTime today) {
    final due = <RevisionItem>[];
    for (final topic in topics) {
      final entry = progress[topic.id];
      if (entry == null || !entry.isCovered || entry.lastStudiedOn == null) continue;
      final dueOn = entry.lastStudiedOn!.add(Duration(days: _revisionGap(entry.status)));
      if (!dueOn.isAfter(today)) due.add(RevisionItem(topic: topic, dueOn: dueOn));
    }
    due.sort((first, second) => first.dueOn.compareTo(second.dueOn));
    return due;
  }

  /// Days to wait before looking at a topic again.
  int _revisionGap(TopicStatus status) => switch (status) {
        TopicStatus.learning => 3,
        TopicStatus.revised => 14,
        _ => 30,
      };

  /// Topics scoring below the limit, with the lowest score first.
  List<WeakArea> weakAreas(List<Topic> topics, Map<String, QuizTally> tallies) {
    final weak = [
      for (final topic in topics)
        if ((tallies[topic.id]?.attempts ?? 0) > 0 &&
            tallies[topic.id]!.accuracy < weakAccuracy)
          WeakArea(topic: topic, tally: tallies[topic.id]!),
    ];
    weak.sort((first, second) => first.tally.accuracy.compareTo(second.tally.accuracy));
    return weak;
  }

  /// Spreads the topics left over weekly blocks up to the revision start.
  List<PlanWeek> weeklyPlan(List<Topic> remaining, DateTime today, int learningDaysLeft) {
    if (remaining.isEmpty) return const [];
    final weekCount = max(1, (learningDaysLeft / 7).ceil());
    final weeks = <PlanWeek>[];
    var taken = 0;
    for (var week = 0; week < weekCount; week++) {
      final until = (remaining.length * (week + 1) / weekCount).round();
      weeks.add(PlanWeek(
        startsOn: today.add(Duration(days: week * 7)),
        topics: remaining.sublist(taken, until),
      ));
      taken = until;
    }
    return weeks;
  }
}
