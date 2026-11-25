import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../widgets/common.dart';
import 'domain_screen.dart';

/// Lists the 8 CISSP domains with progress for each.
class DomainsScreen extends StatelessWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    /// Counts how many topics in a domain have been studied.
    int coveredIn(Domain domain) =>
        domain.topics.where((topic) => scope.store.progressOf(topic.id).isCovered).length;

    return ScreenList(children: [
      Text('Study the 8 domains', style: Theme.of(context).textTheme.headlineMedium),
      for (final domain in scope.library.domains)
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text('${domain.number}. ${domain.name}',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${coveredIn(domain)} of ${domain.topics.length} topics covered. '
              '${domain.weightPercent}% of the exam.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DomainScreen(domain: domain))),
          ),
        ),
    ]);
  }
}
