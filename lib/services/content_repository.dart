import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/study_content.dart';

/// Loads the study notes that ship inside the app.
class ContentRepository {
  const ContentRepository();

  static const domainCount = 8;

  /// Reads all 8 domain files, in order, into one library.
  Future<StudyLibrary> load() async {
    final domains = <Domain>[];
    for (var number = 1; number <= domainCount; number++) {
      final text = await rootBundle.loadString('assets/content/domain$number.json');
      domains.add(Domain.fromJson(jsonDecode(text) as Map<String, dynamic>));
    }
    return StudyLibrary(domains);
  }
}
