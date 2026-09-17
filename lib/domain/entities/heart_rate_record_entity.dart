class HeartRateRecordEntity {
  final String id;
  final int bpm;
  final DateTime timestamp;

  const HeartRateRecordEntity({
    required this.id,
    required this.bpm,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateRecordEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bpm == other.bpm &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, bpm, timestamp);
}
