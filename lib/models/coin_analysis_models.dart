enum ExplosiveUpsideLevel { low, medium, high, extreme }

enum DataConfidenceLevel { low, medium, high }

class MarketSnapshot {
  final double openInterest;
  final DateTime capturedAt;

  const MarketSnapshot({required this.openInterest, required this.capturedAt});
}

class CoinAnalysisResult {
  final String name;
  final String symbol;
  final double marketCap;
  final int explosiveUpsideScore;
  final ExplosiveUpsideLevel explosiveUpsideLevel;
  final int dataConfidenceScore;
  final DataConfidenceLevel dataConfidenceLevel;
  final double? upsideDepthUsd;
  final double? downsideDepthUsd;
  final double? volume24hUsd;
  final double? upsideDepthToMarketCapRatio;
  final double? upsideDepthToVolumeRatio;
  final double? topVenueVolumeShare;
  final double? topVenueUpsideDepthShare;
  final double? usableTickerCoverageRatio;
  final double? athPrice;
  final double? distanceFromAthPct;
  final List<String> findings;
  final List<String> constraints;

  const CoinAnalysisResult({
    required this.name,
    required this.symbol,
    required this.marketCap,
    required this.explosiveUpsideScore,
    required this.explosiveUpsideLevel,
    required this.dataConfidenceScore,
    required this.dataConfidenceLevel,
    required this.findings,
    required this.constraints,
    this.upsideDepthUsd,
    this.downsideDepthUsd,
    this.volume24hUsd,
    this.upsideDepthToMarketCapRatio,
    this.upsideDepthToVolumeRatio,
    this.topVenueVolumeShare,
    this.topVenueUpsideDepthShare,
    this.usableTickerCoverageRatio,
    this.athPrice,
    this.distanceFromAthPct,
  });
}
