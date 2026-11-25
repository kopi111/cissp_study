import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/progress_store.dart';
import '../services/study_planner.dart';
import '../widgets/common.dart';
import 'voice_screen.dart';

/// The week-by-week plan, which adjusts itself to the days left.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  static const _planner = StudyPlanner();
  static const _hourChoices = [1, 2, 3, 4];
  static const _textSizes = {'Normal': 1.0, 'Large': 1.2, 'Largest': 1.4};

  /// Asks for a new exam date and saves it.
  Future<void> _pickExamDate(BuildContext context, ProgressStore store) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: store.settings.examDate,
      firstDate: ProgressStore.today,
      lastDate: DateTime(2030),
    );
    if (chosen != null) await store.updateSettings(store.settings.copyWith(examDate: chosen));
  }

  /// Draws the exam date, study time and text size controls.
  Widget _buildSettings(BuildContext context, ProgressStore store) {
    final settings = store.settings;
    return SectionCard(
      title: 'My exam and study time',
      child: Column(children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Exam date'),
          subtitle: Text(formatDate(settings.examDate)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: () => _pickExamDate(context, store),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reading voice'),
          subtitle: Text(settings.voice.isPhoneDefault
              ? "Phone's normal voice"
              : '${settings.voice.accent} voice'),
          trailing: const Icon(Icons.record_voice_over_outlined),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const VoiceScreen())),
        ),
        Row(children: [
          const Expanded(child: Text('Hours a day')),
          DropdownButton<int>(
            value: settings.hoursPerDay,
            items: [
              for (final hours in _hourChoices)
                DropdownMenuItem(value: hours, child: Text('$hours')),
            ],
            onChanged: (hours) => store.updateSettings(settings.copyWith(hoursPerDay: hours)),
          ),
        ]),
        Row(children: [
          const Expanded(child: Text('Text size')),
          DropdownButton<double>(
            value: settings.textScale,
            items: [
              for (final size in _textSizes.entries)
                DropdownMenuItem(value: size.value, child: Text(size.key)),
            ],
            onChanged: (scale) => store.updateSettings(settings.copyWith(textScale: scale)),
          ),
        ]),
      ]),
    );
  }

  /// Draws one week of the plan.
  Widget _buildWeek(BuildContext context, int weekNumber, PlanWeek week) {
    final names = week.topics.map((topic) => '${topic.id} ${topic.name}').toList();
    return SectionCard(
      title: 'Week $weekNumber: from ${formatDate(week.startsOn)}',
      child: names.isEmpty
          ? Text('Catch up or revise.', style: Theme.of(context).textTheme.bodyLarge)
          : BulletList(names),
    );
  }

  /// Draws the revision month and what happens in it.
  Widget _buildRevisionCard(BuildContext context, PaceReport report) {
    return SectionCard(
      title: 'Revision: from ${formatDate(report.revisionStart)}',
      child: const BulletList([
        'Weeks 1 and 2: go through your revision queue and weak areas.',
        'Week 3: take one domain quiz a day.',
        'Week 4: mixed quizzes and rest. Sleep well before the exam.',
      ]),
    );
  }

  /// Draws the main exam facts.
  Widget _buildExamFacts() {
    return const SectionCard(
      title: 'Exam facts',
      child: BulletList([
        '100 to 150 questions in 3 hours.',
        'The test adapts to you, and you cannot go back to a question.',
        'You need 700 out of 1000 to pass.',
        'Think like a manager. People\'s safety always comes first.',
        'Check the current rules on the ISC2 website before exam day.',
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final today = ProgressStore.today;
    final report = _planner.assess(
      today: today,
      settings: store.settings,
      totalTopics: scope.library.topics.length,
      coveredTopics: store.coveredCount,
      coveredToday: store.coveredToday,
    );
    final remaining = _planner.nextTopics(
        scope.library.topics, store.topicProgress, count: report.remainingTopics);
    final weeks = _planner.weeklyPlan(remaining, today, report.learningDaysLeft);

    return ScreenList(children: [
      Text('My plan', style: Theme.of(context).textTheme.headlineMedium),
      _buildSettings(context, store),
      SectionCard(
        title: report.status.label,
        child: Text(_planner.catchUpAdvice(report, hoursPerDay: store.settings.hoursPerDay),
            style: Theme.of(context).textTheme.bodyLarge),
      ),
      for (var index = 0; index < weeks.length; index++)
        _buildWeek(context, index + 1, weeks[index]),
      _buildRevisionCard(context, report),
      _buildExamFacts(),
    ]);
  }
}
