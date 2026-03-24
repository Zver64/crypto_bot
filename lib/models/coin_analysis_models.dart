enum CoinRiskLevel { low, medium, high }

class MarketSnapshot {
  final double openInterest;
  final DateTime capturedAt;

  const MarketSnapshot({required this.openInterest, required this.capturedAt});
}

class CoinAnalysisResult {
  final String symbol;
  final String generatedTicker;
  final double marketCap;
  final int riskScore;
  final CoinRiskLevel riskLevel;
  final double? visibleDepthUsd;
  final double? turnover24hUsd;
  final double? visibleDepthToMarketCapRatio;
  final double? turnoverToMarketCapRatio;
  final double? fundingRatePct;
  final int? fundingIntervalMinutes;
  final DateTime? nextFundingTime;
  final double? athPrice;
  final double? distanceFromAthPct;
  final List<String> findings;

  const CoinAnalysisResult({
    required this.symbol,
    required this.generatedTicker,
    required this.marketCap,
    required this.riskScore,
    required this.riskLevel,
    required this.findings,
    this.visibleDepthUsd,
    this.turnover24hUsd,
    this.visibleDepthToMarketCapRatio,
    this.turnoverToMarketCapRatio,
    this.fundingRatePct,
    this.fundingIntervalMinutes,
    this.nextFundingTime,
    this.athPrice,
    this.distanceFromAthPct,
  });
}
