class PermissionStatusEntity {
  final bool stepsGranted;
  final bool heartRateGranted;
  final bool canRequestAgain;

  const PermissionStatusEntity({
    required this.stepsGranted,
    required this.heartRateGranted,
    this.canRequestAgain = true,
  });

  bool get allGranted => stepsGranted && heartRateGranted;
  bool get hasDenial => !stepsGranted || !heartRateGranted;

  PermissionStatusEntity copyWith({
    bool? stepsGranted,
    bool? heartRateGranted,
    bool? canRequestAgain,
  }) {
    return PermissionStatusEntity(
      stepsGranted: stepsGranted ?? this.stepsGranted,
      heartRateGranted: heartRateGranted ?? this.heartRateGranted,
      canRequestAgain: canRequestAgain ?? this.canRequestAgain,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionStatusEntity &&
          runtimeType == other.runtimeType &&
          stepsGranted == other.stepsGranted &&
          heartRateGranted == other.heartRateGranted &&
          canRequestAgain == other.canRequestAgain;

  @override
  int get hashCode => Object.hash(stepsGranted, heartRateGranted, canRequestAgain);
}
