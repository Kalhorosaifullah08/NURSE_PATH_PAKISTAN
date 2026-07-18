import 'dart:ui';

import 'package:nursepath_pakistan/data/sample_repository.dart';
import 'package:nursepath_pakistan/state/app_state.dart';
import 'package:nursepath_pakistan/main.dart' as student_app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records correct and incorrect learning events deterministically', () {
    final state = AppState();
    final question = SampleRepository.questions.first;
    state.recordAnswer(question, question.correctIndex);
    state.recordAnswer(question, 1);
    expect(state.progress.length, 2);
    expect(state.progress.first.score, 1);
    expect(state.progress.last.score, 0);
    expect(state.incorrect, contains(question.id));
  });

  test('test entitlement unlocks only requested semester', () {
    final state = AppState()..grantTestEntitlement(3);
    expect(state.entitlements[3]?.active, isTrue);
    expect(state.entitlements[1], isNull);
  });

  testWidgets('renders the desktop student dashboard without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const student_app.NursePathApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Build confidence for\nyour next clinical shift.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
