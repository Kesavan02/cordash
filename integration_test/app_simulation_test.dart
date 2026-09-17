import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cordash/main.dart' as app;
import 'package:cordash/presentation/screens/dashboard_screen.dart';
import 'package:cordash/presentation/widgets/chart_container.dart';
import 'package:cordash/presentation/widgets/header_cards.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CorDash End-to-End Integration & Simulation Tests', () {
    testWidgets(
      'Launches CorDash, toggles SimSource streaming, tests gestures, and stops cleanly',
      (tester) async {
        // 1. Launch the application
        app.main();
        await tester.pumpAndSettle();

        // 2. Verify initial UI state
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(HeaderCards), findsOneWidget);
        expect(find.byType(ChartContainer), findsNWidgets(2));

        // Verify Performance HUD is active and floating
        expect(find.textContaining('BUILD'), findsOneWidget);
        expect(find.textContaining('PAINT'), findsOneWidget);

        // 3. Locate and tap the SimSource start button
        final startSimFinder = find.byTooltip('Start SimSource Live Demo');
        if (startSimFinder.evaluate().isNotEmpty) {
          await tester.tap(startSimFinder);
          await tester.pump();
        } else {
          final bannerButtonFinder = find.text(
            'START LIVE DEMO STREAM (SIMSOURCE)',
          );
          if (bannerButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(bannerButtonFinder);
            await tester.pump();
          }
        }

        // 4. Let the simulation stream run for 2 seconds
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // 5. Verify that the simulation banner / STOP SIM button is active
        expect(find.text('STOP SIM'), findsOneWidget);

        // 6. Test interactive touch & drag gestures across the Steps chart
        final stepsChartFinder = find.byType(ChartContainer).first;
        expect(stepsChartFinder, findsOneWidget);

        // Tap the chart to trigger tooltip
        await tester.tap(stepsChartFinder);
        await tester.pump();

        // Drag across the weekly steps chart to test live scrubbing
        await tester.drag(stepsChartFinder, const Offset(-100, 0));
        await tester.pump();

        // 7. Test interactive touch & drag gestures across the Heart Rate chart
        final hrChartFinder = find.byType(ChartContainer).last;
        expect(hrChartFinder, findsOneWidget);

        await tester.tap(hrChartFinder);
        await tester.pump();

        await tester.drag(hrChartFinder, const Offset(80, 0));
        await tester.pump();

        // 8. Stop the simulation
        final stopButtonFinder = find.text('STOP SIM');
        expect(stopButtonFinder, findsOneWidget);
        await tester.tap(stopButtonFinder);
        await tester.pumpAndSettle();

        // Verify simulation has stopped
        expect(find.text('STOP SIM'), findsNothing);
      },
    );
  });
}
