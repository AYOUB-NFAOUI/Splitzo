import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitzo/main.dart';
import 'package:splitzo/result_screen.dart';

void main() {
  testWidgets('Splitzo smoke test - validation and navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitzoApp());

    // Verify app bar title
    expect(find.text('Splitzo'), findsOneWidget);

    // Verify tagline
    expect(find.text('Split the bill, not the friendship.'), findsOneWidget);

    // Verify Calculate button exists
    final calculateBtn = find.text('Calculate Split');
    expect(calculateBtn, findsOneWidget);

    // Tap calculate without entering bill -> shows validation error
    await tester.tap(calculateBtn);
    await tester.pump();
    expect(find.text('Please enter the bill total'), findsOneWidget);

    // Enter bill amount
    final billInput = find.byType(TextFormField);
    await tester.enterText(billInput, '100.00');
    await tester.pump();

    // Tap calculate with 100.00, default 15%, 1 person
    await tester.tap(calculateBtn);
    await tester.pumpAndSettle();

    // Verify we arrived at ResultScreen
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Splitzo Result'), findsOneWidget);

    // 100 + 15% tip = 115.00 / 1 = $115.00
    expect(find.text('\$115.00'), findsNWidgets(2)); // Hero card & Total with Tip

    // Tap New Calculation button to pop back
    await tester.tap(find.text('New Calculation'));
    await tester.pumpAndSettle();

    // Should be back on InputScreen
    expect(find.text('Calculate Split'), findsOneWidget);
  });
}
