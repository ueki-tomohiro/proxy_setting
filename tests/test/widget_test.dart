import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tests/main.dart';

void main() {
  testWidgets('Network test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('400'), findsNothing);

    await tester.tap(find.byIcon(Icons.network_check));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(seconds: 5));
    });
    await tester.pump();

    expect(find.text('400'), findsOneWidget);
  });
}
