// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Login screen UI loads', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Check for app title
    expect(find.text('DORM FIX'), findsOneWidget);

    // Check for subtitle
    expect(find.text('Maintenance Request System'), findsOneWidget);

    // Check for Sign In card title
    expect(find.text('Sign In'), findsOneWidget);

    // Check for username and password fields
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Check for SIGN IN button
    expect(find.widgetWithText(ElevatedButton, 'SIGN IN'), findsOneWidget);

    // Check for Test Accounts info
    expect(find.text('Test Accounts'), findsOneWidget);
    expect(find.text('Admin: admin / admin123'), findsOneWidget);
    expect(find.text('Staff: staff1 / staff123'), findsOneWidget);
  });
}
