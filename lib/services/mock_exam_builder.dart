import 'dart:math';

import '../models/mock_exam.dart';
import '../models/study_content.dart';

/// Sets a full mock exam paper in the same proportions as the real exam.
class MockExamBuilder {
  MockExamBuilder({Random? random}) : _random = random ?? Random();

  static const questionCount = 150;
  static const timeAllowed = Duration(hours: 3);

  final Random _random;

  /// Starts a new attempt whose clock runs from the given moment.
  MockExamAttempt startAttempt(StudyLibrary library, DateTime startedAt) {
    return MockExamAttempt(
      questionIds: _chooseQuestionIds(library.domains),
      endsAt: startedAt.add(timeAllowed),
    );
  }

  /// Takes each domain's share of questions, then mixes the whole paper.
  List<String> _chooseQuestionIds(List<Domain> domains) {
    final counts = questionCountsFor(domains);
    final chosen = <String>[
      for (final domain in domains) ..._chooseFromDomain(domain, counts[domain.number]!),
    ];
    return chosen..shuffle(_random);
  }

  /// Picks random questions from one domain.
  Iterable<String> _chooseFromDomain(Domain domain, int count) {
    final pool = [...domain.allQuestions]..shuffle(_random);
    return pool.take(count).map((question) => question.id);
  }

  /// Splits the paper by exam weight. Rounding leftovers go to the largest remainders.
  static Map<int, int> questionCountsFor(List<Domain> domains) {
    double exactShare(Domain domain) => questionCount * domain.weightPercent / 100;
    final counts = {for (final domain in domains) domain.number: exactShare(domain).floor()};
    final leftover = questionCount - counts.values.fold<int>(0, (sum, count) => sum + count);
    double remainder(Domain domain) => exactShare(domain) - counts[domain.number]!;
    final largestFirst = [...domains]..sort((a, b) => remainder(b).compareTo(remainder(a)));
    for (final domain in largestFirst.take(leftover)) {
      counts[domain.number] = counts[domain.number]! + 1;
    }
    return counts;
  }
}
