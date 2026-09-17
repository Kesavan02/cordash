import 'package:flutter/foundation.dart';
import '../../domain/entities/permission_status_entity.dart';
import '../../domain/usecases/check_permissions_usecase.dart';
import '../../domain/usecases/request_permissions_usecase.dart';

/// Presentation state provider managing health permissions lifecycle.
class PermissionProvider extends ChangeNotifier {
  final CheckPermissionsUseCase checkPermissions;
  final RequestPermissionsUseCase requestPermissions;

  PermissionStatusEntity _status = const PermissionStatusEntity(
    stepsGranted: false,
    heartRateGranted: false,
    canRequestAgain: true,
  );
  bool _isRequesting = false;

  PermissionProvider({
    required this.checkPermissions,
    required this.requestPermissions,
  }) {
    checkCurrentStatus();
  }

  PermissionStatusEntity get status => _status;
  bool get isRequesting => _isRequesting;
  bool get allGranted => _status.allGranted;
  bool get stepsGranted => _status.stepsGranted;
  bool get heartRateGranted => _status.heartRateGranted;
  bool get isHealthConnectAvailable => _status.isHealthConnectAvailable;

  Future<void> checkCurrentStatus() async {
    _status = await checkPermissions();
    notifyListeners();
  }

  Future<bool> requestAllPermissions() async {
    _isRequesting = true;
    notifyListeners();

    try {
      _status = await requestPermissions();
      return _status.allGranted;
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }
}
