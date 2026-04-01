// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in the app, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/di/service_locator.dart';

import 'package:syntrak/main.dart';

void main() {
  setUp(() async {
    // Mock SharedPreferences to prevent timeout timers
    // This makes SharedPreferences.getInstance() return immediately
    SharedPreferences.setMockInitialValues({});
    sl.reset();
    await setupServiceLocatorWithEnvironment(environment: AppEnvironment.dev);
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SyntrakApp());

    // Avoid pumpAndSettle because periodic polling timers keep the app "busy".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify that the app loads (check for MaterialApp)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
