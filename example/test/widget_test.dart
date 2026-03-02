// Verifies the example app builds and shows attribution UI.
// We do not call Afflicate.init() so the test avoids platform channels and
// network. getAttribution() returns notAttributed before init, so the UI
// still shows "Attributed: false" and "Simulate Signup".

import 'package:affiliate_portal_sdk_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app shows attribution and Simulate Signup button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.textContaining('Attributed:'), findsOneWidget);
    expect(find.text('Simulate Signup'), findsOneWidget);
  });
}
