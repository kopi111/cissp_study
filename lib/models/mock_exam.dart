import 'study_content.dart';

/// One mock exam being sat: its questions, its deadline and the answers so far.
class MockExamAttempt {
  MockExamAttempt({
    required this.questionIds,
    required this.endsAt,
    List<int>? chosenOptions,
  }) : chosenOptions = chosenOptions ?? [];

  /// Stands for "no exam has been started", so callers never handle a null.
  static final none = MockExamAttempt(questionIds: const [], endsAt: DateTime(2000));

  final List<String> questionIds;
  final DateTime endsAt;
  final List<int> chosenOptions;

  bool get isInProgress => questionIds.isNotEmpty;
  int get questionCount => questionIds.length;
  int get answeredCount => chosenOptions.length;
  bool get isComplete => answeredCount >= questionCount;
  String get currentQuestionId => questionIds[answeredCount];

  /// Saves the choice for the current question and moves on. There is no going back.
  void answerCurrent(int optionIndex) => chosenOptions.add(optionIndex);

  /// How long is left at the given moment, and never less than zero.
  Duration timeLeftAt(DateTime now) {
    final timeLeft = endsAt.difference(now);
    return timeLeft.isNegative ? Duration.zero : timeLeft;
  }

  bool isOutOfTimeAt(DateTime now) => timeLeftAt(now) == Duration.zero;

  Map<String, dynamic> toJson() => {
        'questionIds': questionIds,
        'endsAt': endsAt.toIso8601String(),
        'chosenOptions': chosenOptions,
      };

  factory MockExamAttempt.fromJson(Map<String, dynamic> json) => MockExamAttempt(
        questionIds: List<String>.from(json['questionIds'] as List),
        endsAt: DateTime.parse(json['endsAt'] as String),
        chosenOptions: List<int>.from(json['chosenOptions'] as List),
      );
}

/// One exam question after marking.
class MarkedQuestion {
  const MarkedQuestion(this.question, this.chosenOption);

  /// The value held by a question the clock ran out on.
  static const notAnswered = -1;

  final PracticeQuestion question;
  final int chosenOption;

  bool get wasAnswered => chosenOption != notAnswered;
  bool get isCorrect => chosenOption == question.correctIndex;
}

/// How the learner did in one domain of a mock exam.
class DomainScore {
  const DomainScore({
    required this.number,
    required this.name,
    required this.correctCount,
    required this.questionCount,
  });

  final int number;
  final String name;
  final int correctCount;
  final int questionCount;

  int get percent => (correctCount * 100 / questionCount).round();
}

/// The marked paper: the total, each domain and the questions missed.
class MockExamResult {
  const MockExamResult(this.markedQuestions, this.domainScores);

  /// A common rule of thumb for being ready. It is not the real exam's pass mark.
  static const readyPercent = 75;

  final List<MarkedQuestion> markedQuestions;
  final List<DomainScore> domainScores;

  /// Marks an attempt. Questions the clock ran out on count as wrong.
  factory MockExamResult.mark(MockExamAttempt attempt, StudyLibrary library) {
    final marked = [
      for (var index = 0; index < attempt.questionCount; index++)
        MarkedQuestion(
          library.questionById(attempt.questionIds[index]),
          index < attempt.answeredCount
              ? attempt.chosenOptions[index]
              : MarkedQuestion.notAnswered,
        ),
    ];
    return MockExamResult(marked, _scoreEachDomain(marked, library));
  }

  /// Adds up the paper one domain at a time.
  static List<DomainScore> _scoreEachDomain(
      List<MarkedQuestion> marked, StudyLibrary library) {
    return [
      for (final domain in library.domains)
        _scoreDomain(
          domain,
          marked.where((item) => library.domainNumberOf(item.question) == domain.number),
        ),
    ];
  }

  /// Counts one domain's right answers.
  static DomainScore _scoreDomain(Domain domain, Iterable<MarkedQuestion> marked) {
    return DomainScore(
      number: domain.number,
      name: domain.name,
      correctCount: marked.where((item) => item.isCorrect).length,
      questionCount: marked.length,
    );
  }

  int get questionCount => markedQuestions.length;
  int get correctCount => markedQuestions.where((item) => item.isCorrect).length;
  int get percent => (correctCount * 100 / questionCount).round();
  bool get reachedReadyMark => percent >= readyPercent;

  /// The questions the learner got wrong or did not reach.
  List<MarkedQuestion> get missedQuestions =>
      markedQuestions.where((item) => !item.isCorrect).toList();

  /// The questions the learner actually answered, right or wrong.
  Iterable<MarkedQuestion> get answeredQuestions =>
      markedQuestions.where((item) => item.wasAnswered);
}

/// A short record of a finished mock exam, kept to show progress over time.
class MockExamRecord {
  const MockExamRecord({
    required this.finishedOn,
    required this.correctCount,
    required this.questionCount,
  });

  final DateTime finishedOn;
  final int correctCount;
  final int questionCount;

  int get percent => (correctCount * 100 / questionCount).round();

  Map<String, dynamic> toJson() => {
        'finishedOn': finishedOn.toIso8601String(),
        'correctCount': correctCount,
        'questionCount': questionCount,
      };

  factory MockExamRecord.fromJson(Map<String, dynamic> json) => MockExamRecord(
        finishedOn: DateTime.parse(json['finishedOn'] as String),
        correctCount: json['correctCount'] as int,
        questionCount: json['questionCount'] as int,
      );
}
