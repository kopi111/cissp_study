import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study_content.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Reads a whole domain aloud from start to finish and remembers the place.
class DomainListenScreen extends StatefulWidget {
  const DomainListenScreen({super.key, required this.domain, required this.startPart});

  final Domain domain;
  final int startPart;

  @override
  State<DomainListenScreen> createState() => _DomainListenScreenState();
}

class _DomainListenScreenState extends State<DomainListenScreen> {
  final SpeechService _speech = SpeechService.instance;
  late final List<ReadAloudPart> _parts = widget.domain.readAloudParts;
  late int _currentPart = widget.startPart < _parts.length ? widget.startPart : 0;

  /// Stops reading when the learner leaves. The place is already saved.
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  /// Total listening time for the domain, written like "3 h 20 min".
  String get _totalTimeLabel {
    final words = _parts.fold<int>(0, (sum, part) => sum + part.text.split(RegExp(r'\s+')).length);
    final minutes = words ~/ spokenWordsPerMinute;
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }

  /// Shows and saves the part being read now.
  void _showPart(int index) {
    if (!mounted) return;
    setState(() => _currentPart = index);
    AppScope.of(context).store.saveListeningPosition(widget.domain.number, index);
  }

  /// Reads from the given part to the end, and restarts the place when finished.
  Future<void> _playFrom(int index) async {
    final store = AppScope.of(context).store;
    final reachedEnd = await _speech.read(
      [for (final part in _parts) part.text],
      startAt: index,
      onPassageStarted: _showPart,
    );
    if (reachedEnd) await store.saveListeningPosition(widget.domain.number, 0);
  }

  /// Starts reading at the current part, or stops.
  void _togglePlaying() {
    _speech.isReading ? _speech.stop() : _playFrom(_currentPart);
  }

  /// Moves to a part, and keeps reading from there if reading already.
  void _jumpTo(int index) {
    if (index < 0 || index >= _parts.length) return;
    if (_speech.isReading) {
      _playFrom(index);
    } else {
      _showPart(index);
    }
  }

  /// Draws the current part and the player buttons, always at the top.
  Widget _buildPlayer() {
    final textTheme = Theme.of(context).textTheme;
    final part = _parts[_currentPart];
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Part ${_currentPart + 1} of ${_parts.length}  ·  whole domain about $_totalTimeLabel',
                style: textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(part.groupTitle, style: textTheme.bodyMedium),
            Text(part.title, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  /// Draws previous, play or stop, and next.
  Widget _buildControls() {
    return ListenableBuilder(
      listenable: _speech,
      builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(
          tooltip: 'Previous part',
          iconSize: 36,
          onPressed: () => _jumpTo(_currentPart - 1),
          icon: const Icon(Icons.skip_previous),
        ),
        FilledButton.icon(
          onPressed: _togglePlaying,
          icon: Icon(_speech.isReading ? Icons.stop : Icons.play_arrow),
          label: Text(_speech.isReading ? 'Stop' : 'Play'),
        ),
        IconButton(
          tooltip: 'Next part',
          iconSize: 36,
          onPressed: () => _jumpTo(_currentPart + 1),
          icon: const Icon(Icons.skip_next),
        ),
      ]),
    );
  }

  /// Draws one row of the list of parts. Tapping it moves there.
  Widget _buildPartRow(BuildContext context, int index) {
    final part = _parts[index];
    return ListTile(
      selected: index == _currentPart,
      selectedColor: AppColors.evergreen,
      title: Text(part.title),
      subtitle: Text(part.groupTitle),
      onTap: () => _jumpTo(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Domain ${widget.domain.number}: listen')),
      body: Column(children: [
        _buildPlayer(),
        Expanded(
          child: ListView.builder(itemCount: _parts.length, itemBuilder: _buildPartRow),
        ),
      ]),
    );
  }
}
