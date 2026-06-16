import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SlotSync app smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GradientButton(label: 'Get Started', onPressed: null),
          ),
        ),
      ),
    );

    expect(find.text('Get Started'), findsOneWidget);
  });
}
