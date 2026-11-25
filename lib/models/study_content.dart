/// One multiple-choice question, used for topic questions and domain questions.
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.testedTopicIds,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<String> testedTopicIds;

  /// Domain questions have IDs like "D1-Q3". Topic questions use the topic ID.
  bool get isDomainQuestion => id.startsWith('D');

  /// Builds a question from the JSON notes file.
  factory PracticeQuestion.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required List<String> testedTopicIds,
  }) {
    return PracticeQuestion(
      id: id,
      prompt: json['prompt'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      testedTopicIds: testedTopicIds,
    );
  }
}

/// A word and its meaning in plain English.
class KeyTerm {
  const KeyTerm(this.term, this.meaning);

  final String term;
  final String meaning;

  factory KeyTerm.fromJson(Map<String, dynamic> json) =>
      KeyTerm(json['term'] as String, json['meaning'] as String);
}

/// One headed part of the study notes.
class NoteSection {
  const NoteSection(this.heading, this.body);

  final String heading;
  final String body;

  factory NoteSection.fromJson(Map<String, dynamic> json) =>
      NoteSection(json['heading'] as String, json['body'] as String);
}

/// One study topic, such as T01.
class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.outlineReference,
    required this.domainNumber,
    required this.domainName,
    required this.simpleExplanation,
    required this.noteSections,
    required this.keyTerms,
    required this.keyPoints,
    required this.memoryHook,
    required this.question,
    required this.practiceQuestions,
  });

  final String id;
  final String name;
  final String outlineReference;
  final int domainNumber;
  final String domainName;
  final String simpleExplanation;
  final List<NoteSection> noteSections;
  final List<KeyTerm> keyTerms;
  final List<String> keyPoints;
  final String memoryHook;
  final PracticeQuestion question;
  final List<PracticeQuestion> practiceQuestions;

  /// The topic in reading order, in parts small enough to skip between.
  List<ReadAloudPart> get readAloudParts {
    final groupTitle = '$id  $name';
    return [
      ReadAloudPart(
        groupTitle: groupTitle,
        title: 'In simple words',
        text: 'Next topic. $name.\n\n$simpleExplanation',
      ),
      for (final section in noteSections)
        ReadAloudPart(
          groupTitle: groupTitle,
          title: section.heading,
          text: '${section.heading}.\n\n${section.body}',
        ),
      ReadAloudPart(
        groupTitle: groupTitle,
        title: 'Key points and memory hook',
        text: ['Key points.', ...keyPoints, 'Memory hook. $memoryHook'].join('\n\n'),
      ),
    ];
  }

  /// Builds a topic from the JSON notes file.
  factory Topic.fromJson(
    Map<String, dynamic> json, {
    required int domainNumber,
    required String domainName,
  }) {
    final id = json['id'] as String;
    return Topic(
      id: id,
      name: json['name'] as String,
      outlineReference: json['outlineRef'] as String,
      domainNumber: domainNumber,
      domainName: domainName,
      simpleExplanation: json['simpleExplanation'] as String,
      noteSections: (json['studyNotes'] as List)
          .map((section) => NoteSection.fromJson(section as Map<String, dynamic>))
          .toList(),
      keyTerms: (json['keyTerms'] as List)
          .map((term) => KeyTerm.fromJson(term as Map<String, dynamic>))
          .toList(),
      keyPoints: List<String>.from(json['keyPoints'] as List),
      memoryHook: json['memoryHook'] as String,
      question: PracticeQuestion.fromJson(
        json['question'] as Map<String, dynamic>,
        id: id,
        testedTopicIds: [id],
      ),
      practiceQuestions: _practiceQuestionsFromJson(json, id),
    );
  }

  /// Reads the topic's extra questions. Topics not yet deepened have none.
  static List<PracticeQuestion> _practiceQuestionsFromJson(
      Map<String, dynamic> json, String topicId) {
    final rawQuestions = json['practiceQuestions'] as List? ?? const [];
    return [
      for (var index = 0; index < rawQuestions.length; index++)
        PracticeQuestion.fromJson(
          rawQuestions[index] as Map<String, dynamic>,
          id: '$topicId-P${index + 1}',
          testedTopicIds: [topicId],
        ),
    ];
  }
}

/// One stretch of a domain read out loud, with the labels shown while it plays.
class ReadAloudPart {
  const ReadAloudPart({required this.groupTitle, required this.title, required this.text});

  final String groupTitle;
  final String title;
  final String text;
}

/// One of the 8 CISSP domains.
class Domain {
  const Domain({
    required this.number,
    required this.name,
    required this.weightPercent,
    required this.plainMeaning,
    required this.topics,
    required this.examQuestions,
    required this.reviewSession,
  });

  final int number;
  final String name;
  final int weightPercent;
  final String plainMeaning;
  final List<Topic> topics;
  final List<PracticeQuestion> examQuestions;
  final List<NoteSection> reviewSession;

  /// Every question this domain has, of all three kinds.
  List<PracticeQuestion> get allQuestions => [
        for (final topic in topics) ...[topic.question, ...topic.practiceQuestions],
        ...examQuestions,
      ];

  /// The whole domain in reading order: every topic, then the review session.
  List<ReadAloudPart> get readAloudParts => [
        for (final topic in topics) ...topic.readAloudParts,
        for (final item in reviewSession)
          ReadAloudPart(
            groupTitle: 'Review session',
            title: item.heading,
            text: '${item.heading}.\n\n${item.body}',
          ),
      ];

  /// Builds a domain, its topics and its exam questions from the JSON file.
  factory Domain.fromJson(Map<String, dynamic> json) {
    final number = json['number'] as int;
    final name = json['name'] as String;
    final rawQuestions = json['examQuestions'] as List;
    return Domain(
      number: number,
      name: name,
      weightPercent: json['weightPercent'] as int,
      plainMeaning: json['plainMeaning'] as String,
      topics: (json['topics'] as List)
          .map((topic) => Topic.fromJson(topic as Map<String, dynamic>,
              domainNumber: number, domainName: name))
          .toList(),
      examQuestions: [
        for (var index = 0; index < rawQuestions.length; index++)
          _examQuestionFromJson(
              rawQuestions[index] as Map<String, dynamic>, number, index),
      ],
      // Domains not yet deepened have no review session.
      reviewSession: (json['reviewSession'] as List? ?? const [])
          .map((item) => NoteSection.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Gives a domain question a stable ID such as "D3-Q7".
  static PracticeQuestion _examQuestionFromJson(
      Map<String, dynamic> json, int domainNumber, int index) {
    return PracticeQuestion.fromJson(
      json,
      id: 'D$domainNumber-Q${index + 1}',
      testedTopicIds: List<String>.from(json['testsTopics'] as List),
    );
  }
}

/// All the study material in the app.
class StudyLibrary {
  StudyLibrary(this.domains)
      : topics = [for (final domain in domains) ...domain.topics];

  final List<Domain> domains;
  final List<Topic> topics;

  /// Every question in the app, found by its ID.
  late final Map<String, PracticeQuestion> _questionsById = {
    for (final domain in domains)
      for (final question in domain.allQuestions) question.id: question,
  };

  /// Says whether a saved question ID still exists in the notes.
  bool hasQuestion(String id) => _questionsById.containsKey(id);

  /// Finds a question by ID, and throws if the ID does not exist.
  PracticeQuestion questionById(String id) => _questionsById[id]!;

  /// The domain a question belongs to, taken from the first topic it tests.
  int domainNumberOf(PracticeQuestion question) =>
      topicById(question.testedTopicIds.first).domainNumber;

  /// Finds a topic by ID, and throws if the ID does not exist.
  Topic topicById(String id) => topics.firstWhere((topic) => topic.id == id);

  /// Finds a domain by its number, and throws if it does not exist.
  Domain domainByNumber(int number) =>
      domains.firstWhere((domain) => domain.number == number);
}
