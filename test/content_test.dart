import 'dart:convert';
import 'dart:io';

import 'package:cissp_study/models/study_content.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads all 8 notes files straight from the project folder.
StudyLibrary loadLibrary() {
  return StudyLibrary([
    for (var number = 1; number <= 8; number++)
      Domain.fromJson(jsonDecode(File('assets/content/domain$number.json').readAsStringSync())
          as Map<String, dynamic>),
  ]);
}

/// Checks that a question has 4 different options and a real answer.
void expectValidQuestion(PracticeQuestion question) {
  expect(question.options.length, 4, reason: question.id);
  expect(question.options.toSet().length, 4, reason: '${question.id} repeats an option');
  expect(question.correctIndex, inInclusiveRange(0, 3), reason: question.id);
  expect(question.explanation.trim(), isNotEmpty, reason: question.id);
}

void main() {
  final library = loadLibrary();

  test('topics run from T01 to T73 with no gaps', () {
    final expected = [
      for (var n = 1; n <= 73; n++) 'T${n.toString().padLeft(2, '0')}',
    ];
    expect(library.topics.map((topic) => topic.id).toList(), expected);
  });

  test('domain weights add up to 100', () {
    final total = library.domains.fold<int>(0, (sum, d) => sum + d.weightPercent);
    expect(total, 100);
  });

  test('every topic has all of its parts', () {
    for (final topic in library.topics) {
      expect(topic.noteSections.length, inInclusiveRange(3, 6), reason: topic.id);
      expect(topic.keyTerms.length, inInclusiveRange(4, 10), reason: topic.id);
      expect(topic.keyPoints.length, inInclusiveRange(3, 5), reason: topic.id);
      expect(topic.memoryHook.trim(), isNotEmpty, reason: topic.id);
      expectValidQuestion(topic.question);
    }
  });

  test('every domain has 10 valid questions that test its own topics', () {
    for (final domain in library.domains) {
      expect(domain.examQuestions.length, 10, reason: 'Domain ${domain.number}');
      final ownTopicIds = domain.topics.map((topic) => topic.id).toSet();
      for (final question in domain.examQuestions) {
        expectValidQuestion(question);
        expect(question.testedTopicIds, isNotEmpty, reason: question.id);
        expect(ownTopicIds.containsAll(question.testedTopicIds), isTrue, reason: question.id);
      }
    }
  });

  test('deepened topics have short lesson parts and 10 extra questions', () {
    for (final topic in library.topics.where((t) => t.practiceQuestions.isNotEmpty)) {
      expect(topic.practiceQuestions.length, 10, reason: topic.id);
      expect(topic.noteSections.length, inInclusiveRange(5, 6), reason: topic.id);
      topic.practiceQuestions.forEach(expectValidQuestion);
      final allPrompts = {
        topic.question.prompt,
        ...topic.practiceQuestions.map((question) => question.prompt),
      };
      expect(allPrompts.length, 11, reason: '${topic.id} repeats a question');
    }
  });

  test('review sessions are a full recap when a domain has one', () {
    for (final domain in library.domains.where((d) => d.reviewSession.isNotEmpty)) {
      expect(domain.reviewSession.length, inInclusiveRange(8, 12), reason: 'Domain ${domain.number}');
    }
  });

  test('every topic is tested by at least one domain question', () {
    final tested = {
      for (final domain in library.domains)
        for (final question in domain.examQuestions) ...question.testedTopicIds,
    };
    final untested = library.topics.map((t) => t.id).where((id) => !tested.contains(id));
    expect(untested, isEmpty);
  });
}
