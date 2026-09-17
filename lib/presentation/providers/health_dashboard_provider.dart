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

      _steps.clear();
      _steps.addAll(initialSteps);
      _recalculateTotalSteps();

      _heartRates.clear();
      _heartRates.addAll(initialHr);
      if (_heartRates.isNotEmpty) {
        _latestHeartRate = _heartRates.last;
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
    // If records are cumulative intervals, sum count; if absolute, take maximum
    int total = 0;
    for (final s in _steps) {
      total += s.count;
    }
    _todayTotalSteps = total;
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
  void toggleSimulation(bool enable) {
    final repo = repository;
    if (repo is HealthRepositoryImpl) {
      repo.setSimulationMode(enable);
      notifyListeners();
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
