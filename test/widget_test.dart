import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/presentation/widgets/header_cards.dart';

void main() {
  testWidgets('HeaderCards displays steps and heart rate accurately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeaderCards(
            totalSteps: 5430,
            latestBpm: 82,
            heartRateAge: 'just now',
          ),
        ),
      ),
    );

    // Initial pump and settle for pulse animation controller
    await tester.pump();

    expect(find.text('5,430'), findsOneWidget);
    expect(find.text('82 BPM'), findsOneWidget);
    expect(find.text('just now'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}
