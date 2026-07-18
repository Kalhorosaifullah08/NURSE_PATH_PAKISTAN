import 'package:flutter/foundation.dart';

import '../domain/models.dart';

class AppState extends ChangeNotifier {
  int selectedSemester = 1;
  bool guest = true;
  final Set<String> bookmarks = {};
  final Set<String> incorrect = {};
  final List<ProgressEvent> progress = [];
  final Map<int, Entitlement> entitlements = {};

  void chooseSemester(int value) {
    selectedSemester = value;
    notifyListeners();
  }

  void toggleBookmark(String id) {
    bookmarks.contains(id) ? bookmarks.remove(id) : bookmarks.add(id);
    notifyListeners();
  }

  void recordAnswer(Mcq question, int selected) {
    final correct = selected == question.correctIndex;
    if (!correct) incorrect.add(question.id);
    progress.add(ProgressEvent(
      id: '${question.id}-${DateTime.now().microsecondsSinceEpoch}',
      itemId: question.id,
      kind: 'mcq',
      occurredAt: DateTime.now().toUtc(),
      score: correct ? 1 : 0,
    ));
    notifyListeners();
  }

  void grantTestEntitlement(int semester) {
    entitlements[semester] = Entitlement(semester: semester, active: true, source: 'license-test');
    notifyListeners();
  }
}
