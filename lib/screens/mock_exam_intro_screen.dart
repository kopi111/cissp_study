import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/mock_exam.dart';
import '../models/study_content.dart';
import '../services/mock_exam_builder.dart';
import '../services/mock_exam_store.dart';
import '../widgets/common.dart';
import 'mock_exam_screen.dart';

/// Explains the mock exam, and starts or continues one.
class MockExamIntroScreen extends StatefulWidget {
  const MockExamIntroScreen({super.key});

  @override
  State<MockExamIntroScreen> createState() => _MockExamIntroScreenState();
}

class _MockExamIntroScreenState extends State<MockExamIntroScreen> {
  final Future<MockExamStore> _opening = MockExamStore.open();

  StudyLibrary get _library => AppScope.of(context).library;

  /// Sets a new paper, saves it and opens it, so the clock starts now.
  Future<void> _startExam(MockExamStore examStore) async {
    final attempt = MockExamBuilder().startAttempt(_library, DateTime.now());
    await examStore.saveAttempt(attempt);
    await _openExam(attempt, examStore);
  }

  /// Opens the exam, then redraws this page to show what changed.
  Future<void> _openExam(MockExamAttempt attempt, MockExamStore examStore) async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MockExamScreen(attempt: attempt, examStore: examStore),
    ));
    if (mounted) setState(() {});
  }

  /// Throws away the exam in progress, after asking first.
  Future<void> _giveUp(MockExamStore examStore) async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Give up this exam?'),
        content: const Text('Your answers for this exam will be lost and it will not be marked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Give up'),
          ),
        ],
      ),
    );
    if (shouldDiscard != true) return;
    await examStore.discardAttempt();
    if (mounted) setState(() {});
  }

  /// Describes the exam in progress and offers to carry on.
  Widget _buildAttemptInProgress(MockExamAttempt attempt, MockExamStore examStore) {
    final now = DateTime.now();
    final isOutOfTime = attempt.isOutOfTimeAt(now);
    final summary = isOutOfTime
        ? 'Time is up. ${attempt.answeredCount} of ${attempt.questionCount} questions answered.'
        : 'Next is question ${attempt.answeredCount + 1} of ${attempt.questionCount}. '
            '${formatClock(attempt.timeLeftAt(now))} left.';
    return SectionCard(
      title: 'Exam in progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(summary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _openExam(attempt, examStore),
            child: Text(isOutOfTime ? 'See your result' : 'Continue exam'),
          ),
          if (!isOutOfTime)
            TextButton(onPressed: () => _giveUp(examStore), child: const Text('Give up this exam')),
        ],
      ),
    );
  }

  /// Lists the most recent finished exams.
  Widget _buildPastResults(List<MockExamRecord> results) {
    final recentResults = results.take(_pastResultsShown);
    return SectionCard(
      title: 'Your past scores',
      child: BulletList([
        for (final result in recentResults)
          '${formatDate(result.finishedOn)}: ${result.percent}% '
              '(${result.correctCount} of ${result.questionCount})',
      ]),
    );
  }

  static const _pastResultsShown = 5;

  /// Draws the page once the saved data is open.
  Widget _buildPage(MockExamStore examStore) {
    final attempt = examStore.savedAttempt(_library);
    final pastResults = examStore.pastResults;
    return ScreenList(children: [
      SectionCard(
        title: 'How it works',
        child: BulletList([
          '${MockExamBuilder.questionCount} mixed questions, shared across the domains '
              'by their exam weight.',
          '${MockExamBuilder.timeAllowed.inHours} hours on the clock.',
          'One question at a time, and you cannot go back.',
          'You see no answers until the end.',
          'If you leave, your answers are saved but the clock keeps running.',
        ]),
      ),
      if (attempt.isInProgress)
        _buildAttemptInProgress(attempt, examStore)
      else
        FilledButton(
          onPressed: () => _startExam(examStore),
          child: const Text('Start mock exam'),
        ),
      if (pastResults.isNotEmpty) _buildPastResults(pastResults),
      Text(
        'Aim for about ${MockExamResult.readyPercent}% as a rough guide. The real exam adapts '
        'to you and is scored differently, so this score cannot predict a pass.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock exam')),
      body: FutureBuilder<MockExamStore>(
        future: _opening,
        builder: (_, snapshot) => snapshot.hasData
            ? _buildPage(snapshot.data!)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
