import 'package:flutter/material.dart';

import '../models/study_content.dart';
import '../services/speech_service.dart';
import '../widgets/common.dart';

/// A spoken recap of a whole domain, to use before its quiz.
class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key, required this.domain});

  final Domain domain;

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  final SpeechService _speech = SpeechService.instance;

  /// Stops reading when the learner leaves the review.
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  /// Starts or stops reading the whole review aloud.
  void _toggleReading() {
    if (_speech.isReading) {
      _speech.stop();
      return;
    }
    _speech.read([
      for (final item in widget.domain.reviewSession) ...[item.heading, item.body],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.domain.reviewSession;
    return Scaffold(
      appBar: AppBar(
        title: Text('Domain ${widget.domain.number} review'),
        actions: [
          ListenableBuilder(
            listenable: _speech,
            builder: (_, __) => TextButton(
              onPressed: _toggleReading,
              child: Text(_speech.isReading ? 'Stop' : 'Read all'),
            ),
          ),
        ],
      ),
      body: ScreenList(children: [
        Text(widget.domain.name, style: Theme.of(context).textTheme.headlineMedium),
        for (var index = 0; index < items.length; index++)
          LessonPartCard(
            label: 'Review ${index + 1} of ${items.length}',
            section: items[index],
            speech: _speech,
          ),
      ]),
    );
  }
}
