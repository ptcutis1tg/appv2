import 'package:flutter_test/flutter_test.dart';
import 'package:appv2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFinanceApp());
    expect(find.text('Real-time Ledger'), findsOneWidget);
  });
}
