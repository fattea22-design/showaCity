import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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

  testWidgets('renders at iPhone and iPad widths without layout exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MyApp());
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
