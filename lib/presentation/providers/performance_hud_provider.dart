import 'dart:collection';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Provider that tracks real-time frame timings (build duration, raster duration, FPS)
/// for the floating Performance HUD overlay.
class PerformanceHudProvider extends ChangeNotifier {
  static const int _windowSize = 60;

  final Queue<FrameTiming> _recentTimings = Queue<FrameTiming>();

  double _avgBuildTimeMs = 0.0;
  double _avgRasterTimeMs = 0.0;
  double _fps = 60.0;
  bool _isVisible = true;

  PerformanceHudProvider() {
    _initTimingListener();
  }

  double get avgBuildTimeMs => _avgBuildTimeMs;
  double get avgRasterTimeMs => _avgRasterTimeMs;
  double get fps => _fps;
  bool get isVisible => _isVisible;
  bool get isBuildTimeWithinTarget => _avgBuildTimeMs <= 8.0;

  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  void _initTimingListener() {
    // Only register frame timings if not running in a pure headless unit test environment
    try {
      WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    } catch (_) {
      // In headless test runners, WidgetsBinding may not have frame scheduler attached
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _recentTimings.addLast(timing);
      if (_recentTimings.length > _windowSize) {
        _recentTimings.removeFirst();
      }
    }

    if (_recentTimings.isNotEmpty) {
      double totalBuild = 0;
      double totalRaster = 0;
      double totalFrame = 0;

      for (final t in _recentTimings) {
        totalBuild += t.buildDuration.inMicroseconds / 1000.0;
        totalRaster += t.rasterDuration.inMicroseconds / 1000.0;
        totalFrame += t.totalSpan.inMicroseconds / 1000.0;
      }

      final count = _recentTimings.length;
      _avgBuildTimeMs = totalBuild / count;
      _avgRasterTimeMs = totalRaster / count;

      final avgTotalMs = totalFrame / count;
      if (avgTotalMs > 0) {
        _fps = (1000.0 / avgTotalMs).clamp(0.0, 120.0);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    } catch (_) {}
    super.dispose();
  }
}
