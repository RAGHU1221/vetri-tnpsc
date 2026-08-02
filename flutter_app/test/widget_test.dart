import 'package:flutter_test/flutter_test.dart';
import 'package:vetri_tnpsc/main.dart';

void main() {
  testWidgets('VetriApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const VetriApp());
    await tester.pump();
    expect(find.byType(VetriApp), findsOneWidget);
  });
}
