import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/data/services/deduplication_service.dart';

void main() {
  group('DeduplicationService Tests', () {
    late DeduplicationService service;

    setUp(() {
      service = DeduplicationService(
        maxCacheSize: 5,
        burstThreshold: const Duration(milliseconds: 200),
      );
    });

    test('Identifies duplicate IDs correctly', () {
      expect(service.isDuplicate('id_1'), isFalse);
      expect(service.isDuplicate('id_1'), isTrue);
      expect(service.isDuplicate('id_2'), isFalse);
      expect(service.isDuplicate('id_2'), isTrue);
    });

    test('Evicts oldest item when maxCacheSize is reached', () {
      for (int i = 1; i <= 5; i++) {
        expect(service.isDuplicate('id_$i'), isFalse);
      }
      expect(service.cachedIdCount, equals(5));

      // Adding 6th item should evict id_1
      expect(service.isDuplicate('id_6'), isFalse);
      expect(service.cachedIdCount, equals(5));

      // id_1 should now be accepted again as it was evicted
      expect(service.isDuplicate('id_1'), isFalse);
    });

    test('Filters duplicate items from a list', () {
      final input = [
        {'id': 'a', 'val': 10},
        {'id': 'b', 'val': 20},
        {'id': 'a', 'val': 30},
        {'id': 'c', 'val': 40},
        {'id': 'b', 'val': 50},
      ];

      final filtered = service.filterDuplicates<Map<String, dynamic>>(
        input,
        (item) => item['id'] as String,
      );

      expect(filtered.length, equals(3));
      expect(filtered.map((e) => e['id']).toList(), equals(['a', 'b', 'c']));
      expect(filtered.map((e) => e['val']).toList(), equals([10, 20, 40]));
    });

    test('Detects bursts within cooldown threshold', () {
      final t0 = DateTime.now();
      expect(service.isBurst(t0), isFalse);

      // Event 50ms later is within 200ms threshold -> burst
      expect(service.isBurst(t0.add(const Duration(milliseconds: 50))), isTrue);

      // Event 300ms later is outside threshold -> not burst
      expect(service.isBurst(t0.add(const Duration(milliseconds: 300))), isFalse);
    });

    test('clear() resets cached IDs', () {
      service.isDuplicate('id_1');
      service.isDuplicate('id_2');
      expect(service.cachedIdCount, equals(2));

      service.clear();
      expect(service.cachedIdCount, equals(0));
      expect(service.isDuplicate('id_1'), isFalse);
    });
  });
}
