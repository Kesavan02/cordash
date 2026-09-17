import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_dashboard_provider.dart';
import '../providers/permission_provider.dart';

/// Screen allowing the user to view and manage Android Health Connect permissions.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111422),
        elevation: 0,
        title: const Text(
          'Health Permissions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<PermissionProvider>(
        builder: (context, perm, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Connect Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CorDash requires passive read access to your steps and heart rate records to render real-time dashboard analytics.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Permission ledger cards
                _buildPermissionTile(
                  icon: Icons.directions_walk_rounded,
                  name: 'Steps Records',
                  description: 'Access to step counter data and daily activity totals.',
                  isGranted: perm.stepsGranted,
                  color: const Color(0xFF00E5FF),
                ),

                const SizedBox(height: 14),

                _buildPermissionTile(
                  icon: Icons.favorite_rounded,
                  name: 'Heart Rate Records',
                  description: 'Access to sensor heart rate intervals and BPM trends.',
                  isGranted: perm.heartRateGranted,
                  color: const Color(0xFFFF2A6D),
                ),

                // Health Connect status banner if not available
                if (!perm.isHealthConnectAvailable) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x26FF9100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF9100).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF9100),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Health Connect Not Installed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'On Android 12, Google Health Connect is a standalone app from the Play Store required to grant permissions.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Action button (Grant or Install Health Connect)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: perm.allGranted
                          ? const Color(0xFF00E676)
                          : !perm.isHealthConnectAvailable
                              ? const Color(0xFFFF9100)
                              : const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: perm.isRequesting
                        ? null
                        : () async {
                            final success = await perm.requestAllPermissions();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'All permissions successfully granted!'
                                        : !perm.isHealthConnectAvailable
                                            ? 'Opening Google Play Store to install Health Connect...'
                                            : 'Some permissions were not granted in Health Connect.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: perm.isRequesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : Text(
                            perm.allGranted
                                ? 'PERMISSIONS GRANTED'
                                : !perm.isHealthConnectAvailable
                                    ? 'INSTALL HEALTH CONNECT (PLAY STORE)'
                                    : 'GRANT PERMISSIONS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Fallback simulation button
                Consumer<HealthDashboardProvider>(
                  builder: (context, dashboard, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E5FF),
                          side: BorderSide(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          dashboard.isSimulating
                              ? Icons.sensors_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          dashboard.isSimulating
                              ? 'SIMSOURCE ACTIVE • VIEW DASHBOARD'
                              : 'OR TEST WITH SIMSOURCE SYNTHETIC STREAM',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        onPressed: () {
                          if (!dashboard.isSimulating) {
                            dashboard.toggleSimulation(true);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String name,
    required String description,
    required bool isGranted,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161823),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isGranted ? const Color(0xFF00E676) : Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
