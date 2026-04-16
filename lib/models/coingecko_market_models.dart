class CoinGeckoMarketData {
  final String id;
  final String name;
  final String symbol;
  final double? currentPrice;
  final double? marketCap;
  final double? totalVolume;
  final double? ath;
  final double? athChangePercentage;

  const CoinGeckoMarketData({
    required this.id,
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.marketCap,
    required this.totalVolume,
    required this.ath,
    required this.athChangePercentage,
  });

  factory CoinGeckoMarketData.fromJson(Map<String, dynamic> json) {
    final currentPrice = json['current_price'];
    final marketCap = json['market_cap'];
    final totalVolume = json['total_volume'];
    final ath = json['ath'];
    final athChangePercentage = json['ath_change_percentage'];

    return CoinGeckoMarketData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString().toUpperCase() ?? '',
      currentPrice: currentPrice?.toDouble(),
      marketCap: marketCap?.toDouble(),
      totalVolume: totalVolume?.toDouble(),
      ath: ath?.toDouble(),
      athChangePercentage: athChangePercentage?.toDouble(),
    );
  }
}
