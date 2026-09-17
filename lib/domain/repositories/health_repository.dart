import '../entities/heart_rate_record_entity.dart';
import '../entities/step_record_entity.dart';

abstract interface class HealthRepository {
  Stream<StepRecordEntity> get stepsStream;
  Stream<HeartRateRecordEntity> get heartRateStream;

  Future<List<StepRecordEntity>> fetchTodaySteps();
  Future<List<HeartRateRecordEntity>> fetchRecentHeartRates({
    Duration duration = const Duration(hours: 1),
  });

  void dispose();
}
