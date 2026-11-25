import 'speech_voice.dart';

/// How well the learner knows a topic.
enum TopicStatus {
  notStarted('Not started'),
  learning('Learning'),
  revised('Revised'),
  confident('Confident');

  const TopicStatus(this.label);

  final String label;

  /// Reads a saved status name, and treats anything unknown as not started.
  static TopicStatus fromName(String name) => TopicStatus.values.firstWhere(
        (status) => status.name == name,
        orElse: () => TopicStatus.notStarted,
      );
}

/// What the learner has done on one topic.
class TopicProgress {
  const TopicProgress({
    this.status = TopicStatus.notStarted,
    this.coveredOn,
    this.lastStudiedOn,
  });

  final TopicStatus status;
  final DateTime? coveredOn;
  final DateTime? lastStudiedOn;

  /// A topic counts as covered once it has been studied at least one time.
  bool get isCovered => status != TopicStatus.notStarted;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'coveredOn': coveredOn?.toIso8601String(),
        'lastStudiedOn': lastStudiedOn?.toIso8601String(),
      };

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
        status: TopicStatus.fromName(json['status'] as String),
        coveredOn: DateTime.tryParse(json['coveredOn'] as String? ?? ''),
        lastStudiedOn: DateTime.tryParse(json['lastStudiedOn'] as String? ?? ''),
      );
}

/// Right and wrong answers for one topic.
class QuizTally {
  const QuizTally({this.attempts = 0, this.correct = 0});

  final int attempts;
  final int correct;

  /// The share of answers that were right, from 0 to 1.
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// Returns a new tally with one more answer added.
  QuizTally withAnswer({required bool wasCorrect}) => QuizTally(
        attempts: attempts + 1,
        correct: correct + (wasCorrect ? 1 : 0),
      );

  Map<String, dynamic> toJson() => {'attempts': attempts, 'correct': correct};

  factory QuizTally.fromJson(Map<String, dynamic> json) => QuizTally(
        attempts: json['attempts'] as int,
        correct: json['correct'] as int,
      );
}

/// The learner's exam date, study time and reading size.
class StudySettings {
  const StudySettings({
    required this.examDate,
    required this.planStart,
    this.hoursPerDay = 1,
    this.textScale = 1.0,
    this.voice = SpeechVoice.phoneDefault,
  });

  final DateTime examDate;
  final DateTime planStart;
  final int hoursPerDay;
  final double textScale;
  final SpeechVoice voice;

  /// Returns a copy with only the given values changed.
  StudySettings copyWith({
    DateTime? examDate,
    int? hoursPerDay,
    double? textScale,
    SpeechVoice? voice,
  }) =>
      StudySettings(
        examDate: examDate ?? this.examDate,
        planStart: planStart,
        hoursPerDay: hoursPerDay ?? this.hoursPerDay,
        textScale: textScale ?? this.textScale,
        voice: voice ?? this.voice,
      );

  Map<String, dynamic> toJson() => {
        'examDate': examDate.toIso8601String(),
        'planStart': planStart.toIso8601String(),
        'hoursPerDay': hoursPerDay,
        'textScale': textScale,
        'voiceName': voice.name,
        'voiceLocale': voice.locale,
      };

  factory StudySettings.fromJson(Map<String, dynamic> json) => StudySettings(
        examDate: DateTime.parse(json['examDate'] as String),
        planStart: DateTime.parse(json['planStart'] as String),
        hoursPerDay: json['hoursPerDay'] as int,
        textScale: (json['textScale'] as num).toDouble(),
        // Progress saved before voices existed has no voice, so it keeps the normal one.
        voice: SpeechVoice(
          name: json['voiceName'] as String? ?? '',
          locale: json['voiceLocale'] as String? ?? '',
        ),
      );
}
