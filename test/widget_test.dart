import 'package:flutter_test/flutter_test.dart';
import 'package:showa_city/main.dart';

void main() {
  testWidgets('city screen shows resources and building controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('街づくり'), findsOneWidget);
    expect(find.text('dagashiya'), findsOneWidget);
    expect(find.text('放置収益を回収'), findsOneWidget);
  });
}
