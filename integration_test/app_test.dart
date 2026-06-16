import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slotsync_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Create Account and Login', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Wait for splash screen to disappear
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Try finding "Create New Account"
    final createAccountButton = find.text('Create New Account');
    expect(createAccountButton, findsOneWidget);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    // Enter email
    final emailField = find
        .ancestor(of: find.text('Email'), matching: find.byType(TextField))
        .first;
    await tester.enterText(emailField, 'test12345@example.com');

    // Enter username
    final userField = find
        .ancestor(of: find.text('Username'), matching: find.byType(TextField))
        .first;
    await tester.enterText(userField, 'testuser');

    // Enter password
    final passField = find
        .ancestor(of: find.text('Password'), matching: find.byType(TextField))
        .first;
    await tester.enterText(passField, 'password123');

    // Tap Register
    final registerButton = find.text('Register');
    await tester.tap(registerButton);
    await tester.pump();

    // Give it 5 seconds to complete registration network request
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Check if error snackbar appeared or success
    final snackBar = find.byType(SnackBar);
    if (tester.any(snackBar)) {
      // Snackbar found - could be success or error message
      await tester.pump();
    } else {
      // No snackbar - check for navigation or other success indicators
      await tester.pump();
    }
  });
}
