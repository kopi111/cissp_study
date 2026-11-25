import 'package:cissp_study/app_scope.dart';
import 'package:cissp_study/main.dart';
import 'package:cissp_study/models/study_content.dart';
import 'package:cissp_study/services/content_repository.dart';
import 'package:cissp_study/services/progress_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Finds which of the topic's practice questions is on the screen now.
PracticeQuestion questionOnScreen(List<PracticeQuestion> questions) {
  return questions.singleWhere((question) => find.text(question.prompt).evaluate().isNotEmpty);
}

void main() {
  testWidgets('answering a practice question keeps it on screen with its reason', (tester) async {
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

    // Opens the practice set for the first topic.
    await tester.tap(find.text('Study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Security and Risk Management'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('T01  '));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice: 10 more questions'));
    await tester.pumpAndSettle();

    // Remembers the question shown, then answers it.
    final practiceQuestions = library.domains.first.topics.first.practiceQuestions;
    final askedQuestion = questionOnScreen(practiceQuestions);
    await tester.tap(find.textContaining('A.  '));
    await tester.pumpAndSettle();

    // The same question stays, and the learner can read why the answer is right.
    expect(questionOnScreen(practiceQuestions), same(askedQuestion));
    expect(find.textContaining(askedQuestion.explanation), findsOneWidget);
  });
}
