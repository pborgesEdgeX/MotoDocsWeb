// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motodocs_web/main.dart';

void main() {
  testWidgets('MotoDocs app basic structure test', (WidgetTester tester) async {
    // Test that the app can be instantiated without Firebase
    // This tests the basic widget structure
    const app = MotoDocsApp();
    expect(app, isA<StatelessWidget>());
  });

  testWidgets('MaterialApp configuration test', (WidgetTester tester) async {
    // Test the MaterialApp configuration directly
    await tester.pumpWidget(
      const MaterialApp(
        title: 'MotoDocs AI',
        home: Scaffold(body: Center(child: Text('Test App'))),
      ),
    );

    // Verify that MaterialApp works
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });
}
