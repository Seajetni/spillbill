import 'package:flutter_test/flutter_test.dart';
import 'package:split_bill/main.dart';

void main() {
  testWidgets('SplitBillApp renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitBillApp());
    expect(find.text('ยอดสุทธิของคุณ'), findsOneWidget);
  });
}
