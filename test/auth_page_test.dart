import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation/auth/auth_page.dart';

void main() {
  testWidgets('auth form validates locally and switches to sign up', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: AuthPage(onExplore: () {})));

    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);

    await tester.ensureVisible(find.text('New to Seren? Create an account'));
    await tester.tap(find.text('New to Seren? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
  });
}
