import 'package:flutter/material.dart';

import '../models/study_content.dart';
import '../theme.dart';

/// Shows one question. The answer stays hidden until an option is tapped.
class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswered,
    this.showAnswerKey = false,
  });

  final PracticeQuestion question;
  final ValueChanged<bool> onAnswered;
  final bool showAnswerKey;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  static const _letters = ['A', 'B', 'C', 'D'];
  int _chosenIndex = -1;

  bool get _hasAnswered => _chosenIndex >= 0;
  bool get _answerIsVisible => _hasAnswered || widget.showAnswerKey;

  /// Saves the first choice only, so a question cannot be answered twice.
  void _choose(int index) {
    if (_hasAnswered) return;
    setState(() => _chosenIndex = index);
    widget.onAnswered(index == widget.question.correctIndex);
  }

  /// Picks an option's border colour once the answer can be shown.
  Color _optionColor(int index) {
    if (!_answerIsVisible) return AppColors.line;
    if (index == widget.question.correctIndex) return AppColors.good;
    return index == _chosenIndex ? AppColors.bad : AppColors.line;
  }

  /// Draws one tappable answer.
  Widget _buildOption(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _choose(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _optionColor(index), width: 2),
          ),
          child: Text('${_letters[index]}.  ${widget.question.options[index]}',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }

  /// Draws the result line and the simple reason.
  Widget _buildAnswer(BuildContext context) {
    final question = widget.question;
    final wasRight = _chosenIndex == question.correctIndex;
    final heading = !_hasAnswered
        ? 'Answer: ${_letters[question.correctIndex]}'
        : wasRight
            ? 'Correct'
            : 'Not quite. The answer is ${_letters[question.correctIndex]}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.evergreenSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(question.explanation, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.question.prompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        for (var index = 0; index < widget.question.options.length; index++)
          _buildOption(context, index),
        if (_answerIsVisible) _buildAnswer(context),
      ],
    );
  }
}
