class PermissionStatusEntity {
  final bool stepsGranted;
  final bool heartRateGranted;
  final bool canRequestAgain;
  final bool isHealthConnectAvailable;

  const PermissionStatusEntity({
    required this.stepsGranted,
    required this.heartRateGranted,
    this.canRequestAgain = true,
    this.isHealthConnectAvailable = true,
  });

  bool get allGranted => stepsGranted && heartRateGranted;
  bool get hasDenial => !stepsGranted || !heartRateGranted;

  PermissionStatusEntity copyWith({
    bool? stepsGranted,
    bool? heartRateGranted,
    bool? canRequestAgain,
    bool? isHealthConnectAvailable,
  }) {
    return PermissionStatusEntity(
      stepsGranted: stepsGranted ?? this.stepsGranted,
      heartRateGranted: heartRateGranted ?? this.heartRateGranted,
      canRequestAgain: canRequestAgain ?? this.canRequestAgain,
      isHealthConnectAvailable: isHealthConnectAvailable ?? this.isHealthConnectAvailable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionStatusEntity &&
          runtimeType == other.runtimeType &&
          stepsGranted == other.stepsGranted &&
          heartRateGranted == other.heartRateGranted &&
          canRequestAgain == other.canRequestAgain &&
          isHealthConnectAvailable == other.isHealthConnectAvailable;

  @override
  int get hashCode => Object.hash(
        stepsGranted,
        heartRateGranted,
        canRequestAgain,
        isHealthConnectAvailable,
      );
}
