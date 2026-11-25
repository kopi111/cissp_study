import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../widgets/common.dart';
import '../widgets/question_card.dart';

/// Runs a quiz one question at a time, then shows the score.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.title, required this.questions});

  final String title;
  final List<PracticeQuestion> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _correctCount = 0;
  bool _hasAnswered = false;

  bool get _isFinished => _questionIndex >= widget.questions.length;

  /// Counts the answer, saves it and shows the Next button.
  void _recordAnswer(PracticeQuestion question, bool wasCorrect) {
    AppScope.of(context).store.recordAnswer(question, wasCorrect: wasCorrect);
    setState(() {
      _hasAnswered = true;
      if (wasCorrect) _correctCount++;
    });
  }

  /// Moves on to the next question.
  void _goToNext() => setState(() {
        _questionIndex++;
        _hasAnswered = false;
      });

  /// Draws the current question and its Next button.
  Widget _buildQuestion() {
    final question = widget.questions[_questionIndex];
    return ScreenList(children: [
      Text('Question ${_questionIndex + 1} of ${widget.questions.length}',
          style: Theme.of(context).textTheme.titleMedium),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: QuestionCard(
            // A new key gives each question a fresh, unanswered card.
            key: ValueKey(question.id),
            question: question,
            onAnswered: (wasCorrect) => _recordAnswer(question, wasCorrect),
          ),
        ),
      ),
      if (_hasAnswered) FilledButton(onPressed: _goToNext, child: const Text('Next')),
    ]);
  }

  /// Draws the final score.
  Widget _buildResult() {
    final total = widget.questions.length;
    final percent = (_correctCount * 100 / total).round();
    return ScreenList(children: [
      Text('$_correctCount out of $total', style: Theme.of(context).textTheme.headlineMedium),
      Text('You scored $percent%. Your weak areas on the dashboard are now updated.',
          style: Theme.of(context).textTheme.bodyLarge),
      FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isFinished ? _buildResult() : _buildQuestion(),
    );
  }
}
