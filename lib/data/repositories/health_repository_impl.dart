import 'dart:async';
import '../../domain/entities/heart_rate_record_entity.dart';
import '../../domain/entities/step_record_entity.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_connect_data_source.dart';
import '../services/deduplication_service.dart';

/// Concrete implementation of [HealthRepository] backed by [HealthConnectDataSource]
/// and filtered by [DeduplicationService].
class HealthRepositoryImpl implements HealthRepository {
  final HealthConnectDataSource _dataSource;
  final DeduplicationService _dedupService;

  final _stepController = StreamController<StepRecordEntity>.broadcast();
  final _hrController = StreamController<HeartRateRecordEntity>.broadcast();

  StreamSubscription<StepRecordEntity>? _stepSub;
  StreamSubscription<HeartRateRecordEntity>? _hrSub;

  HealthRepositoryImpl({
    HealthConnectDataSource? dataSource,
    DeduplicationService? dedupService,
  })  : _dataSource = dataSource ?? HealthConnectDataSource(),
        _dedupService = dedupService ?? DeduplicationService() {
    _initStreamPipes();
  }

  void _initStreamPipes() {
    _stepSub = _dataSource.stepsStream.listen((step) {
      if (!_dedupService.isDuplicate(step.id) && !_stepController.isClosed) {
        _stepController.add(step);
      }
    });

    _hrSub = _dataSource.heartRateStream.listen((hr) {
      if (!_dedupService.isDuplicate(hr.id) && !_hrController.isClosed) {
        _hrController.add(hr);
      }
    });
  }

  @override
  Stream<StepRecordEntity> get stepsStream => _stepController.stream;

  @override
  Stream<HeartRateRecordEntity> get heartRateStream => _hrController.stream;

  @override
  Future<List<StepRecordEntity>> fetchTodaySteps() async {
    final rawList = await _dataSource.fetchTodaySteps();
    return _dedupService.filterDuplicates(rawList, (item) => item.id);
  }

  @override
  Future<List<HeartRateRecordEntity>> fetchRecentHeartRates({
    Duration duration = const Duration(hours: 1),
  }) async {
    final rawList = await _dataSource.fetchRecentHeartRates(duration: duration);
    return _dedupService.filterDuplicates(rawList, (item) => item.id);
  }

  /// Toggles synthetic data simulation mode for development/testing.
  void setSimulationMode(bool enabled) {
    _dataSource.setSimulationMode(enabled);
  }

  bool get isSimulating => _dataSource.isSimulating;

  @override
  void dispose() {
    _stepSub?.cancel();
    _hrSub?.cancel();
    _stepController.close();
    _hrController.close();
    _dataSource.dispose();
  }
}
