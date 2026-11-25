import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/mock_exam.dart';
import '../models/study_content.dart';
import '../services/mock_exam_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mock_exam_results_view.dart';

/// What the learner picked in the "leave the exam" dialog.
enum _LeaveChoice { keepGoing, leave, finishNow }

/// Runs the timed exam, then shows the marked result on the same screen.
class MockExamScreen extends StatefulWidget {
  const MockExamScreen({super.key, required this.attempt, required this.examStore});

  final MockExamAttempt attempt;
  final MockExamStore examStore;

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  static const _nothingChosen = -1;
  static const _lowTimeWarning = Duration(minutes: 10);
  static const _letters = ['A', 'B', 'C', 'D'];

  late final ValueNotifier<Duration> _timeLeft;
  late final Timer _clock;
  int _chosenOption = _nothingChosen;
  MockExamResult? _result;

  MockExamAttempt get _attempt => widget.attempt;
  StudyLibrary get _library => AppScope.of(context).library;
  bool get _isFinished => _result != null;

  @override
  void initState() {
    super.initState();
    _timeLeft = ValueNotifier(_attempt.timeLeftAt(DateTime.now()));
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    // Marks at once an exam reopened after its time ran out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateClock());
  }

  @override
  void dispose() {
    _clock.cancel();
    _timeLeft.dispose();
    super.dispose();
  }

  /// Shows the time left, and ends the exam when it reaches zero.
  void _updateClock() {
    if (!mounted || _isFinished) return;
    final now = DateTime.now();
    _timeLeft.value = _attempt.timeLeftAt(now);
    if (_attempt.isOutOfTimeAt(now) || _attempt.isComplete) _finishExam();
  }

  /// Saves the chosen answer and moves on, or finishes after the last question.
  void _confirmAnswer() {
    _attempt.answerCurrent(_chosenOption);
    if (_attempt.isComplete) {
      _finishExam();
      return;
    }
    widget.examStore.saveAttempt(_attempt);
    setState(() => _chosenOption = _nothingChosen);
  }

  /// Marks the paper once, saves the score and feeds the weak-area tracker.
  void _finishExam() {
    if (_isFinished) return;
    _clock.cancel();
    final result = MockExamResult.mark(_attempt, _library);
    setState(() => _result = result);
    widget.examStore.recordFinished(result, DateTime.now());
    AppScope.of(context).store.recordAnswers([
      for (final item in result.answeredQuestions) (item.question, item.isCorrect),
    ]);
  }

  /// Asks what to do when the learner tries to leave during the exam.
  Future<void> _confirmLeaving() async {
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave the exam?'),
        content: const Text('Your answers are saved, but the clock keeps running.'),
        actions: [
          _buildLeaveAction(dialogContext, 'End and mark', _LeaveChoice.finishNow),
          _buildLeaveAction(dialogContext, 'Leave', _LeaveChoice.leave),
          _buildLeaveAction(dialogContext, 'Keep going', _LeaveChoice.keepGoing),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == _LeaveChoice.finishNow) _finishExam();
    if (choice == _LeaveChoice.leave) Navigator.of(context).pop();
  }

  /// Draws one button of the leave dialog.
  Widget _buildLeaveAction(BuildContext dialogContext, String label, _LeaveChoice choice) {
    return TextButton(
      onPressed: () => Navigator.of(dialogContext).pop(choice),
      child: Text(label),
    );
  }

  /// Draws the countdown, which turns red for the last few minutes.
  Widget _buildClock() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: ValueListenableBuilder<Duration>(
          valueListenable: _timeLeft,
          builder: (context, timeLeft, _) => Text(
            formatClock(timeLeft),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: timeLeft < _lowTimeWarning ? AppColors.bad : AppColors.ink),
          ),
        ),
      ),
    );
  }

  /// Draws one answer. Choosing it only highlights it; nothing is marked yet.
  Widget _buildOption(PracticeQuestion question, int index) {
    final isChosen = index == _chosenOption;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _chosenOption = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isChosen ? AppColors.evergreenSoft : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isChosen ? AppColors.evergreen : AppColors.line, width: 2),
        ),
        child: Text('${_letters[index]}.  ${question.options[index]}',
            style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }

  /// Draws the current question, starting from the top of the page each time.
  Widget _buildQuestion() {
    final question = _library.questionById(_attempt.currentQuestionId);
    final position = _attempt.answeredCount + 1;
    return ScreenList(key: ValueKey(position), children: [
      Text('Question $position of ${_attempt.questionCount}',
          style: Theme.of(context).textTheme.titleMedium),
      LinearProgressIndicator(value: position / _attempt.questionCount),
      Text(question.prompt, style: Theme.of(context).textTheme.bodyLarge),
      for (var index = 0; index < question.options.length; index++) _buildOption(question, index),
    ]);
  }

  /// Draws the button that stays in view below long questions.
  Widget _buildNextButton() {
    final isLastQuestion = _attempt.answeredCount + 1 == _attempt.questionCount;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _chosenOption == _nothingChosen ? null : _confirmAnswer,
          child: Text(isLastQuestion ? 'Finish exam' : 'Next'),
        ),
      ),
    );
  }

  /// Draws the screen while the exam is being sat.
  Widget _buildExam() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeaving();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mock exam'), actions: [_buildClock()]),
        body: _attempt.isComplete ? const SizedBox.shrink() : _buildQuestion(),
        bottomNavigationBar: _attempt.isComplete ? null : _buildNextButton(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) return _buildExam();
    return Scaffold(
      appBar: AppBar(title: const Text('Mock exam result')),
      body: MockExamResultsView(result: result),
    );
  }
}
