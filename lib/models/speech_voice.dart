/// One voice the phone can read aloud with.
class SpeechVoice {
  const SpeechVoice({required this.name, required this.locale, this.needsInternet = false});

  /// Stands for "whatever the phone uses normally", so nothing has to be null.
  static const phoneDefault = SpeechVoice(name: '', locale: '');

  static const _accents = {
    'en-US': 'American',
    'en-GB': 'British',
    'en-AU': 'Australian',
    'en-IN': 'Indian',
    'en-NG': 'Nigerian',
  };

  final String name;
  final String locale;
  final bool needsInternet;

  bool get isPhoneDefault => name.isEmpty;
  bool get isEnglish => locale.startsWith('en');

  /// A plain name for the accent, such as "British".
  String get accent => _accents[locale] ?? 'English ($locale)';

  /// Reads one voice from the details the phone reports.
  factory SpeechVoice.fromPlatform(Map<Object?, Object?> details) => SpeechVoice(
        name: details['name'] as String,
        locale: details['locale'] as String,
        needsInternet: details['network_required'] == '1',
      );
}
