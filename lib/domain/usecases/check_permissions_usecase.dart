import '../entities/permission_status_entity.dart';
import '../repositories/permission_repository.dart';

final class CheckPermissionsUseCase {
  final PermissionRepository _repository;

  const CheckPermissionsUseCase(this._repository);

  Future<PermissionStatusEntity> call() => _repository.checkStatus();
}
