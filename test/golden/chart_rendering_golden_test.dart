import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/domain/entities/heart_rate_record_entity.dart';
import 'package:cordash/domain/entities/step_record_entity.dart';
import 'package:cordash/presentation/widgets/chart_container.dart';
import 'package:cordash/presentation/widgets/hr_chart_painter.dart';
import 'package:cordash/presentation/widgets/steps_chart_painter.dart';

void main() {
  group('Chart CustomPainter Visual Rendering Tests', () {
    testWidgets('StepsChartPainter renders empty state cleanly without exceptions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                height: 180,
                child: CustomPaint(
                  painter: StepsChartPainter(records: const []),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is StepsChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('StepsChartPainter renders bars with selection highlight',
        (tester) async {
      final now = DateTime(2026, 9, 17, 10, 0);
      final sampleSteps = List.generate(
        12,
        (i) => StepRecordEntity(
          id: 'step_$i',
          count: (i + 1) * 85,
          startTime: now.subtract(Duration(minutes: (12 - i) * 5)),
          endTime: now.subtract(Duration(minutes: (11 - i) * 5)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0C0E17),
            body: Center(
              child: SizedBox(
                width: 360,
                height: 180,
                child: CustomPaint(
                  painter: StepsChartPainter(
                    records: sampleSteps,
                    selectedNormalizedX: 0.5,
                    primaryColor: const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is StepsChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('HeartRateChartPainter renders smooth bezier curve and gradient fill',
        (tester) async {
      final now = DateTime(2026, 9, 17, 10, 0);
      final sampleHr = List.generate(
        25,
        (i) => HeartRateRecordEntity(
          id: 'hr_$i',
          bpm: 68 + (i % 6) * 3 + (i == 12 ? 25 : 0),
          timestamp: now.subtract(Duration(seconds: (25 - i) * 10)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0C0E17),
            body: Center(
              child: SizedBox(
                width: 360,
                height: 180,
                child: CustomPaint(
                  painter: HeartRateChartPainter(
                    records: sampleHr,
                    selectedNormalizedX: 0.7,
                    primaryColor: const Color(0xFFFF3366),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is HeartRateChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('ChartContainer handles tap gestures and updates tooltip query',
        (tester) async {
      String? queriedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartContainer(
              title: 'TEST CHART',
              subtitle: '1,200 units',
              onTooltipQuery: (normX) {
                queriedValue = 'NormX: ${(normX * 100).toInt()}%';
                return queriedValue;
              },
              painterBuilder: (context, normX) {
                return const SizedBox(width: 300, height: 160);
              },
            ),
          ),
        ),
      );

      expect(find.text('TEST CHART'), findsOneWidget);
      expect(find.text('1,200 units'), findsOneWidget);

      // Perform tap gesture on the chart area
      final gestureTarget = find.byType(GestureDetector).first;
      await tester.tap(gestureTarget);
      await tester.pump();

      expect(queriedValue, isNotNull);
    });
  });
}
