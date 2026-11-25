import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../widgets/common.dart';
import 'domain_listen_screen.dart';
import 'exam_questions_screen.dart';
import 'review_session_screen.dart';
import 'topic_screen.dart';

/// One domain: its topics, then its exam-related questions.
class DomainScreen extends StatelessWidget {
  const DomainScreen({super.key, required this.domain});

  final Domain domain;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return Scaffold(
      appBar: AppBar(title: Text('Domain ${domain.number}')),
      body: ScreenList(children: [
        Text(domain.name, style: Theme.of(context).textTheme.headlineMedium),
        Text(domain.plainMeaning, style: Theme.of(context).textTheme.bodyLarge),
        FilledButton.icon(
          onPressed: () {
            final startPart = store.listeningPositionOf(domain.number);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DomainListenScreen(domain: domain, startPart: startPart),
            ));
          },
          icon: const Icon(Icons.headphones),
          label: const Text('Read this whole domain aloud'),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final topic in domain.topics)
              ListTile(
                title: Text('${topic.id}  ${topic.name}'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(store.progressOf(topic.id).status),
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TopicScreen(topic: topic))),
              ),
          ]),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExamQuestionsScreen(domain: domain))),
          child: const Text('Exam-Related Questions for This Domain'),
        ),
        if (domain.reviewSession.isNotEmpty)
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReviewSessionScreen(domain: domain))),
            child: const Text('Review session for this domain'),
          ),
      ]),
    );
  }
}
