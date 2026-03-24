class CoinGeckoMarketData {
  final String symbol;
  final BigInt? circulatingSupply;
  final double? ath;
  final double? athChangePercentage;

  const CoinGeckoMarketData({
    required this.symbol,
    required this.circulatingSupply,
    required this.ath,
    required this.athChangePercentage,
  });

  factory CoinGeckoMarketData.fromJson(Map<String, dynamic> json) {
    final circulatingSupply = json['circulating_supply'];
    final ath = json['ath'];
    final athChangePercentage = json['ath_change_percentage'];

    return CoinGeckoMarketData(
      symbol: json['symbol']?.toString().toUpperCase() ?? '',
      circulatingSupply: circulatingSupply == null
          ? null
          : BigInt.from(circulatingSupply.toDouble()),
      ath: ath?.toDouble(),
      athChangePercentage: athChangePercentage?.toDouble(),
    );
  }
}
