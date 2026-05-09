import 'package:flutter_test/flutter_test.dart';
import 'package:vaakya/main.dart';

void main() {
  testWidgets('Vaakya app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VaakyaApp());
    await tester.pumpAndSettle();

    // Verify the dashboard renders
    expect(find.text('Vaakya'), findsOneWidget);
  });
}
