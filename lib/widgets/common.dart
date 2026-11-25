import 'package:flutter/material.dart';

import '../models/progress.dart';
import '../models/study_content.dart';
import '../services/speech_service.dart';
import '../theme.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Writes a date the way people say it, such as "1 Mar 2027".
String formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// A calm reading-aloud pace, used to estimate how long notes take to hear.
const spokenWordsPerMinute = 130;

/// Writes a length of time as a clock, such as "2:59:41".
String formatClock(Duration time) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final minutes = twoDigits(time.inMinutes.remainder(60));
  final seconds = twoDigits(time.inSeconds.remainder(60));
  return '${time.inHours}:$minutes:$seconds';
}

/// A white block with a heading, used on most screens.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// A coloured label that shows a topic's status at a glance.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final TopicStatus status;

  /// Picks the label's colours from the status.
  (Color, Color) get _colors => switch (status) {
        TopicStatus.notStarted => (AppColors.line, AppColors.inkSoft),
        TopicStatus.learning => (AppColors.amberSoft, AppColors.amber),
        TopicStatus.revised => (AppColors.evergreenSoft, AppColors.evergreen),
        TopicStatus.confident => (AppColors.good, Colors.white),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

/// A bullet list of short lines.
class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(fontSize: 18, color: AppColors.amber)),
                Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shows note text: plain paragraphs, and bullets for lines starting with "- ".
class NoteBody extends StatelessWidget {
  const NoteBody(this.text, {super.key});

  final String text;

  /// Draws one paragraph, as bullets when its lines start with "- ".
  Widget _buildParagraph(BuildContext context, String paragraph) {
    final lines = paragraph.split('\n');
    final isBulletBlock = lines.every((line) => line.trimLeft().startsWith('- '));
    if (isBulletBlock) {
      return BulletList([for (final line in lines) line.trimLeft().substring(2)]);
    }
    return Text(paragraph, style: Theme.of(context).textTheme.bodyLarge);
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n\n').where((part) => part.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildParagraph(context, paragraph),
          ),
      ],
    );
  }
}

/// One short lesson part, with its length and its own Listen button.
class LessonPartCard extends StatelessWidget {
  const LessonPartCard({
    super.key,
    required this.label,
    required this.section,
    required this.speech,
  });

  final String label;
  final NoteSection section;
  final SpeechService speech;

  /// Estimates how long the part takes to hear, and is never under 1 minute.
  int get _minutes {
    final words = section.body.split(RegExp(r'\s+')).length;
    return (words / spokenWordsPerMinute).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('$label  ·  about $_minutes min', style: textTheme.bodySmall)),
              TextButton.icon(
                onPressed: () => speech.read([section.heading, section.body]),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Listen'),
              ),
            ]),
            Text(section.heading, style: textTheme.titleMedium),
            const SizedBox(height: 10),
            NoteBody(section.body),
          ],
        ),
      ),
    );
  }
}

/// A screen body that scrolls and keeps even gaps between its blocks.
class ScreenList extends StatelessWidget {
  const ScreenList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) => children[index],
    );
  }
}
