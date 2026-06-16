import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/shared/widgets/gradient_button.dart';

void main() {
  testWidgets('GradientButton shows label and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientButton(
            label: 'Book Now',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Book Now'), findsOneWidget);
    await tester.tap(find.text('Book Now'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('GradientButton shows loading indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientButton(
            label: 'Loading',
            isLoading: true,
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
