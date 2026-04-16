enum CoinRiskLevel { low, medium, high }

class MarketSnapshot {
  final double openInterest;
  final DateTime capturedAt;

  const MarketSnapshot({required this.openInterest, required this.capturedAt});
}

class CoinAnalysisResult {
  final String name;
  final String symbol;
  final double marketCap;
  final int riskScore;
  final CoinRiskLevel riskLevel;
  final double? twoPercentDepthUsd;
  final double? volume24hUsd;
  final double? twoPercentDepthToMarketCapRatio;
  final double? volumeToMarketCapRatio;
  final double? athPrice;
  final double? distanceFromAthPct;
  final List<String> findings;

  const CoinAnalysisResult({
    required this.name,
    required this.symbol,
    required this.marketCap,
    required this.riskScore,
    required this.riskLevel,
    required this.findings,
    this.twoPercentDepthUsd,
    this.volume24hUsd,
    this.twoPercentDepthToMarketCapRatio,
    this.volumeToMarketCapRatio,
    this.athPrice,
    this.distanceFromAthPct,
  });
}
