import '../entities/heart_rate_record_entity.dart';
import '../repositories/health_repository.dart';

final class GetHeartRateStreamUseCase {
  final HealthRepository _repository;

  const GetHeartRateStreamUseCase(this._repository);

  Stream<HeartRateRecordEntity> call() => _repository.heartRateStream;
}
