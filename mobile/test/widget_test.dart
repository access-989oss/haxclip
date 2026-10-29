import 'package:flutter_test/flutter_test.dart';
import 'package:haxclip/main.dart';

void main() {
  testWidgets('HaxClip app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HaxClipApp());
    expect(find.text('HaxClip'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
  });
}
