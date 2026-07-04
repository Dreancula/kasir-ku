import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_ku/main.dart';

void main() {
  testWidgets('App dapat dibuka tanpa error', (WidgetTester tester) async {
    await tester.pumpWidget(const KasirApp());
    expect(find.byType(KasirApp), findsOneWidget);
  });
}
