import 'dart:math';

import '../models/study_content.dart';
import 'progress_store.dart';

/// Chooses questions for each kind of quiz.
class QuizBuilder {
  QuizBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const mixedQuizSize = 5;
  static const domainQuizSize = 10;

  /// Picks mixed questions, only from topics the learner has covered.
  List<PracticeQuestion> quizMe(StudyLibrary library, ProgressStore store) {
    bool isCovered(String id) => store.progressOf(id).isCovered;
    final pool = <PracticeQuestion>[
      for (final topic in library.topics)
        if (isCovered(topic.id)) ...[topic.question, ...topic.practiceQuestions],
      for (final domain in library.domains)
        ...domain.examQuestions.where((q) => q.testedTopicIds.every(isCovered)),
    ];
    return (pool..shuffle(_random)).take(mixedQuizSize).toList();
  }

  /// Picks 10 exam-related questions from one domain, in random order.
  List<PracticeQuestion> domainQuiz(Domain domain) {
    final pool = [...domain.examQuestions]..shuffle(_random);
    return pool.take(domainQuizSize).toList();
  }
}
