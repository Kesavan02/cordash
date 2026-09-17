import '../../domain/entities/permission_status_entity.dart';
import '../../domain/repositories/permission_repository.dart';
import '../datasources/health_connect_data_source.dart';

/// Concrete implementation of [PermissionRepository] backed by [HealthConnectDataSource].
class PermissionRepositoryImpl implements PermissionRepository {
  final HealthConnectDataSource _dataSource;

  PermissionRepositoryImpl({HealthConnectDataSource? dataSource})
    : _dataSource = dataSource ?? HealthConnectDataSource();

  @override
  Future<PermissionStatusEntity> checkStatus() {
    return _dataSource.checkPermissions();
  }

  @override
  Future<PermissionStatusEntity> requestAccess() {
    return _dataSource.requestPermissions();
  }
}
