import '../entities/permission_status_entity.dart';

abstract interface class PermissionRepository {
  Future<PermissionStatusEntity> checkStatus();
  Future<PermissionStatusEntity> requestAccess();
}
