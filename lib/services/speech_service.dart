import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/speech_voice.dart';

/// Reads the notes aloud. The rest of the app never talks to the plugin directly.
class SpeechService extends ChangeNotifier {
  SpeechService._() {
    _configure();
  }

  static final SpeechService instance = SpeechService._();

  /// Android refuses one long piece of text, so notes are read in short parts.
  static const _longestPassage = 3000;

  /// Android's mark on a voice that is listed but not downloaded.
  static const _notInstalledFeature = 'notInstalled';

  final FlutterTts _engine = FlutterTts();
  bool isReading = false;
  int _currentReading = 0;

  /// Sets a slow, clear voice and makes speak() wait until a part has finished.
  Future<void> _configure() async {
    await _engine.setSpeechRate(0.42);
    await _engine.setVolume(1.0);
    await _engine.awaitSpeakCompletion(true);
  }

  /// The English voices installed on this phone, grouped by accent.
  Future<List<SpeechVoice>> englishVoices() async {
    final reported = await _engine.getVoices as List<Object?>;
    final voices = reported
        .cast<Map<Object?, Object?>>()
        .where((details) => !'${details['features']}'.contains(_notInstalledFeature))
        .map(SpeechVoice.fromPlatform)
        .where((voice) => voice.isEnglish)
        .toList();
    return voices..sort((a, b) => '${a.locale}${a.name}'.compareTo('${b.locale}${b.name}'));
  }

  /// Switches voice. A phone that refuses keeps its normal voice and still reads.
  Future<void> useVoice(SpeechVoice voice) async {
    try {
      if (voice.isPhoneDefault) {
        await _engine.clearVoice();
      } else {
        await _engine.setVoice({'name': voice.name, 'locale': voice.locale});
      }
    } on Object catch (error) {
      debugPrint('CISSP Study could not switch voice: $error');
    }
  }

  /// Reads each passage in turn. Returns true only if it reached the very end.
  Future<bool> read(
    List<String> passages, {
    int startAt = 0,
    ValueChanged<int>? onPassageStarted,
  }) async {
    await stop();
    final thisReading = ++_currentReading;
    _setReading(true);
    for (var index = startAt; index < passages.length; index++) {
      if (thisReading != _currentReading) return false;
      onPassageStarted?.call(index);
      for (final part in _splitIntoParts(passages[index])) {
        if (thisReading != _currentReading) return false;
        await _engine.speak(part);
      }
    }
    if (thisReading != _currentReading) return false;
    _setReading(false);
    return true;
  }

  /// Stops reading straight away.
  Future<void> stop() async {
    _currentReading++;
    if (isReading) await _engine.stop();
    _setReading(false);
  }

  /// Breaks text at paragraph ends and keeps each part under the Android limit.
  Iterable<String> _splitIntoParts(String text) sync* {
    for (final paragraph in text.split('\n\n')) {
      final cleaned = paragraph.replaceAll('- ', '').trim();
      if (cleaned.isEmpty) continue;
      for (var start = 0; start < cleaned.length; start += _longestPassage) {
        final end = (start + _longestPassage).clamp(0, cleaned.length);
        yield cleaned.substring(start, end);
      }
    }
  }

  /// Records the reading state and redraws the read-aloud button.
  void _setReading(bool reading) {
    if (isReading == reading) return;
    isReading = reading;
    notifyListeners();
  }
}
