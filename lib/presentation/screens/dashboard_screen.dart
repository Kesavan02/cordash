import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/resampling_service.dart';
import '../providers/health_dashboard_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/chart_container.dart';
import '../widgets/header_cards.dart';
import '../widgets/hr_chart_painter.dart';
import '../widgets/performance_hud_overlay.dart';
import '../widgets/steps_chart_painter.dart';
import 'permissions_screen.dart';

/// Main health dashboard displaying live metrics, interactive 60 FPS charts,
/// and the performance diagnostics overlay.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PerformanceHudOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0E17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111422),
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF00E5FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CorDash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            // Simulation toggle / stop button
            Consumer<HealthDashboardProvider>(
              builder: (context, dashboard, _) {
                final isSim = dashboard.isSimulating;
                if (isSim) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0x33FF2A6D),
                        foregroundColor: const Color(0xFFFF2A6D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFFF2A6D), width: 1.2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 18, color: Color(0xFFFF2A6D)),
                      label: const Text(
                        'STOP SIM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        dashboard.toggleSimulation(false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 2),
                            content: Text('SimSource stopped. Switched to Health Connect.'),
                          ),
                        );
                      },
                    ),
                  );
                }

                return IconButton(
                  tooltip: 'Start SimSource Live Demo',
                  icon: const Icon(Icons.sensors_rounded, color: Colors.white54),
                  onPressed: () {
                    dashboard.toggleSimulation(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 2),
                        content: Text('SimSource synthetic data stream enabled'),
                      ),
                    );
                  },
                );
              },
            ),

            // Permissions screen action
            Consumer<PermissionProvider>(
              builder: (context, perm, _) {
                final allGranted = perm.allGranted;
                return IconButton(
                  tooltip: 'Permissions',
                  icon: Icon(
                    allGranted ? Icons.verified_user_rounded : Icons.shield_outlined,
                    color: allGranted ? const Color(0xFF00E5FF) : const Color(0xFFFF9100),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PermissionsScreen(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<HealthDashboardProvider>().refresh();
                      context.read<PermissionProvider>().checkCurrentStatus();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer2<HealthDashboardProvider, PermissionProvider>(
          builder: (context, dashboard, perm, _) {
            if (dashboard.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                ),
              );
            }

            final timeFormat = DateFormat('HH:mm:ss');

            return RefreshIndicator(
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF161823),
              onRefresh: () async {
                await dashboard.refresh();
                await perm.checkCurrentStatus();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Active Simulation Banner with Stop Button
                  if (dashboard.isSimulating)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFF2A6D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stream_rounded, color: Color(0xFFFF2A6D), size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SimSource Simulation Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Streaming live walking steps & BPM',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF2A6D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 16),
                            label: const Text(
                              'STOP',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: () => dashboard.toggleSimulation(false),
                          ),
                        ],
                      ),
                    ),

                  // Permission Warning Banner if not granted
                  if (!perm.allGranted && !dashboard.isSimulating)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x33FF9100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF9100).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFF9100), size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Health Connect permissions not fully granted.',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PermissionsScreen(),
                                ),
                              );
                              if (context.mounted) {
                                context.read<HealthDashboardProvider>().refresh();
                                context.read<PermissionProvider>().checkCurrentStatus();
                              }
                            },
                            child: const Text(
                              'GRANT',
                              style: TextStyle(
                                color: Color(0xFFFF9100),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (dashboard.steps.isEmpty && !dashboard.isSimulating)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x1F00E5FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Health Connect Connected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Permissions are active! Health Connect has 0 step records logged today (requires Google Fit or a fitness app to log sensor walks).',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text(
                              'START LIVE DEMO STREAM (SIMSOURCE)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => dashboard.toggleSimulation(true),
                          ),
                        ],
                      ),
                    ),

                  // Header Cards (Steps & Heart Rate)
                  HeaderCards(
                    totalSteps: dashboard.todayTotalSteps,
                    latestBpm: dashboard.latestHeartRate?.bpm,
                    heartRateAge: dashboard.heartRateAge,
                  ),

                  // Steps Chart Section (Weekly 7-day Daily View)
                  ChartContainer(
                    title: 'STEPS ACTIVITY',
                    subtitle: '${NumberFormat('#,###').format(dashboard.todayTotalSteps)} steps today',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1F00E5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        '7 DAYS',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    onTooltipQuery: (normX) {
                      final displaySteps = dashboard.weeklySteps;
                      if (displaySteps.isEmpty) return null;
                      final index = (normX * (displaySteps.length - 1)).round();
                      final rec = displaySteps[index];
                      final isToday = index == displaySteps.length - 1;
                      final dayName = isToday
                          ? 'Today'
                          : DateFormat('EEEE, MMM d').format(rec.startTime);
                      if (rec.count == 0) {
                        return '$dayName: No steps recorded';
                      }
                      return '$dayName: ${NumberFormat('#,###').format(rec.count)} steps';
                    },
                    painterBuilder: (context, selectedNormX) {
                      return CustomPaint(
                        painter: StepsChartPainter(
                          records: dashboard.weeklySteps,
                          selectedNormalizedX: selectedNormX,
                          primaryColor: const Color(0xFF00E5FF),
                        ),
                      );
                    },
                  ),

                  // Heart Rate Chart Section
                  Builder(
                    builder: (context) {
                      // Apply LTTB point decimation to ensure <= 300 points for smooth 60fps rendering
                      final decimatedHr = ResamplingService.downsampleHeartRateRecords(
                        dashboard.heartRates,
                        AppConstants.maxChartDecimationPoints,
                      );

                      final currentBpm = dashboard.latestHeartRate?.bpm;

                      return ChartContainer(
                        title: 'HEART RATE TREND',
                        subtitle: currentBpm != null ? '$currentBpm BPM' : '-- BPM',
                        trailing: const Icon(
                          Icons.show_chart_rounded,
                          color: Color(0xFFFF3366),
                        ),
                        onTooltipQuery: (normX) {
                          if (decimatedHr.isEmpty) return null;
                          final index = (normX * (decimatedHr.length - 1)).round();
                          final rec = decimatedHr[index];
                          return '${rec.bpm} BPM at ${timeFormat.format(rec.timestamp)}';
                        },
                        painterBuilder: (context, selectedNormX) {
                          return CustomPaint(
                            painter: HeartRateChartPainter(
                              records: decimatedHr,
                              selectedNormalizedX: selectedNormX,
                              primaryColor: const Color(0xFFFF3366),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
