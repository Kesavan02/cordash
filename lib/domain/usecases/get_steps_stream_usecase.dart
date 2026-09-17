import '../entities/step_record_entity.dart';
import '../repositories/health_repository.dart';

final class GetStepsStreamUseCase {
  final HealthRepository _repository;

  const GetStepsStreamUseCase(this._repository);

  Stream<StepRecordEntity> call() => _repository.stepsStream;
}
