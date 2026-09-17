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
            // Simulation toggle button
            Consumer<HealthDashboardProvider>(
              builder: (context, dashboard, _) {
                final isSim = dashboard.isSimulating;
                return IconButton(
                  tooltip: isSim ? 'Disable SimSource' : 'Enable SimSource',
                  icon: Icon(
                    isSim ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                    color: isSim ? const Color(0xFF00E676) : Colors.white38,
                  ),
                  onPressed: () {
                    dashboard.toggleSimulation(!isSim);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 2),
                        content: Text(
                          !isSim
                              ? 'SimSource synthetic data stream enabled'
                              : 'SimSource disabled, listening to Health Connect',
                        ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PermissionsScreen(),
                      ),
                    );
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PermissionsScreen(),
                                ),
                              );
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
                    ),

                  // Header Cards (Steps & Heart Rate)
                  HeaderCards(
                    totalSteps: dashboard.todayTotalSteps,
                    latestBpm: dashboard.latestHeartRate?.bpm,
                    heartRateAge: dashboard.heartRateAge,
                  ),

                  // Steps Chart Section
                  ChartContainer(
                    title: 'STEPS ACTIVITY',
                    subtitle: '${dashboard.todayTotalSteps} steps',
                    trailing: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF00E5FF),
                    ),
                    onTooltipQuery: (normX) {
                      if (dashboard.steps.isEmpty) return null;
                      final index = (normX * (dashboard.steps.length - 1)).round();
                      final rec = dashboard.steps[index];
                      return '${rec.count} steps at ${timeFormat.format(rec.endTime)}';
                    },
                    painterBuilder: (context, selectedNormX) {
                      return CustomPaint(
                        painter: StepsChartPainter(
                          records: dashboard.steps,
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
