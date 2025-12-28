class BybitTicker {
  final String symbol;
  final String lastPrice;
  final String price24hPcnt;

  const BybitTicker({
    required this.symbol,
    required this.lastPrice,
    required this.price24hPcnt,
  });

  factory BybitTicker.fromJson(Map<String, Object?> json) {
    return BybitTicker(
      symbol: json['symbol'] as String,
      lastPrice: json['lastPrice'] as String,
      price24hPcnt: json['price24hPcnt'] as String,
    );
  }
}

class BybitResult {
  final List<BybitTicker> list;

  const BybitResult({required this.list});

  factory BybitResult.fromJson(Map<String, Object?> json) {
    final List<Object?> tickerList = json['list'] as List<Object?>;
    final List<BybitTicker> tickers = tickerList
        .map(
          (Object? item) => BybitTicker.fromJson(item as Map<String, Object?>),
        )
        .toList();

    return BybitResult(list: tickers);
  }
}

class BybitResponse {
  final BybitResult result;

  const BybitResponse({required this.result});

  factory BybitResponse.fromJson(Map<String, Object?> json) {
    return BybitResponse(
      result: BybitResult.fromJson(json['result'] as Map<String, Object?>),
    );
  }
}
