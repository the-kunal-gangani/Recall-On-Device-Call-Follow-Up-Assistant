// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());
    expect(find.text('Recall'), findsOneWidget);
  });
}
