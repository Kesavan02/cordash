import 'package:flutter/material.dart';

/// Container with dark-theme styling, interactive touch gesture recognition,
/// and live tooltip inspection.
class ChartContainer extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, double? selectedNormalizedX) painterBuilder;
  final String? Function(double normalizedX)? onTooltipQuery;
  final Widget? trailing;

  const ChartContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.painterBuilder,
    this.onTooltipQuery,
    this.trailing,
  });

  @override
  State<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends State<ChartContainer> {
  double? _normalizedX;
  String? _tooltipText;

  void _onGestureUpdate(Offset localPosition, double width) {
    if (width <= 0) return;
    final normalized = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() {
      _normalizedX = normalized;
      if (widget.onTooltipQuery != null) {
        _tooltipText = widget.onTooltipQuery!(normalized);
      }
    });
  }

  void _onGestureEnd() {
    setState(() {
      _normalizedX = null;
      _tooltipText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161823),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),

          const SizedBox(height: 12),

          // Interactive Tooltip Banner (if active)
          if (_tooltipText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF23283A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                _tooltipText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Interactive Chart Canvas Area
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragDown: (details) =>
                    _onGestureUpdate(details.localPosition, chartWidth),
                onHorizontalDragUpdate: (details) =>
                    _onGestureUpdate(details.localPosition, chartWidth),
                onHorizontalDragEnd: (_) => _onGestureEnd(),
                onHorizontalDragCancel: () => _onGestureEnd(),
                onTapDown: (details) =>
                    _onGestureUpdate(details.localPosition, chartWidth),
                onTapUp: (_) => _onGestureEnd(),
                child: SizedBox(
                  width: chartWidth,
                  height: 180,
                  child: widget.painterBuilder(context, _normalizedX),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
