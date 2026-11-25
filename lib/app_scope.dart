import 'package:flutter/widgets.dart';

import 'models/study_content.dart';
import 'services/progress_store.dart';

/// Gives every screen access to the notes and the learner's progress.
class AppScope extends InheritedNotifier<ProgressStore> {
  const AppScope({
    super.key,
    required this.library,
    required ProgressStore store,
    required super.child,
  }) : super(notifier: store);

  final StudyLibrary library;

  ProgressStore get store => notifier!;

  /// Finds the scope and redraws the calling screen when progress changes.
  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;
}
