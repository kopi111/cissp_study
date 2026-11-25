import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../services/progress_store.dart';
import '../services/study_planner.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'topic_screen.dart';
import 'update_screen.dart';

/// The tracker: where the learner stands and what to do next.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _planner = StudyPlanner();

  /// Works out today's numbers from the saved progress.
  PaceReport _buildReport(StudyLibrary library, ProgressStore store) => _planner.assess(
        today: ProgressStore.today,
        settings: store.settings,
        totalTopics: library.topics.length,
        coveredTopics: store.coveredCount,
        coveredToday: store.coveredToday,
      );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final library = scope.library;
    final report = _buildReport(library, store);
    final next = _planner.nextTopics(library.topics, store.topicProgress);
    final queue = _planner.revisionQueue(library.topics, store.topicProgress, ProgressStore.today);
    final weak = _planner.weakAreas(library.topics, store.quizTallies);

    return ScreenList(children: [
      _ExamHeader(report: report, examDate: store.settings.examDate),
      _CountsRow(report: report),
      FilledButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const UpdateScreen())),
        icon: const Icon(Icons.edit_note),
        label: const Text('Update my progress'),
      ),
      _TargetsCard(report: report, next: next, advice: _planner.catchUpAdvice(report, hoursPerDay: store.settings.hoursPerDay)),
      _TopicLinksCard(
        title: 'Next 3 topics to study',
        emptyMessage: 'You have covered every topic.',
        topics: next,
      ),
      _TopicLinksCard(
        title: 'Revision queue',
        emptyMessage: 'Nothing is due for revision today.',
        topics: [for (final item in queue) item.topic],
      ),
      _DomainQuestionsCard(library: library, store: store),
      _WeakAreasCard(weakAreas: weak),
    ]);
  }
}

/// Shows the exam date, days left, percent done and pace.
class _ExamHeader extends StatelessWidget {
  const _ExamHeader({required this.report, required this.examDate});

  final PaceReport report;
  final DateTime examDate;

  /// Picks the colour that matches the pace.
  Color get _paceColor => switch (report.status) {
        PaceStatus.onTrack => AppColors.good,
        PaceStatus.slightlyBehind => AppColors.warning,
        PaceStatus.behind => AppColors.bad,
      };

  @override
  Widget build(BuildContext context) {
    const onDark = TextStyle(color: Colors.white, fontSize: 17);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.evergreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CISSP exam: ${formatDate(examDate)}', style: onDark),
          const SizedBox(height: 4),
          Text('${report.daysLeft} days left',
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: report.percentComplete / 100,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: const Color(0xFFF2B35E),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('${report.percentComplete}% complete', style: onDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(report.status.label,
                  style: TextStyle(color: _paceColor, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Shows total, covered and remaining topics side by side.
class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.report});

  final PaceReport report;

  /// Draws one number with its label.
  Widget _tile(BuildContext context, String label, int value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(children: [
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _tile(context, 'Total topics', report.totalTopics),
      const SizedBox(width: 10),
      _tile(context, 'Covered', report.coveredTopics),
      const SizedBox(width: 10),
      _tile(context, 'Remaining', report.remainingTopics),
    ]);
  }
}

/// Shows today's target, this week's target and how to stay on track.
class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.report, required this.next, required this.advice});

  final PaceReport report;
  final List<Topic> next;
  final String advice;

  /// Says what is left to do today, in plain words.
  String get _todayText {
    if (report.remainingTopics == 0 && report.todayTarget == 0) return 'All topics covered.';
    if (report.todayRemaining == 0) return 'Done for today. Well done.';
    final firstTopic = next.isEmpty ? '' : ' Start with ${next.first.id}.';
    return '${report.todayRemaining} topic${report.todayRemaining == 1 ? '' : 's'} left today.$firstTopic';
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return SectionCard(
      title: 'Your targets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today: $_todayText', style: style),
          const SizedBox(height: 6),
          Text('This week: ${report.weekTarget} topics.', style: style),
          const SizedBox(height: 6),
          Text('New topics end on ${formatDate(report.revisionStart)}. The last 4 weeks are for revision.', style: style),
          const SizedBox(height: 10),
          Text(advice, style: style?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A card that lists topics. Tapping one opens its notes.
class _TopicLinksCard extends StatelessWidget {
  const _TopicLinksCard({required this.title, required this.emptyMessage, required this.topics});

  final String title;
  final String emptyMessage;
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: topics.isEmpty
          ? Text(emptyMessage, style: Theme.of(context).textTheme.bodyLarge)
          : Column(children: [
              for (final topic in topics)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${topic.id}  ${topic.name}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TopicScreen(topic: topic))),
                ),
            ]),
    );
  }
}

/// Shows how many exam-related questions are done in each domain.
class _DomainQuestionsCard extends StatelessWidget {
  const _DomainQuestionsCard({required this.library, required this.store});

  final StudyLibrary library;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Exam-related questions done',
      child: Column(children: [
        for (final domain in library.domains)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text('${domain.number}. ${domain.name}', style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(width: 10),
              Text('${store.answeredCountForDomain(domain.number)}/${domain.examQuestions.length}',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
      ]),
    );
  }
}

/// Lists the topics with the lowest quiz scores.
class _WeakAreasCard extends StatelessWidget {
  const _WeakAreasCard({required this.weakAreas});

  static const _mostShown = 5;

  final List<WeakArea> weakAreas;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Weak areas from your quizzes',
      child: weakAreas.isEmpty
          ? Text('No weak areas yet. They appear after you take quizzes.',
              style: Theme.of(context).textTheme.bodyLarge)
          : BulletList([
              for (final area in weakAreas.take(_mostShown))
                '${area.topic.id} ${area.topic.name}: '
                    '${area.tally.correct} of ${area.tally.attempts} right',
            ]),
    );
  }
}
