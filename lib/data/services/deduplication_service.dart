import 'dart:collection';

/// Service responsible for filtering out duplicate health records and coalescing
/// rapid event bursts before data reaches the presentation layer.
class DeduplicationService {
  final int maxCacheSize;
  final Duration burstThreshold;

  final LinkedHashSet<String> _seenIds = LinkedHashSet<String>();
  DateTime? _lastEmittedTimestamp;

  DeduplicationService({
    this.maxCacheSize = 5000,
    this.burstThreshold = const Duration(milliseconds: 250),
  });

  /// Checks if a record with [id] has already been processed.
  /// If not, stores the [id] and returns `false`.
  bool isDuplicate(String id) {
    if (id.isEmpty) return false;
    if (_seenIds.contains(id)) {
      return true;
    }
    _seenIds.add(id);
    if (_seenIds.length > maxCacheSize) {
      // Evict oldest item (FIFO behavior of LinkedHashSet)
      _seenIds.remove(_seenIds.first);
    }
    return false;
  }

  /// Determines whether a new event is within the burst cooldown window.
  bool isBurst(DateTime currentTimestamp) {
    if (_lastEmittedTimestamp == null) {
      _lastEmittedTimestamp = currentTimestamp;
      return false;
    }
    final difference = currentTimestamp.difference(_lastEmittedTimestamp!);
    if (difference >= Duration.zero && difference < burstThreshold) {
      return true;
    }
    _lastEmittedTimestamp = currentTimestamp;
    return false;
  }

  /// Filters a list of records, preserving order and removing any duplicates by [idSelector].
  List<T> filterDuplicates<T>(
    List<T> records,
    String Function(T item) idSelector,
  ) {
    final result = <T>[];
    for (final item in records) {
      final id = idSelector(item);
      if (!isDuplicate(id)) {
        result.add(item);
      }
    }
    return result;
  }

  /// Clears internal cache.
  void clear() {
    _seenIds.clear();
    _lastEmittedTimestamp = null;
  }

  /// Number of unique IDs currently stored.
  int get cachedIdCount => _seenIds.length;
}
