import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/data/services/resampling_service.dart';
import 'package:cordash/domain/entities/heart_rate_record_entity.dart';

void main() {
  group('ResamplingService LTTB Tests', () {
    test('Returns exact list if threshold >= data length', () {
      final points = [
        const DataPoint(1, 10),
        const DataPoint(2, 20),
        const DataPoint(3, 30),
      ];

      final result = ResamplingService.downsampleLTTB(points, 5);
      expect(result.length, equals(3));
      expect(result, equals(points));
    });

    test('Downsamples 1,000 points to exactly requested threshold', () {
      final points = <DataPoint>[];
      for (int i = 0; i < 1000; i++) {
        // Sinusoidal wave with noise
        final y = 75 + 15 * math.sin(i / 20.0) + (i % 5);
        points.add(DataPoint(i.toDouble(), y));
      }

      const target = 100;
      final downsampled = ResamplingService.downsampleLTTB(points, target);

      expect(downsampled.length, equals(target));
      // First point must match
      expect(downsampled.first, equals(points.first));
      // Last point must match
      expect(downsampled.last, equals(points.last));
    });

    test('Downsamples 5,000 points down to 300 points efficiently', () {
      final points = <DataPoint>[];
      for (int i = 0; i < 5000; i++) {
        points.add(DataPoint(i.toDouble(), (60 + (i % 40)).toDouble()));
      }

      final stopwatch = Stopwatch()..start();
      final result = ResamplingService.downsampleLTTB(points, 300);
      stopwatch.stop();

      expect(result.length, equals(300));
      expect(result.first, equals(points.first));
      expect(result.last, equals(points.last));
      // Performance check: should complete well within 50ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('downsampleHeartRateRecords preserves extremes and target count', () {
      final now = DateTime.now();
      final records = <HeartRateRecordEntity>[];

      for (int i = 0; i < 500; i++) {
        final time = now.add(Duration(seconds: i * 5));
        // Spike at index 250
        final bpm = i == 250 ? 180 : 70 + (i % 10);
        records.add(HeartRateRecordEntity(
          id: 'hr_$i',
          bpm: bpm,
          timestamp: time,
        ));
      }

      const target = 50;
      final downsampled = ResamplingService.downsampleHeartRateRecords(records, target);

      expect(downsampled.length, equals(target));
      expect(downsampled.first.id, equals('hr_0'));
      expect(downsampled.last.id, equals('hr_499'));

      // The prominent peak (180 bpm) must be retained by LTTB
      final containsPeak = downsampled.any((r) => r.bpm == 180);
      expect(containsPeak, isTrue);
    });
  });
}
