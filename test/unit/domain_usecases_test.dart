import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/domain/entities/step_record_entity.dart';
import 'package:cordash/domain/entities/heart_rate_record_entity.dart';
import 'package:cordash/domain/entities/permission_status_entity.dart';
import 'package:cordash/domain/repositories/health_repository.dart';
import 'package:cordash/domain/repositories/permission_repository.dart';
import 'package:cordash/domain/usecases/get_steps_stream_usecase.dart';
import 'package:cordash/domain/usecases/get_heart_rate_stream_usecase.dart';
import 'package:cordash/domain/usecases/check_permissions_usecase.dart';
import 'package:cordash/domain/usecases/request_permissions_usecase.dart';

class MockHealthRepository implements HealthRepository {
  final _stepController = StreamController<StepRecordEntity>.broadcast();
  final _hrController = StreamController<HeartRateRecordEntity>.broadcast();

  @override
  Stream<StepRecordEntity> get stepsStream => _stepController.stream;

  @override
  Stream<HeartRateRecordEntity> get heartRateStream => _hrController.stream;

  @override
  Future<List<StepRecordEntity>> fetchTodaySteps() async => [];

  @override
  Future<List<HeartRateRecordEntity>> fetchRecentHeartRates({
    Duration duration = const Duration(hours: 1),
  }) async => [];

  void emitStep(StepRecordEntity step) => _stepController.add(step);
  void emitHeartRate(HeartRateRecordEntity hr) => _hrController.add(hr);

  @override
  void dispose() {
    _stepController.close();
    _hrController.close();
  }
}

class MockPermissionRepository implements PermissionRepository {
  PermissionStatusEntity status = const PermissionStatusEntity(
    stepsGranted: false,
    heartRateGranted: false,
  );

  @override
  Future<PermissionStatusEntity> checkStatus() async => status;

  @override
  Future<PermissionStatusEntity> requestAccess() async {
    status = const PermissionStatusEntity(
      stepsGranted: true,
      heartRateGranted: true,
    );
    return status;
  }
}

void main() {
  group('Domain Entities & Use Cases', () {
    late MockHealthRepository healthRepo;
    late MockPermissionRepository permRepo;

    setUp(() {
      healthRepo = MockHealthRepository();
      permRepo = MockPermissionRepository();
    });

    tearDown(() {
      healthRepo.dispose();
    });

    test('GetStepsStreamUseCase delivers emitted step records', () async {
      final useCase = GetStepsStreamUseCase(healthRepo);
      final now = DateTime.now();
      final expectedRecord = StepRecordEntity(
        id: 'step_1',
        count: 150,
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now,
      );

      final expectation = expectLater(useCase(), emits(expectedRecord));
      healthRepo.emitStep(expectedRecord);
      await expectation;
    });

    test('GetHeartRateStreamUseCase delivers emitted HR records', () async {
      final useCase = GetHeartRateStreamUseCase(healthRepo);
      final now = DateTime.now();
      final expectedRecord = HeartRateRecordEntity(
        id: 'hr_1',
        bpm: 78,
        timestamp: now,
      );

      final expectation = expectLater(useCase(), emits(expectedRecord));
      healthRepo.emitHeartRate(expectedRecord);
      await expectation;
    });

    test('CheckPermissionsUseCase returns initial permission state', () async {
      final useCase = CheckPermissionsUseCase(permRepo);
      final result = await useCase();

      expect(result.allGranted, isFalse);
      expect(result.hasDenial, isTrue);
    });

    test('RequestPermissionsUseCase updates grant state to true', () async {
      final useCase = RequestPermissionsUseCase(permRepo);
      final result = await useCase();

      expect(result.allGranted, isTrue);
      expect(result.stepsGranted, isTrue);
      expect(result.heartRateGranted, isTrue);
    });
  });
}
