import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../services/quiz_builder.dart';
import '../widgets/common.dart';
import 'mock_exam_intro_screen.dart';
import 'quiz_screen.dart';

/// Lets the learner choose "Quiz me" or a domain quiz.
class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({super.key});

  /// Opens a quiz with the given questions.
  void _openQuiz(BuildContext context, String title, List<PracticeQuestion> questions) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizScreen(title: title, questions: questions)));
  }

  /// Starts a mixed quiz, or explains why there are no questions yet.
  void _startQuizMe(BuildContext context) {
    final scope = AppScope.of(context);
    final questions = QuizBuilder().quizMe(scope.library, scope.store);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Study a topic first. Quiz me only uses topics you have covered.')));
      return;
    }
    _openQuiz(context, 'Quiz me', questions);
  }

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    return ScreenList(children: [
      Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
      FilledButton(
        onPressed: () => _startQuizMe(context),
        child: const Text('Quiz me: 5 mixed questions'),
      ),
      OutlinedButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MockExamIntroScreen())),
        child: const Text('Mock exam: 150 questions, 3 hours'),
      ),
      Text('Domain quiz: 10 questions', style: Theme.of(context).textTheme.titleLarge),
      for (final domain in library.domains)
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text('${domain.number}. ${domain.name}'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _openQuiz(context, 'Domain ${domain.number} quiz',
                QuizBuilder().domainQuiz(domain)),
          ),
        ),
    ]);
  }
}
