class CoinGeckoMarketData {
  final String symbol;
  final double? marketCap;
  final double? ath;
  final double? athChangePercentage;

  const CoinGeckoMarketData({
    required this.symbol,
    required this.marketCap,
    required this.ath,
    required this.athChangePercentage,
  });

  factory CoinGeckoMarketData.fromJson(Map<String, dynamic> json) {
    final marketCap = json['market_cap'];
    final ath = json['ath'];
    final athChangePercentage = json['ath_change_percentage'];

    return CoinGeckoMarketData(
      symbol: json['symbol']?.toString().toUpperCase() ?? '',
      marketCap: marketCap?.toDouble(),
      ath: ath?.toDouble(),
      athChangePercentage: athChangePercentage?.toDouble(),
    );
  }
}
