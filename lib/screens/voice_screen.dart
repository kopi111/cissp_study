import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/speech_voice.dart';
import '../services/speech_service.dart';
import '../widgets/common.dart';

/// Lists the phone's English voices. Tapping one plays it and keeps it.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  static const _sampleLine =
      'This is how your lessons will sound. Think like a manager, and keep people safe first.';

  final SpeechService _speech = SpeechService.instance;
  late final Future<List<SpeechVoice>> _loadingVoices = _speech.englishVoices();

  /// Stops the sample when the learner leaves this page.
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  /// Saves the voice, switches to it and plays a short sample.
  Future<void> _chooseVoice(SpeechVoice voice) async {
    final store = AppScope.of(context).store;
    await store.updateSettings(store.settings.copyWith(voice: voice));
    await _speech.useVoice(voice);
    await _speech.read([_sampleLine]);
  }

  /// Draws one voice, with a tick beside the one in use.
  Widget _buildVoice(SpeechVoice voice, String title) {
    final chosen = AppScope.of(context).store.settings.voice;
    return ListTile(
      leading: Icon(voice.name == chosen.name ? Icons.check_circle : Icons.volume_up_outlined),
      title: Text(title),
      subtitle: voice.needsInternet ? const Text('Needs internet') : null,
      onTap: () => _chooseVoice(voice),
    );
  }

  /// Numbers the voices within each accent, so that each has a plain name.
  List<Widget> _buildVoiceRows(List<SpeechVoice> voices) {
    final seenPerAccent = <String, int>{};
    return [
      for (final voice in voices)
        _buildVoice(voice,
            '${voice.accent} voice ${seenPerAccent[voice.accent] = (seenPerAccent[voice.accent] ?? 0) + 1}'),
    ];
  }

  /// Draws the list once the phone has reported its voices.
  Widget _buildPage(List<SpeechVoice> voices) {
    return ScreenList(children: [
      Text('Tap a voice to hear it. The last one you tap is used for your lessons.',
          style: Theme.of(context).textTheme.bodyLarge),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _buildVoice(SpeechVoice.phoneDefault, "Phone's normal voice"),
          ..._buildVoiceRows(voices),
        ]),
      ),
      Text('Want other accents? Download them in your phone\'s text-to-speech settings, '
          'then come back here.',
          style: Theme.of(context).textTheme.bodyMedium),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading voice')),
      body: FutureBuilder<List<SpeechVoice>>(
        future: _loadingVoices,
        builder: (_, snapshot) => snapshot.hasData
            ? _buildPage(snapshot.data!)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
