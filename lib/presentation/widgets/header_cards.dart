import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Top metric cards displaying total daily steps and latest heart rate with live freshness age.
class HeaderCards extends StatefulWidget {
  final int totalSteps;
  final int? latestBpm;
  final String heartRateAge;
  final int dailyStepGoal;

  const HeaderCards({
    super.key,
    required this.totalSteps,
    required this.latestBpm,
    required this.heartRateAge,
    this.dailyStepGoal = 10000,
  });

  @override
  State<HeaderCards> createState() => _HeaderCardsState();
}

class _HeaderCardsState extends State<HeaderCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final progress = (widget.totalSteps / widget.dailyStepGoal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Steps Card
          Expanded(
            child: _buildMetricCard(
              title: 'STEPS TODAY',
              value: numberFormat.format(widget.totalSteps),
              subtitle: '${(progress * 100).toInt()}% of goal',
              icon: Icons.directions_walk_rounded,
              accentColor: const Color(0xFF00E5FF),
              gradientStart: const Color(0xFF00E5FF),
              gradientEnd: const Color(0xFF0072FF),
              extraWidget: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Heart Rate Card
          Expanded(
            child: _buildMetricCard(
              title: 'HEART RATE',
              value: widget.latestBpm != null ? '${widget.latestBpm} BPM' : '--',
              subtitle: widget.heartRateAge,
              icon: Icons.favorite_rounded,
              accentColor: const Color(0xFFFF2A6D),
              gradientStart: const Color(0xFFFF2A6D),
              gradientEnd: const Color(0xFF9B00E8),
              iconWidget: ScaleTransition(
                scale: _pulseAnimation,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF2A6D),
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color gradientStart,
    required Color gradientEnd,
    Widget? iconWidget,
    Widget? extraWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161823),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              iconWidget ??
                  Icon(
                    icon,
                    color: accentColor,
                    size: 22,
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (extraWidget != null) ...[
            const SizedBox(height: 8),
            extraWidget,
          ],
        ],
      ),
    );
  }
}
