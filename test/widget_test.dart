import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled1/app/app.dart';

void main() {
  testWidgets('AppRoot smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
