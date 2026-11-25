import 'dart:async';

import 'package:cissp_study/app_scope.dart';
import 'package:cissp_study/main.dart';
import 'package:cissp_study/services/content_repository.dart';
import 'package:cissp_study/services/progress_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the phone's speech engine and records what it is asked.
class FakeSpeechEngine {
  final spoken = <String>[];
  final voicesSet = <Map<Object?, Object?>>[];
  Completer<int> speechInProgress = Completer<int>();

  static const _voices = [
    {'name': 'en-gb-a', 'locale': 'en-GB', 'network_required': '0', 'features': ''},
    {'name': 'en-us-b', 'locale': 'en-US', 'network_required': '1', 'features': ''},
    {'name': 'en-us-c', 'locale': 'en-US', 'network_required': '0', 'features': 'notInstalled'},
    {'name': 'fr-fr-d', 'locale': 'fr-FR', 'network_required': '0', 'features': ''},
  ];

  /// Answers each call. Each spoken piece waits until the test finishes it.
  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'getVoices':
        return _voices;
      case 'setVoice':
        voicesSet.add(call.arguments as Map<Object?, Object?>);
        return 1;
      case 'speak':
        spoken.add(call.arguments as String);
        speechInProgress = Completer<int>();
        return speechInProgress.future;
      case 'stop':
        if (!speechInProgress.isCompleted) speechInProgress.complete(1);
        return 1;
      default:
        return 1;
    }
  }
}

/// Starts the real app with real notes and the fake speech engine.
Future<ProgressStore> startApp(WidgetTester tester, FakeSpeechEngine engine) async {
  // Uses a very tall screen so whole pages are drawn without scrolling.
  tester.view.physicalSize = const Size(1200, 40000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), engine.handle);
  final store = await tester.runAsync(ProgressStore.open);
  final library = await tester.runAsync(const ContentRepository().load);
  await tester.pumpWidget(AppScope(library: library!, store: store!, child: const CisspStudyApp()));
  await tester.pumpAndSettle();
  return store;
}

/// Goes from the home screen to Domain 6's whole-domain reader.
Future<void> openDomainReader(WidgetTester tester) async {
  await tester.tap(find.text('Study'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('6. Security Assessment and Testing'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Read this whole domain aloud'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a domain is read topic by topic and ends with its review session', () async {
    final library = await const ContentRepository().load();
    for (final domain in library.domains) {
      final parts = domain.readAloudParts;
      expect(parts.first.title, 'In simple words');
      expect(parts.first.groupTitle, contains(domain.topics.first.id));
      expect(parts.last.groupTitle, 'Review session');
      final expectedParts = domain.reviewSession.length +
          domain.topics.fold<int>(0, (sum, topic) => sum + topic.noteSections.length + 2);
      expect(parts.length, expectedParts);
    }
  });

  testWidgets('whole-domain reading moves on by itself and remembers the place', (tester) async {
    final engine = FakeSpeechEngine();
    final store = await startApp(tester, engine);
    await openDomainReader(tester);
    expect(find.textContaining('Part 1 of'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(engine.spoken.first, contains('Next topic.'));
    expect(find.text('Stop'), findsOneWidget);

    // Finishing each spoken piece moves the reader along to the next part by itself.
    for (var finished = 0; store.listeningPositionOf(6) == 0 && finished < 20; finished++) {
      engine.speechInProgress.complete(1);
      await tester.pump();
    }
    expect(store.listeningPositionOf(6), 1);
    expect(find.textContaining('Part 2 of'), findsOneWidget);

    // Next jumps forward while still reading.
    await tester.tap(find.byTooltip('Next part'));
    await tester.pump();
    expect(store.listeningPositionOf(6), 2);
    expect(find.textContaining('Part 3 of'), findsOneWidget);

    // Stopping and leaving, then coming back, returns to the same part.
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read this whole domain aloud'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Part 3 of'), findsOneWidget);
  });

  testWidgets('only installed English voices are offered and the choice is kept', (tester) async {
    final engine = FakeSpeechEngine();
    final store = await startApp(tester, engine);
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reading voice'));
    await tester.pumpAndSettle();

    expect(find.text("Phone's normal voice"), findsOneWidget);
    expect(find.text('British voice 1'), findsOneWidget);
    expect(find.text('American voice 1'), findsOneWidget);
    expect(find.text('Needs internet'), findsOneWidget);
    expect(find.text('American voice 2'), findsNothing);
    expect(find.textContaining('French'), findsNothing);

    await tester.tap(find.text('British voice 1'));
    await tester.pump();
    await tester.pump();
    expect(engine.voicesSet.last['name'], 'en-gb-a');
    expect(store.settings.voice.name, 'en-gb-a');
    expect(engine.spoken.last, contains('how your lessons will sound'));

    // A later start reads the same voice back from what was saved.
    final reopened = await tester.runAsync(ProgressStore.open);
    expect(reopened!.settings.voice.name, 'en-gb-a');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });
}
