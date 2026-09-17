import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/heart_rate_record_entity.dart';
import '../../domain/entities/step_record_entity.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/usecases/get_heart_rate_stream_usecase.dart';
import '../../domain/usecases/get_steps_stream_usecase.dart';

/// Presentation state provider managing real-time step and heart rate data,
/// cumulative metrics, and live timestamp freshness calculation.
class HealthDashboardProvider extends ChangeNotifier {
  final HealthRepository repository;
  final GetStepsStreamUseCase getStepsStream;
  final GetHeartRateStreamUseCase getHeartRateStream;

  StreamSubscription<StepRecordEntity>? _stepSub;
  StreamSubscription<HeartRateRecordEntity>? _hrSub;
  Timer? _ageTimer;

  final List<StepRecordEntity> _steps = [];
  final List<HeartRateRecordEntity> _heartRates = [];

  HeartRateRecordEntity? _latestHeartRate;
  int _todayTotalSteps = 0;
  String _heartRateAge = 'No data';
  bool _isLoading = true;

  HealthDashboardProvider({
    required this.repository,
    required this.getStepsStream,
    required this.getHeartRateStream,
  }) {
    _init();
  }

  List<StepRecordEntity> get steps => List.unmodifiable(_steps);
  List<HeartRateRecordEntity> get heartRates => List.unmodifiable(_heartRates);
  HeartRateRecordEntity? get latestHeartRate => _latestHeartRate;
  int get todayTotalSteps => _todayTotalSteps;
  String get heartRateAge => _heartRateAge;
  bool get isLoading => _isLoading;

  /// Returns 7 daily step records (past 6 days + today) for the weekly activity chart.
  /// Today's bar is dynamically bound to [todayTotalSteps], and past days reflect
  /// recorded historical steps or baseline activity.
  List<StepRecordEntity> get weeklySteps {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Group existing step records by calendar day
    final Map<int, int> dayStepsMap = {};
    for (final s in _steps) {
      final sDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      final daysAgo = todayMidnight.difference(sDate).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        dayStepsMap[daysAgo] = (dayStepsMap[daysAgo] ?? 0) + s.count;
      }
    }

    final result = <StepRecordEntity>[];
    for (int i = 6; i >= 0; i--) {
      final dayDate = todayMidnight.subtract(Duration(days: i));
      int count;
      if (i == 0) {
        // Today is always the live todayTotalSteps
        count = _todayTotalSteps;
      } else {
        // Past days: strictly use recorded steps; if none, it's 0 (empty)
        count = dayStepsMap[i] ?? 0;
      }

      result.add(
        StepRecordEntity(
          id: 'weekly_day_$i',
          count: count,
          startTime: dayDate,
          endTime: i == 0
              ? now
              : dayDate.add(
                  const Duration(hours: 23, minutes: 59, seconds: 59),
                ),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  bool get isSimulating {
    final repo = repository;
    if (repo is HealthRepositoryImpl) {
      return repo.isSimulating;
    }
    return false;
  }

  void _init() {
    // Initial fetch
    _loadHistoricalData();

    // Stream subscriptions
    _stepSub = getStepsStream().listen(_onNewStep);
    _hrSub = getHeartRateStream().listen(_onNewHeartRate);

    // Periodic freshness timer (updates "X seconds ago" label every second)
    _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateHeartRateAge();
    });
  }

  Future<void> _loadHistoricalData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final initialSteps = await repository.fetchTodaySteps();
      final initialHr = await repository.fetchRecentHeartRates(
        duration: const Duration(hours: 1),
      );

      if (isSimulating) {
        _steps.clear();
        _steps.addAll(initialSteps);
        _recalculateTotalSteps();

        _heartRates.clear();
        _heartRates.addAll(initialHr);
        _latestHeartRate = _heartRates.isNotEmpty ? _heartRates.last : null;
      } else {
        // In real mode, purge any synthetic simulated records
        _steps.removeWhere((s) => s.id.startsWith('sim_'));
        if (initialSteps.isNotEmpty) {
          _steps.clear();
          _steps.addAll(initialSteps);
        }
        _recalculateTotalSteps();

        _heartRates.removeWhere((hr) => hr.id.startsWith('sim_'));
        if (initialHr.isNotEmpty) {
          _heartRates.clear();
          _heartRates.addAll(initialHr);
          _latestHeartRate = _heartRates.last;
        } else if (_heartRates.isEmpty) {
          _latestHeartRate = null;
        }
      }
    } finally {
      _isLoading = false;
      _updateHeartRateAge();
      notifyListeners();
    }
  }

  void _onNewStep(StepRecordEntity step) {
    _steps.add(step);
    _recalculateTotalSteps();
    notifyListeners();
  }

  void _onNewHeartRate(HeartRateRecordEntity hr) {
    _heartRates.add(hr);
    _latestHeartRate = hr;
    _updateHeartRateAge();
    notifyListeners();
  }

  void _recalculateTotalSteps() {
    if (_steps.isEmpty) {
      _todayTotalSteps = 0;
      return;
    }
    // If an aggregate record exists (e.g., from Health Connect daily total), use it as the base
    final hasAggregate = _steps.any((s) => s.id.startsWith('hc_aggregate'));
    if (hasAggregate) {
      int aggregateMax = 0;
      int liveIncrements = 0;
      for (final s in _steps) {
        if (s.id.startsWith('hc_aggregate')) {
          if (s.count > aggregateMax) aggregateMax = s.count;
        } else {
          liveIncrements += s.count;
        }
      }
      _todayTotalSteps = aggregateMax + liveIncrements;
    } else {
      int total = 0;
      for (final s in _steps) {
        total += s.count;
      }
      _todayTotalSteps = total;
    }
  }

  void _updateHeartRateAge() {
    if (_latestHeartRate == null) {
      _heartRateAge = 'No data';
      return;
    }

    final diff = DateTime.now().difference(_latestHeartRate!.timestamp);
    if (diff.isNegative || diff.inSeconds < 3) {
      _heartRateAge = 'just now';
    } else if (diff.inSeconds < 60) {
      _heartRateAge = '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      _heartRateAge = '${diff.inMinutes}m ago';
    } else {
      _heartRateAge = '${diff.inHours}h ago';
    }
    notifyListeners();
  }

  /// Toggles synthetic data simulation mode for development/testing.
  /// Constraint: SimSource must be disabled in release builds.
  void toggleSimulation(bool enable) {
    if (kReleaseMode) return;
    final repo = repository;
    if (repo is HealthRepositoryImpl) {
      repo.setSimulationMode(enable);
      if (!enable) {
        // Immediately purge simulated records from local state
        _heartRates.removeWhere((hr) => hr.id.startsWith('sim_'));
        _latestHeartRate = _heartRates.isNotEmpty ? _heartRates.last : null;
        _steps.removeWhere((s) => s.id.startsWith('sim_'));
        _recalculateTotalSteps();
        _updateHeartRateAge();
        notifyListeners();
      }
      _loadHistoricalData();
    }
  }

  /// Refreshes historical data from repository.
  Future<void> refresh() => _loadHistoricalData();

  @override
  void dispose() {
    _stepSub?.cancel();
    _hrSub?.cancel();
    _ageTimer?.cancel();
    super.dispose();
  }
}
