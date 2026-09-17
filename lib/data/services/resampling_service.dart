import 'dart:developer' as developer;
import 'dart:math' as math;
import '../../domain/entities/heart_rate_record_entity.dart';

/// Representation of a 2D data point for downsampling calculations.
class DataPoint {
  final double x;
  final double y;

  const DataPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// High-performance data decimation and resampling service.
/// Implements the Largest-Triangle-Three-Buckets (LTTB) algorithm to reduce
/// large time-series series (e.g., 5,000–10,000 points) to a fixed visual
/// budget (e.g., 300 points) while preserving local peaks, valleys, and trends.
class ResamplingService {
  /// Downsamples a list of [DataPoint] using the Largest-Triangle-Three-Buckets (LTTB) algorithm.
  ///
  /// [data]: The input series sorted ascending by x (timestamp).
  /// [threshold]: The target number of points to produce. Must be >= 2.
  static List<DataPoint> downsampleLTTB(List<DataPoint> data, int threshold) {
    final dataLength = data.length;
    if (threshold >= dataLength || threshold < 3) {
      return List<DataPoint>.from(data);
    }

    final sampled = <DataPoint>[];
    // Size of each bucket in the middle
    final every = (dataLength - 2) / (threshold - 2);

    int a = 0; // Index of the selected point in the previous bucket
    sampled.add(data[a]); // Always add the first point

    for (int i = 0; i < threshold - 2; i++) {
      // Calculate average point for bucket C (the next bucket)
      double avgX = 0.0;
      double avgY = 0.0;
      final avgRangeStart = ((i + 1) * every + 1).floor();
      final avgRangeEnd = math.min(((i + 2) * every + 1).floor(), dataLength);

      final avgRangeLength = avgRangeEnd - avgRangeStart;
      if (avgRangeLength > 0) {
        for (int j = avgRangeStart; j < avgRangeEnd; j++) {
          avgX += data[j].x;
          avgY += data[j].y;
        }
        avgX /= avgRangeLength;
        avgY /= avgRangeLength;
      } else {
        avgX = data[math.min(avgRangeStart, dataLength - 1)].x;
        avgY = data[math.min(avgRangeStart, dataLength - 1)].y;
      }

      // Range for the current bucket B
      final rangeBStart = (i * every + 1).floor();
      final rangeBEnd = math.min(((i + 1) * every + 1).floor(), dataLength);

      // Point a
      final pointAX = data[a].x;
      final pointAY = data[a].y;

      double maxArea = -1.0;
      int maxAreaIndex = rangeBStart;

      for (int j = rangeBStart; j < rangeBEnd; j++) {
        // Area of triangle between A, B, and average C:
        // Area = 0.5 * | (x_a - x_c)(y_b - y_a) - (x_a - x_b)(y_c - y_a) |
        final area =
            ((pointAX - avgX) * (data[j].y - pointAY) -
                    (pointAX - data[j].x) * (avgY - pointAY))
                .abs();

        if (area > maxArea) {
          maxArea = area;
          maxAreaIndex = j;
        }
      }

      sampled.add(data[maxAreaIndex]);
      a = maxAreaIndex; // Next bucket's previous point is the chosen point
    }

    // Always add the last point
    sampled.add(data[dataLength - 1]);

    return sampled;
  }

  /// Downsamples a list of [HeartRateRecordEntity] using LTTB, preserving timestamps and BPM.
  /// Downsamples a list of [HeartRateRecordEntity] using LTTB, mapped by timestamp and BPM.
  static List<HeartRateRecordEntity> downsampleHeartRateRecords(
    List<HeartRateRecordEntity> records,
    int targetCount,
  ) {
    if (records.length <= targetCount || targetCount < 3) {
      return records;
    }

    return developer.Timeline.timeSync('LTTB.downsampleHeartRateRecords', () {
      final dataPoints = records
          .map(
            (r) => DataPoint(
              r.timestamp.millisecondsSinceEpoch.toDouble(),
              r.bpm.toDouble(),
            ),
          )
          .toList(growable: false);

      final decimated = downsampleLTTB(dataPoints, targetCount);

      // Map back to HeartRateRecordEntity
      final result = <HeartRateRecordEntity>[];
      int cursor = 0;
      for (final point in decimated) {
        final targetMs = point.x.round();
        // Find nearest original record matching timestamp and BPM
        while (cursor < records.length - 1 &&
            records[cursor].timestamp.millisecondsSinceEpoch < targetMs) {
          cursor++;
        }
        result.add(records[cursor]);
      }
      return result;
    });
  }
}
