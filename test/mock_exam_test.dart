import 'package:cissp_study/app_scope.dart';
import 'package:cissp_study/main.dart';
import 'package:cissp_study/models/mock_exam.dart';
import 'package:cissp_study/models/study_content.dart';
import 'package:cissp_study/services/content_repository.dart';
import 'package:cissp_study/services/mock_exam_builder.dart';
import 'package:cissp_study/services/mock_exam_store.dart';
import 'package:cissp_study/services/progress_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the real app with real notes and goes to the mock exam page.
Future<(StudyLibrary, ProgressStore)> openMockExamPage(WidgetTester tester) async {
  // Uses a very tall screen so whole pages are drawn without scrolling.
  tester.view.physicalSize = const Size(1200, 40000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'), (call) async => 1);
  final store = await tester.runAsync(ProgressStore.open);
  final library = await tester.runAsync(const ContentRepository().load);
  await tester.pumpWidget(AppScope(library: library!, store: store!, child: const CisspStudyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Quiz'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Mock exam: 150 questions'));
  await tester.pumpAndSettle();
  return (library, store);
}

/// Picks option A of the question on screen and presses the given button.
Future<void> answerAndPress(WidgetTester tester, String buttonLabel) async {
  await tester.tap(find.textContaining('A.  '));
  await tester.pump();
  await tester.tap(find.text(buttonLabel));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the paper', () {
    late StudyLibrary library;

    setUpAll(() async => library = await const ContentRepository().load());

    test('has 150 different questions shared by exam weight', () {
      final counts = MockExamBuilder.questionCountsFor(library.domains);
      expect(counts.values.fold<int>(0, (sum, count) => sum + count), 150);
      for (final domain in library.domains) {
        expect(counts[domain.number]! - 150 * domain.weightPercent / 100, inInclusiveRange(-0.5, 1));
        expect(domain.allQuestions.length, greaterThanOrEqualTo(counts[domain.number]!));
      }
      final attempt = MockExamBuilder().startAttempt(library, DateTime(2027));
      expect(attempt.questionIds.toSet().length, 150);
      final perDomain = <int, int>{};
      for (final id in attempt.questionIds) {
        final number = library.domainNumberOf(library.questionById(id));
        perDomain[number] = (perDomain[number] ?? 0) + 1;
      }
      expect(perDomain, counts);
    });

    test('allows exactly 3 hours and then runs out', () {
      final start = DateTime(2027, 1, 1, 9);
      final attempt = MockExamBuilder().startAttempt(library, start);
      expect(attempt.timeLeftAt(start), const Duration(hours: 3));
      expect(attempt.isOutOfTimeAt(start.add(const Duration(hours: 2, minutes: 59))), isFalse);
      expect(attempt.isOutOfTimeAt(start.add(const Duration(hours: 3))), isTrue);
      expect(attempt.timeLeftAt(start.add(const Duration(hours: 4))), Duration.zero);
    });

    test('counts questions the clock ran out on as wrong', () {
      final attempt = MockExamBuilder().startAttempt(library, DateTime(2027));
      final firstQuestion = library.questionById(attempt.questionIds.first);
      attempt.answerCurrent(firstQuestion.correctIndex);
      final result = MockExamResult.mark(attempt, library);
      expect(result.correctCount, 1);
      expect(result.questionCount, 150);
      expect(result.answeredQuestions.length, 1);
      expect(result.missedQuestions.length, 149);
      expect(result.domainScores.fold<int>(0, (sum, s) => sum + s.questionCount), 150);
    });
  });

  group('sitting the exam', () {
    testWidgets('answers stay hidden, the whole paper is marked and the score is kept',
        (tester) async {
      final (_, store) = await openMockExamPage(tester);
      await tester.tap(find.text('Start mock exam'));
      await tester.pumpAndSettle();

      // Choosing an answer shows no reason until the exam is over.
      await tester.tap(find.textContaining('A.  '));
      await tester.pump();
      expect(find.text('Correct'), findsNothing);
      expect(find.textContaining('Not quite'), findsNothing);
      await tester.tap(find.text('Next'));
      await tester.pump();

      for (var position = 2; position < 150; position++) {
        expect(find.text('Question $position of 150'), findsOneWidget);
        await answerAndPress(tester, 'Next');
      }
      await answerAndPress(tester, 'Finish exam');
      await tester.pumpAndSettle();

      expect(find.textContaining('out of 150 correct'), findsOneWidget);
      expect(find.text('1. Security and Risk Management'), findsOneWidget);
      expect(store.quizTallies, isNotEmpty);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Your past scores'), findsOneWidget);
      expect(find.text('Start mock exam'), findsOneWidget);
    });

    testWidgets('leaving keeps the answers and continuing resumes the same place',
        (tester) async {
      await openMockExamPage(tester);
      await tester.tap(find.text('Start mock exam'));
      await tester.pumpAndSettle();
      await answerAndPress(tester, 'Next');
      await answerAndPress(tester, 'Next');
      expect(find.text('Question 3 of 150'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Next is question 3 of 150'), findsOneWidget);

      await tester.tap(find.text('Continue exam'));
      await tester.pumpAndSettle();
      expect(find.text('Question 3 of 150'), findsOneWidget);

      // Leaves the screen so its clock is stopped before the test ends.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
    });

    testWidgets('an exam whose time ran out while away is marked when reopened',
        (tester) async {
      final library = await tester.runAsync(const ContentRepository().load);
      final examStore = await tester.runAsync(MockExamStore.open);
      final started = DateTime.now().subtract(const Duration(hours: 4));
      await tester.runAsync(
          () => examStore!.saveAttempt(MockExamBuilder().startAttempt(library!, started)));

      await openMockExamPage(tester);
      expect(find.textContaining('Time is up'), findsOneWidget);
      await tester.tap(find.text('See your result'));
      await tester.pumpAndSettle();
      expect(find.text('0 out of 150 correct'), findsOneWidget);
    });
  });
}
