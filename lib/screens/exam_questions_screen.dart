import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../widgets/common.dart';
import '../widgets/question_card.dart';

/// "Exam-Related Questions for This Domain", with an answer key to open.
class ExamQuestionsScreen extends StatefulWidget {
  const ExamQuestionsScreen({super.key, required this.domain});

  final Domain domain;

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> {
  bool _showAnswerKey = false;

  /// Draws a question and the note of which topics it tests.
  Widget _buildQuestion(BuildContext context, int index) {
    final question = widget.domain.examQuestions[index];
    final store = AppScope.of(context).store;
    return SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: question,
            showAnswerKey: _showAnswerKey,
            onAnswered: (wasCorrect) => store.recordAnswer(question, wasCorrect: wasCorrect),
          ),
          const SizedBox(height: 10),
          Text('This tests: ${question.testedTopicIds.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.domain;
    return Scaffold(
      appBar: AppBar(title: Text('Domain ${domain.number} questions')),
      body: ScreenList(children: [
        Text('Exam-Related Questions for This Domain',
            style: Theme.of(context).textTheme.titleLarge),
        Text('New practice questions in the exam style. Tap an answer to see the reason.',
            style: Theme.of(context).textTheme.bodyMedium),
        for (var index = 0; index < domain.examQuestions.length; index++)
          _buildQuestion(context, index),
        OutlinedButton(
          onPressed: () => setState(() => _showAnswerKey = !_showAnswerKey),
          child: Text(_showAnswerKey ? 'Hide answer key' : 'Show answer key'),
        ),
      ]),
    );
  }
}
