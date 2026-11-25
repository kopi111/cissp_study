import 'package:cissp_study/app_scope.dart';
import 'package:cissp_study/main.dart';
import 'package:cissp_study/services/content_repository.dart';
import 'package:cissp_study/services/progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('study a topic, see the dashboard change, then take a quiz', (tester) async {
    // Uses a very tall screen so whole pages are drawn without scrolling.
    tester.view.physicalSize = const Size(1200, 40000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Pretends the phone's read-aloud engine and storage are there.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});

    // Loads the real notes and starts the real app.
    final store = await tester.runAsync(ProgressStore.open);
    final library = await tester.runAsync(const ContentRepository().load);
    await tester.pumpWidget(
        AppScope(library: library!, store: store!, child: const CisspStudyApp()));
    await tester.pumpAndSettle();

    // A new learner starts at zero with T01 next.
    expect(find.text('0% complete'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(find.textContaining('T01  '), findsOneWidget);

    // Opens T01 and checks the lesson parts are shown.
    await tester.tap(find.text('Study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Security and Risk Management'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('T01  '));
    await tester.pumpAndSettle();
    expect(find.text('In simple words'), findsOneWidget);
    expect(find.text('Memory hook'), findsOneWidget);
    expect(find.textContaining('Part 1 of 6'), findsOneWidget);
    expect(find.text('Practice: 10 more questions'), findsOneWidget);
    expect(find.text('Date covered: Not covered yet'), findsOneWidget);

    // Marks the topic as learning, and the date covered appears.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Date covered: Not covered yet'), findsNothing);
    expect(store.coveredCount, 1);

    // Goes back and starts a quiz on the covered topic.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz me: 5 mixed questions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Question 1 of'), findsOneWidget);

    // Answers the first question and checks the reason is revealed.
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.textContaining('A.  '));
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
    expect(store.quizTallies['T01']!.attempts, greaterThan(0));
  });
}
