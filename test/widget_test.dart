import 'package:flutter_test/flutter_test.dart';
import 'package:voiceguru/main.dart';

void main() {
  testWidgets('VoiceGuru app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceGuruApp());
    await tester.pumpAndSettle();

    // Verify the auth screen renders
    expect(find.text('VoiceGuru'), findsOneWidget);
    expect(find.text('Your AI Study Companion'), findsOneWidget);
  });
}
