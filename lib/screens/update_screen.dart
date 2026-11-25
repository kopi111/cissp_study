import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/progress.dart';
import '../models/study_content.dart';
import '../widgets/common.dart';

/// Asks which topics were studied and how confident the learner feels.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  static const _confidenceChoices = [
    TopicStatus.learning,
    TopicStatus.revised,
    TopicStatus.confident,
  ];

  final Set<String> _selectedTopicIds = {};
  TopicStatus _confidence = TopicStatus.learning;

  /// Ticks or unticks a topic.
  void _toggleTopic(String topicId, bool isSelected) => setState(() {
        isSelected ? _selectedTopicIds.add(topicId) : _selectedTopicIds.remove(topicId);
      });

  /// Saves the ticked topics, then returns to the dashboard.
  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final savedCount = _selectedTopicIds.length;
    await AppScope.of(context).store.setStatusForTopics(_selectedTopicIds, _confidence);
    messenger.showSnackBar(SnackBar(content: Text('Saved $savedCount topics.')));
    navigator.pop();
  }

  /// Draws a domain heading with a tick box for each of its topics.
  Widget _buildDomainTicks(Domain domain) {
    final store = AppScope.of(context).store;
    return SectionCard(
      title: '${domain.number}. ${domain.name}',
      child: Column(children: [
        for (final topic in domain.topics)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedTopicIds.contains(topic.id),
            onChanged: (value) => _toggleTopic(topic.id, value ?? false),
            title: Text('${topic.id}  ${topic.name}'),
            subtitle: Text(store.progressOf(topic.id).status.label),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    return Scaffold(
      appBar: AppBar(title: const Text('Update my progress')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selectedTopicIds.isEmpty ? null : _save,
            child: Text('Save ${_selectedTopicIds.length} topics'),
          ),
        ),
      ),
      body: ScreenList(children: [
        SectionCard(
          title: 'How confident do you feel?',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final choice in _confidenceChoices)
              ChoiceChip(
                label: Text(choice.label),
                selected: _confidence == choice,
                onSelected: (_) => setState(() => _confidence = choice),
              ),
          ]),
        ),
        Text('Tick the topics you studied', style: Theme.of(context).textTheme.titleLarge),
        for (final domain in library.domains) _buildDomainTicks(domain),
      ]),
    );
  }
}
