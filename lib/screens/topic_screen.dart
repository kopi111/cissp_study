import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/progress.dart';
import '../models/study_content.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/question_card.dart';
import 'quiz_screen.dart';

/// The full lesson for one topic.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final SpeechService _speech = SpeechService.instance;

  /// Stops reading when the learner leaves the lesson.
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  /// Puts the lesson in the order it should be read aloud.
  List<String> get _passagesToRead {
    final topic = widget.topic;
    return [
      topic.name,
      topic.simpleExplanation,
      for (final section in topic.noteSections) ...[section.heading, section.body],
      'Key points.',
      ...topic.keyPoints,
      'Memory hook. ${topic.memoryHook}',
    ];
  }

  /// Starts or stops reading aloud.
  void _toggleReading() {
    _speech.isReading ? _speech.stop() : _speech.read(_passagesToRead);
  }

  /// Opens this topic's extra questions, in a new order each time.
  void _openPractice(BuildContext context) {
    final topic = widget.topic;
    // Shuffled once here, because the route's builder runs again on every redraw.
    final questions = [...topic.practiceQuestions]..shuffle();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(title: '${topic.id} practice', questions: questions),
    ));
  }

  /// Draws the button that starts this topic's extra questions.
  Widget _buildPracticeButton(BuildContext context) {
    return FilledButton(
      onPressed: () => _openPractice(context),
      child: Text('Practice: ${widget.topic.practiceQuestions.length} more questions'),
    );
  }

  /// Draws the button that changes each time reading starts or stops.
  Widget _buildReadButton() {
    return ListenableBuilder(
      listenable: _speech,
      builder: (_, __) => TextButton.icon(
        onPressed: _toggleReading,
        icon: Icon(_speech.isReading ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
        label: Text(_speech.isReading ? 'Stop' : 'Read aloud'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final topic = widget.topic;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(topic.id), actions: [_buildReadButton()]),
      body: ScreenList(children: [
        Text(topic.name, style: textTheme.headlineMedium),
        Text('Domain ${topic.domainNumber}: ${topic.domainName}  ·  Outline ${topic.outlineReference}',
            style: textTheme.bodySmall),
        SectionCard(title: 'In simple words', child: Text(topic.simpleExplanation, style: textTheme.bodyLarge)),
        for (var index = 0; index < topic.noteSections.length; index++)
          LessonPartCard(
            label: 'Part ${index + 1} of ${topic.noteSections.length}',
            section: topic.noteSections[index],
            speech: _speech,
          ),
        SectionCard(title: 'Words to know', child: _KeyTermsList(terms: topic.keyTerms)),
        SectionCard(title: 'Key points to remember', child: BulletList(topic.keyPoints)),
        _MemoryHookCard(hook: topic.memoryHook),
        SectionCard(
          title: 'Practice question',
          child: QuestionCard(
            question: topic.question,
            onAnswered: (wasCorrect) =>
                scope.store.recordAnswer(topic.question, wasCorrect: wasCorrect),
          ),
        ),
        if (topic.practiceQuestions.isNotEmpty) _buildPracticeButton(context),
        _StatusCard(topic: topic),
      ]),
    );
  }
}

/// Lists each word with its plain meaning.
class _KeyTermsList extends StatelessWidget {
  const _KeyTermsList({required this.terms});

  final List<KeyTerm> terms;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final term in terms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(term.term, style: textTheme.titleMedium),
                Text(term.meaning, style: textTheme.bodyLarge),
              ],
            ),
          ),
      ],
    );
  }
}

/// Makes the memory hook stand out.
class _MemoryHookCard extends StatelessWidget {
  const _MemoryHookCard({required this.hook});

  final String hook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Memory hook', style: textTheme.titleMedium?.copyWith(color: AppColors.amber)),
          const SizedBox(height: 6),
          Text(hook, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Lets the learner set the status and shows the date covered.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final progress = store.progressOf(topic.id);
    final coveredText = progress.coveredOn == null
        ? 'Not covered yet'
        : formatDate(progress.coveredOn!);
    return SectionCard(
      title: 'How well do you know this?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final status in TopicStatus.values)
              ChoiceChip(
                label: Text(status.label),
                selected: progress.status == status,
                onSelected: (_) => store.setStatus(topic.id, status),
              ),
          ]),
          const SizedBox(height: 12),
          Text('Date covered: $coveredText', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
