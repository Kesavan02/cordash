import '../entities/permission_status_entity.dart';
import '../repositories/permission_repository.dart';

/// Use case to launch the Health Connect permission request dialog.
class RequestPermissionsUseCase {
  final PermissionRepository _repository;

  const RequestPermissionsUseCase(this._repository);

  Future<PermissionStatusEntity> call() {
    return _repository.requestAccess();
  }
}
