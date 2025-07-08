// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poafix/models/user_model.dart';
import 'package:poafix/screens/home/home_screen.dart';

void main() {
  testWidgets('Home screen shows welcome message', (WidgetTester tester) async {
    final user = User(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      userType: 'client',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: user),
      ),
    );

    expect(find.text('Welcome back, Test User! 😊'), findsOneWidget);
  });
}
