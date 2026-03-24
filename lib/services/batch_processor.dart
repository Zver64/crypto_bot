class BatchProcessor {
  static Future<List<T>> batchProcess<T, U>(
    List<U> items,
    Future<T> Function(List<U>) processor, {
    int batchSize = 50,
    Duration delay = const Duration(seconds: 1),
  }) async {
    if (items.isEmpty) return [];

    final results = <T>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();

      try {
        final result = await processor(batch);
        results.add(result);
        print('Batch ${(i ~/ batchSize) + 1}: processed ${batch.length} items');
      } catch (e) {
        print('Batch ${(i ~/ batchSize) + 1} failed: $e');
      }

      // Rate limiting between batches
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }

    return results;
  }
}
