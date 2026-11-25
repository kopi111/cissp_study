import 'package:flutter/material.dart';

import '../models/mock_exam.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/question_card.dart';

/// Shows the score, how each domain went and every question missed.
class MockExamResultsView extends StatelessWidget {
  const MockExamResultsView({super.key, required this.result});

  static const _letters = ['A', 'B', 'C', 'D'];

  final MockExamResult result;

  /// Picks the colour for a percentage, measured against the ready mark.
  Color _colorFor(int percent) =>
      percent >= MockExamResult.readyPercent ? AppColors.good : AppColors.amber;

  /// Draws the overall score and what it means.
  Widget _buildScore(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verdict = result.reachedReadyMark
        ? 'You reached the ${MockExamResult.readyPercent}% guide. Keep practising with outside '
            'questions too.'
        : 'Below the ${MockExamResult.readyPercent}% guide. Start with your weakest domains below.';
    return SectionCard(
      title: 'Your score',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${result.percent}%',
              style: textTheme.headlineMedium!.copyWith(color: _colorFor(result.percent))),
          Text('${result.correctCount} out of ${result.questionCount} correct',
              style: textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(verdict, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Draws one domain's score and its bar.
  Widget _buildDomainScore(BuildContext context, DomainScore score) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${score.number}. ${score.name}', style: textTheme.bodyLarge),
          Text('${score.correctCount} of ${score.questionCount}, ${score.percent}%',
              style: textTheme.bodySmall),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: score.percent / 100,
            color: _colorFor(score.percent),
            backgroundColor: AppColors.line,
          ),
        ],
      ),
    );
  }

  /// Draws a missed question with what was chosen and the reason.
  Widget _buildMissedQuestion(BuildContext context, int position, MarkedQuestion item) {
    final choice = item.wasAnswered
        ? 'You chose ${_letters[item.chosenOption]}'
        : 'You did not reach this question';
    return SectionCard(
      title: 'Missed question $position. $choice',
      child: QuestionCard(
        key: ValueKey(item.question.id),
        question: item.question,
        showAnswerKey: true,
        onAnswered: (_) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missed = result.missedQuestions;
    return ScreenList(children: [
      _buildScore(context),
      SectionCard(
        title: 'By domain',
        child: Column(children: [
          for (final score in result.domainScores) _buildDomainScore(context, score),
        ]),
      ),
      FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
      for (var index = 0; index < missed.length; index++)
        _buildMissedQuestion(context, index + 1, missed[index]),
    ]);
  }
}
