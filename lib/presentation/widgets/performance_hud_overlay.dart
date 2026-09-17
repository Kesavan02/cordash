import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/performance_hud_provider.dart';

/// Floating Performance HUD overlay showing real-time frame build time,
/// raster time, and FPS to verify zero-allocation 60 FPS performance targets.
class PerformanceHudOverlay extends StatefulWidget {
  final Widget child;

  const PerformanceHudOverlay({
    super.key,
    required this.child,
  });

  @override
  State<PerformanceHudOverlay> createState() => _PerformanceHudOverlayState();
}

class _PerformanceHudOverlayState extends State<PerformanceHudOverlay> {
  Offset _position = const Offset(16, 60);
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Consumer<PerformanceHudProvider>(
          builder: (context, hud, _) {
            if (!hud.isVisible) return const SizedBox.shrink();

            final isBuildGood = hud.isBuildTimeWithinTarget;
            final statusColor = isBuildGood
                ? const Color(0xFF00E676)
                : const Color(0xFFFF9100);

            return Positioned(
              left: _position.dx,
              top: _position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                  });
                },
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE60A0C14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _isExpanded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing indicator dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _metricColumn(
                                label: 'BUILD',
                                value: '${hud.avgBuildTimeMs.toStringAsFixed(1)}ms',
                                color: statusColor,
                              ),
                              _divider(),
                              _metricColumn(
                                label: 'PAINT',
                                value: '${hud.avgRasterTimeMs.toStringAsFixed(1)}ms',
                                color: Colors.white70,
                              ),
                              _divider(),
                              _metricColumn(
                                label: 'FPS',
                                value: hud.fps.toStringAsFixed(0),
                                color: Colors.white,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${hud.fps.toStringAsFixed(0)} FPS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _metricColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white12,
    );
  }
}
