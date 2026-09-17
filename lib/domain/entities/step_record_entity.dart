class StepRecordEntity {
  final String id;
  final int count;
  final DateTime startTime;
  final DateTime endTime;

  const StepRecordEntity({
    required this.id,
    required this.count,
    required this.startTime,
    required this.endTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepRecordEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          count == other.count &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(id, count, startTime, endTime);
}
