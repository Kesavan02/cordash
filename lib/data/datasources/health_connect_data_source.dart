import 'dart:async';
import 'dart:math' as math;
import 'package:health/health.dart';
import '../../domain/entities/heart_rate_record_entity.dart';
import '../../domain/entities/permission_status_entity.dart';
import '../../domain/entities/step_record_entity.dart';

/// Data source interacting with Android Health Connect via the `health` package,
/// with integrated synthetic simulation fallback (`SimSource`).
class HealthConnectDataSource {
  final Health _health = Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  final _stepStreamController = StreamController<StepRecordEntity>.broadcast();
  final _hrStreamController = StreamController<HeartRateRecordEntity>.broadcast();

  Timer? _pollingTimer;
  Timer? _simTimer;
  bool _isSimulating = false;
  int _simStepAccumulator = 2340;
  final math.Random _random = math.Random();

  Stream<StepRecordEntity> get stepsStream => _stepStreamController.stream;
  Stream<HeartRateRecordEntity> get heartRateStream => _hrStreamController.stream;
  int get simulatedStepTotal => _simStepAccumulator;

  HealthConnectDataSource() {
    _initHealth();
  }

  Future<void> _initHealth() async {
    try {
      await _health.configure();
    } catch (_) {
      // Configuration fallback for environments without Health Connect support
    }
  }

  /// Checks whether Health Connect is available on the device.
  Future<bool> isHealthConnectInstalled() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Play Store to install or update Health Connect.
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (_) {}
  }

  /// Checks Health Connect authorization status for Steps and Heart Rate.
  Future<PermissionStatusEntity> checkPermissions() async {
    try {
      final bool isAvailable = await isHealthConnectInstalled();
      if (!isAvailable) {
        return const PermissionStatusEntity(
          stepsGranted: false,
          heartRateGranted: false,
          canRequestAgain: true,
          isHealthConnectAvailable: false,
        );
      }

      final bool? stepsGranted = await _health.hasPermissions([HealthDataType.STEPS]);
      final bool? hrGranted = await _health.hasPermissions([HealthDataType.HEART_RATE]);

      final allGranted = (stepsGranted ?? false) && (hrGranted ?? false);
      if (allGranted && _pollingTimer == null && !_isSimulating) {
        startPolling();
      }

      return PermissionStatusEntity(
        stepsGranted: stepsGranted ?? false,
        heartRateGranted: hrGranted ?? false,
        canRequestAgain: true,
        isHealthConnectAvailable: true,
      );
    } catch (_) {
      return const PermissionStatusEntity(
        stepsGranted: false,
        heartRateGranted: false,
        canRequestAgain: true,
        isHealthConnectAvailable: false,
      );
    }
  }

  /// Launches the Health Connect permission request sheet.
  Future<PermissionStatusEntity> requestPermissions() async {
    try {
      final bool isAvailable = await isHealthConnectInstalled();
      if (!isAvailable) {
        await installHealthConnect();
        return const PermissionStatusEntity(
          stepsGranted: false,
          heartRateGranted: false,
          canRequestAgain: true,
          isHealthConnectAvailable: false,
        );
      }

      final bool authorized = await _health.requestAuthorization(
        _dataTypes,
        permissions: const [HealthDataAccess.READ, HealthDataAccess.READ],
      );
      if (authorized) {
        startPolling();
      }
      return await checkPermissions();
    } catch (_) {
      return await checkPermissions();
    }
  }

  /// Fetches cumulative or sampled steps from today (midnight to now).
  Future<List<StepRecordEntity>> fetchTodaySteps() async {
    if (_isSimulating) {
      final now = DateTime.now();
      final records = <StepRecordEntity>[];
      int accumulated = 0;
      for (int i = 12; i >= 1; i--) {
        final stepCount = 220 + _random.nextInt(140);
        accumulated += stepCount;
        records.add(
          StepRecordEntity(
            id: 'sim_hist_step_${now.millisecondsSinceEpoch}_$i',
            count: stepCount,
            startTime: now.subtract(Duration(minutes: i * 5)),
            endTime: now.subtract(Duration(minutes: (i - 1) * 5)),
          ),
        );
      }
      _simStepAccumulator = accumulated;
      return records;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      final records = <StepRecordEntity>[];
      for (final point in healthData) {
        final val = point.value;
        int count = 0;
        if (val is NumericHealthValue) {
          count = val.numericValue.round();
        }
        records.add(
          StepRecordEntity(
            id: point.uuid,
            count: count,
            startTime: point.dateFrom,
            endTime: point.dateTo,
          ),
        );
      }

      if (records.isEmpty) {
        try {
          final totalSteps = await _health.getTotalStepsInInterval(startOfDay, now);
          if (totalSteps != null && totalSteps > 0) {
            records.add(
              StepRecordEntity(
                id: 'hc_aggregate_${now.millisecondsSinceEpoch}',
                count: totalSteps,
                startTime: startOfDay,
                endTime: now,
              ),
            );
          }
        } catch (_) {}
      }

      return records;
    } catch (_) {
      return [];
    }
  }

  /// Fetches recent heart rate readings within the specified [duration].
  Future<List<HeartRateRecordEntity>> fetchRecentHeartRates({
    Duration duration = const Duration(hours: 1),
  }) async {
    if (_isSimulating) {
      final now = DateTime.now();
      final records = <HeartRateRecordEntity>[];
      for (int i = 50; i >= 0; i--) {
        final time = now.subtract(Duration(seconds: i * 20));
        final bpm = 70 + _random.nextInt(16) + (i % 6);
        records.add(
          HeartRateRecordEntity(
            id: 'sim_hist_hr_${now.millisecondsSinceEpoch}_$i',
            bpm: bpm,
            timestamp: time,
          ),
        );
      }
      return records;
    }

    final now = DateTime.now();
    final startTime = now.subtract(duration);

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: now,
      );

      final records = <HeartRateRecordEntity>[];
      for (final point in healthData) {
        final val = point.value;
        int bpm = 0;
        if (val is NumericHealthValue) {
          bpm = val.numericValue.round();
        }
        records.add(
          HeartRateRecordEntity(
            id: point.uuid,
            bpm: bpm,
            timestamp: point.dateFrom,
          ),
        );
      }
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Starts polling Health Connect periodically for fresh data points.
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        final recentHr = await fetchRecentHeartRates(duration: const Duration(minutes: 2));
        if (recentHr.isNotEmpty && !_hrStreamController.isClosed) {
          _hrStreamController.add(recentHr.last);
        }
        final todaySteps = await fetchTodaySteps();
        if (todaySteps.isNotEmpty && !_stepStreamController.isClosed) {
          _stepStreamController.add(todaySteps.last);
        }
      } catch (_) {
        // Silently catch background foreground-caller exceptions
      }
    });
  }

  /// Enables or disables synthetic debug data simulation (`SimSource`).
  void setSimulationMode(bool enabled) {
    _isSimulating = enabled;
    _simTimer?.cancel();

    if (enabled) {
      _simTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();

        // Simulate random step increase
        final stepIncrement = _random.nextInt(8) + 2;
        _simStepAccumulator += stepIncrement;
        final simStep = StepRecordEntity(
          id: 'sim_step_${now.millisecondsSinceEpoch}',
          count: stepIncrement,
          startTime: now.subtract(const Duration(seconds: 5)),
          endTime: now,
        );
        if (!_stepStreamController.isClosed) {
          _stepStreamController.add(simStep);
        }

        // Simulate natural fluctuating BPM (68 - 92 bpm with smooth noise)
        final simBpm = 72 + _random.nextInt(15) + (_random.nextBool() ? 3 : -3);
        final simHr = HeartRateRecordEntity(
          id: 'sim_hr_${now.millisecondsSinceEpoch}',
          bpm: simBpm,
          timestamp: now,
        );
        if (!_hrStreamController.isClosed) {
          _hrStreamController.add(simHr);
        }
      });
    }
  }

  bool get isSimulating => _isSimulating;

  void dispose() {
    _pollingTimer?.cancel();
    _simTimer?.cancel();
    _stepStreamController.close();
    _hrStreamController.close();
  }
}
