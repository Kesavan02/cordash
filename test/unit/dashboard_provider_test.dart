import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/domain/entities/heart_rate_record_entity.dart';
import 'package:cordash/domain/entities/step_record_entity.dart';
import 'package:cordash/domain/repositories/health_repository.dart';
import 'package:cordash/domain/usecases/get_heart_rate_stream_usecase.dart';
import 'package:cordash/domain/usecases/get_steps_stream_usecase.dart';
import 'package:cordash/presentation/providers/health_dashboard_provider.dart';

class MockHealthRepository implements HealthRepository {
  final _stepController = StreamController<StepRecordEntity>.broadcast();
  final _hrController = StreamController<HeartRateRecordEntity>.broadcast();

  @override
  Stream<StepRecordEntity> get stepsStream => _stepController.stream;

  @override
  Stream<HeartRateRecordEntity> get heartRateStream => _hrController.stream;

  @override
  Future<List<StepRecordEntity>> fetchTodaySteps() async => [
    StepRecordEntity(
      id: 'step_initial',
      count: 1200,
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<HeartRateRecordEntity>> fetchRecentHeartRates({
    Duration duration = const Duration(hours: 1),
  }) async => [
    HeartRateRecordEntity(
      id: 'hr_initial',
      bpm: 72,
      timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
    ),
  ];

  void emitStep(StepRecordEntity step) => _stepController.add(step);
  void emitHeartRate(HeartRateRecordEntity hr) => _hrController.add(hr);

  @override
  void dispose() {
    _stepController.close();
    _hrController.close();
  }
}

void main() {
  group('HealthDashboardProvider Tests', () {
    late MockHealthRepository repo;
    late GetStepsStreamUseCase getSteps;
    late GetHeartRateStreamUseCase getHr;
    late HealthDashboardProvider provider;

    setUp(() async {
      repo = MockHealthRepository();
      getSteps = GetStepsStreamUseCase(repo);
      getHr = GetHeartRateStreamUseCase(repo);
      provider = HealthDashboardProvider(
        repository: repo,
        getStepsStream: getSteps,
        getHeartRateStream: getHr,
      );
      // Wait for initial historical fetch to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      provider.dispose();
      repo.dispose();
    });

    test('Loads initial step and heart rate data correctly', () {
      expect(provider.isLoading, isFalse);
      expect(provider.steps.length, equals(1));
      expect(provider.todayTotalSteps, equals(1200));
      expect(provider.heartRates.length, equals(1));
      expect(provider.latestHeartRate?.bpm, equals(72));
    });

    test('Updates total steps on live step emission', () async {
      final now = DateTime.now();
      repo.emitStep(
        StepRecordEntity(
          id: 'step_live_1',
          count: 350,
          startTime: now.subtract(const Duration(minutes: 1)),
          endTime: now,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.steps.length, equals(2));
      expect(provider.todayTotalSteps, equals(1550));
    });

    test('Updates latest heart rate on live HR emission', () async {
      final now = DateTime.now();
      repo.emitHeartRate(
        HeartRateRecordEntity(id: 'hr_live_1', bpm: 88, timestamp: now),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.heartRates.length, equals(2));
      expect(provider.latestHeartRate?.bpm, equals(88));
      expect(provider.heartRateAge, equals('just now'));
    });
  });
}
