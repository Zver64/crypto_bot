class OrderbookLevel {
  final double price;
  final double size;

  const OrderbookLevel({required this.price, required this.size});

  double get notionalUsd => price * size;
}

class BybitOrderbook {
  final String symbol;
  final List<OrderbookLevel> bids;
  final List<OrderbookLevel> asks;

  const BybitOrderbook({
    required this.symbol,
    required this.bids,
    required this.asks,
  });

  factory BybitOrderbook.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? const {};

    return BybitOrderbook(
      symbol: result['s']?.toString() ?? '',
      bids: _parseLevels(result['b'] as List<dynamic>?),
      asks: _parseLevels(result['a'] as List<dynamic>?),
    );
  }

  static List<OrderbookLevel> _parseLevels(List<dynamic>? values) {
    if (values == null) {
      return const [];
    }

    return values
        .whereType<List<dynamic>>()
        .map((level) {
          final price = double.tryParse(level.firstOrNull?.toString() ?? '');
          final size = double.tryParse(
            level.elementAtOrNull(1)?.toString() ?? '',
          );
          if (price == null || size == null) {
            return null;
          }

          return OrderbookLevel(price: price, size: size);
        })
        .whereType<OrderbookLevel>()
        .toList(growable: false);
  }
}
