import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'models/study_content.dart';
import 'screens/home_shell.dart';
import 'services/content_repository.dart';
import 'services/progress_store.dart';
import 'services/speech_service.dart';
import 'theme.dart';

/// Starts the app at once, so something is always on screen.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyAppLoader());
}

/// Everything the app must read before its first real screen.
class LoadedStudyData {
  const LoadedStudyData(this.store, this.library);

  final ProgressStore store;
  final StudyLibrary library;
}

/// Shows a loading screen, then the app, or a clear message if loading fails.
class StudyAppLoader extends StatefulWidget {
  const StudyAppLoader({super.key});

  @override
  State<StudyAppLoader> createState() => _StudyAppLoaderState();
}

class _StudyAppLoaderState extends State<StudyAppLoader> {
  static const _longestWait = Duration(seconds: 30);

  late final Future<LoadedStudyData> _loading = _load().timeout(_longestWait);

  /// Opens saved progress and the notes.
  Future<LoadedStudyData> _load() async {
    final store = await ProgressStore.open();
    final library = await const ContentRepository().load();
    // Not waited for, so a phone with no speech engine still opens the app.
    SpeechService.instance.useVoice(store.settings.voice);
    return LoadedStudyData(store, library);
  }

  /// Draws the screen shown while loading or after a failure.
  Widget _buildWaitingScreen(Widget content) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(body: Center(child: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoadedStudyData>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Keeps the technical detail in the log and the screen message short.
          debugPrint('CISSP Study failed to start: ${snapshot.error}');
          return _buildWaitingScreen(const Text('The study notes did not load. Close and reopen the app.'));
        }
        if (!snapshot.hasData) return _buildWaitingScreen(const CircularProgressIndicator());
        final data = snapshot.data!;
        return AppScope(library: data.library, store: data.store, child: const CisspStudyApp());
      },
    );
  }
}

/// The root of the app.
class CisspStudyApp extends StatelessWidget {
  const CisspStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = AppScope.of(context).store.settings.textScale;
    return MaterialApp(
      title: 'CISSP Study',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Applies the reading size the learner chose to every screen.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const HomeShell(),
    );
  }
}
