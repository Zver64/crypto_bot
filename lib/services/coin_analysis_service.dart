import '../models/coin_analysis_models.dart';
import '../models/coingecko_market_models.dart';
import '../models/coingecko_ticker_models.dart';

class CoinAnalysisService {
  static CoinAnalysisResult analyze({
    required CoinGeckoMarketData marketData,
    required List<CoinGeckoTicker> tickers,
    double? distanceFromAthPct,
  }) {
    final findings = <String>[];
    final constraints = <String>[];
    var explosiveUpsideScore = 0;

    final marketCap = marketData.marketCap ?? 0;
    final volume24h = marketData.totalVolume;
    final usableTickers = tickers.where((ticker) => ticker.isUsableForDepth).toList(
      growable: false,
    );

    final upsideDepthUsd = _sumPositive(
      usableTickers.map((ticker) => ticker.costToMoveUpUsd),
    );
    final downsideDepthUsd = _sumPositive(
      usableTickers.map((ticker) => ticker.costToMoveDownUsd),
    );
    final usableVolumeUsd = _sumPositive(
      usableTickers.map((ticker) => ticker.convertedVolumeUsd),
    );

    final usableTickerCoverageRatio = tickers.isEmpty
        ? null
        : usableTickers.length / tickers.length;
    final volumeCoverageRatio =
        usableVolumeUsd != null && volume24h != null && volume24h > 0
        ? usableVolumeUsd / volume24h
        : null;
    final upsideDepthToMarketCapRatio =
        upsideDepthUsd != null && marketCap > 0 ? upsideDepthUsd / marketCap : null;
    final upsideDepthToVolumeRatio =
        upsideDepthUsd != null && volume24h != null && volume24h > 0
        ? upsideDepthUsd / volume24h
        : null;
    final topVenueVolumeShare = _largestShare(
      usableTickers.map((ticker) => ticker.convertedVolumeUsd),
    );
    final topVenueUpsideDepthShare = _largestShare(
      usableTickers.map((ticker) => ticker.costToMoveUpUsd),
    );
    final upsideToDownsideDepthRatio =
        upsideDepthUsd != null && downsideDepthUsd != null && downsideDepthUsd > 0
        ? upsideDepthUsd / downsideDepthUsd
        : null;

    explosiveUpsideScore += _scoreThinUpsideDepth(
      upsideDepthUsd: upsideDepthUsd,
      upsideDepthToMarketCapRatio: upsideDepthToMarketCapRatio,
      findings: findings,
      constraints: constraints,
    );
    explosiveUpsideScore += _scoreCrowdedFlow(
      marketCap: marketCap,
      upsideDepthUsd: upsideDepthUsd,
      upsideDepthToVolumeRatio: upsideDepthToVolumeRatio,
      findings: findings,
      constraints: constraints,
    );
    explosiveUpsideScore += _scoreVenueConcentration(
      marketCap: marketCap,
      upsideDepthUsd: upsideDepthUsd,
      topVenueVolumeShare: topVenueVolumeShare,
      topVenueUpsideDepthShare: topVenueUpsideDepthShare,
      findings: findings,
    );
    explosiveUpsideScore += _scoreUpsideAsymmetry(
      upsideDepthUsd: upsideDepthUsd,
      upsideToDownsideDepthRatio: upsideToDownsideDepthRatio,
      findings: findings,
      constraints: constraints,
    );
    explosiveUpsideScore += _scoreSmallCapReflexivity(
      marketCap: marketCap,
      findings: findings,
    );

    final dataConfidenceScore = _scoreDataConfidence(
      totalTickerCount: tickers.length,
      usableTickerCount: usableTickers.length,
      usableTickerCoverageRatio: usableTickerCoverageRatio,
      volumeCoverageRatio: volumeCoverageRatio,
      upsideDepthUsd: upsideDepthUsd,
      constraints: constraints,
    );

    if (findings.isEmpty) {
      findings.add('No strong CoinGecko depth signals of an easy upside squeeze');
    }

    if (constraints.isEmpty) {
      constraints.add('No major data-quality constraints detected in CoinGecko tickers');
    }

    final boundedExplosiveUpsideScore = explosiveUpsideScore.clamp(0, 100);

    return CoinAnalysisResult(
      name: marketData.name,
      symbol: marketData.symbol,
      marketCap: marketCap,
      explosiveUpsideScore: boundedExplosiveUpsideScore,
      explosiveUpsideLevel: _resolveExplosiveUpsideLevel(
        boundedExplosiveUpsideScore,
      ),
      dataConfidenceScore: dataConfidenceScore,
      dataConfidenceLevel: _resolveDataConfidenceLevel(dataConfidenceScore),
      findings: findings.take(4).toList(growable: false),
      constraints: constraints.take(3).toList(growable: false),
      upsideDepthUsd: upsideDepthUsd,
      downsideDepthUsd: downsideDepthUsd,
      volume24hUsd: volume24h,
      upsideDepthToMarketCapRatio: upsideDepthToMarketCapRatio,
      upsideDepthToVolumeRatio: upsideDepthToVolumeRatio,
      topVenueVolumeShare: topVenueVolumeShare,
      topVenueUpsideDepthShare: topVenueUpsideDepthShare,
      usableTickerCoverageRatio: usableTickerCoverageRatio,
      athPrice: marketData.ath,
      distanceFromAthPct: distanceFromAthPct,
    );
  }

  static double? _sumPositive(Iterable<double?> values) {
    double total = 0;
    var hasValue = false;

    for (final value in values) {
      if (value == null || value <= 0) {
        continue;
      }

      total += value;
      hasValue = true;
    }

    return hasValue ? total : null;
  }

  static double? _largestShare(Iterable<double?> values) {
    double total = 0;
    double largest = 0;
    var hasValue = false;

    for (final value in values) {
      if (value == null || value <= 0) {
        continue;
      }

      total += value;
      if (value > largest) {
        largest = value;
      }
      hasValue = true;
    }

    if (!hasValue || total <= 0) {
      return null;
    }

    return largest / total;
  }

  static int _scoreThinUpsideDepth({
    required double? upsideDepthUsd,
    required double? upsideDepthToMarketCapRatio,
    required List<String> findings,
    required List<String> constraints,
  }) {
    if (upsideDepthUsd == null || upsideDepthToMarketCapRatio == null) {
      constraints.add('CoinGecko upward depth data is missing');
      return 0;
    }

    if (upsideDepthUsd < 250000 && upsideDepthToMarketCapRatio < 0.0005) {
      findings.add('Upward 2% depth is extremely thin for the reported market cap');
      return 32;
    }
    if (upsideDepthUsd < 1000000 && upsideDepthToMarketCapRatio < 0.001) {
      findings.add('Upward 2% depth is thin enough for a squeeze on modest size');
      return 22;
    }
    if (upsideDepthUsd < 5000000 && upsideDepthToMarketCapRatio < 0.003) {
      findings.add('Upward depth is limited relative to the reported market cap');
      return 12;
    }
    if (upsideDepthUsd < 15000000 && upsideDepthToMarketCapRatio < 0.01) {
      findings.add('Upward depth is not especially deep for the market cap');
      return 6;
    }

    constraints.add('Upward depth is substantial enough to resist a small squeeze');
    return 0;
  }

  static int _scoreCrowdedFlow({
    required double marketCap,
    required double? upsideDepthUsd,
    required double? upsideDepthToVolumeRatio,
    required List<String> findings,
    required List<String> constraints,
  }) {
    if (upsideDepthUsd == null || upsideDepthToVolumeRatio == null) {
      return 0;
    }

    final shouldScore = marketCap < 2000000000 || upsideDepthUsd < 10000000;
    if (!shouldScore) {
      return 0;
    }

    if (upsideDepthToVolumeRatio < 0.004) {
      findings.add('Trading flow is heavy relative to upward depth');
      return 16;
    }
    if (upsideDepthToVolumeRatio < 0.015) {
      findings.add('Trading flow could crowd a thin upside book');
      return 10;
    }
    if (upsideDepthToVolumeRatio < 0.04) {
      findings.add('Recent trading flow is meaningful relative to upward depth');
      return 5;
    }

    constraints.add('24h flow is not obviously crowding the upside book');
    return 0;
  }

  static int _scoreVenueConcentration({
    required double marketCap,
    required double? upsideDepthUsd,
    required double? topVenueVolumeShare,
    required double? topVenueUpsideDepthShare,
    required List<String> findings,
  }) {
    final shouldScore =
        marketCap < 5000000000 || (upsideDepthUsd != null && upsideDepthUsd < 15000000);
    if (!shouldScore) {
      return 0;
    }

    var score = 0;

    if (topVenueVolumeShare != null) {
      if (topVenueVolumeShare > 0.85) {
        findings.add('Most visible volume is concentrated on one venue');
        score += 14;
      } else if (topVenueVolumeShare > 0.65) {
        findings.add('A single venue dominates visible volume');
        score += 9;
      } else if (topVenueVolumeShare > 0.50) {
        findings.add('Visible volume is concentrated in a narrow venue set');
        score += 4;
      }
    }

    if (topVenueUpsideDepthShare != null) {
      if (topVenueUpsideDepthShare > 0.85) {
        findings.add('Upward depth is heavily dependent on one venue');
        score += 14;
      } else if (topVenueUpsideDepthShare > 0.65) {
        findings.add('One venue contributes most of the visible upward depth');
        score += 9;
      } else if (topVenueUpsideDepthShare > 0.50) {
        findings.add('Upward depth is concentrated in a narrow venue set');
        score += 4;
      }
    }

    return score;
  }

  static int _scoreUpsideAsymmetry({
    required double? upsideDepthUsd,
    required double? upsideToDownsideDepthRatio,
    required List<String> findings,
    required List<String> constraints,
  }) {
    if (upsideDepthUsd == null || upsideToDownsideDepthRatio == null) {
      return 0;
    }

    if (upsideDepthUsd < 10000000 && upsideToDownsideDepthRatio < 0.70) {
      findings.add('Price looks materially easier to push up than down');
      return 14;
    }
    if (upsideDepthUsd < 10000000 && upsideToDownsideDepthRatio < 0.85) {
      findings.add('Upward moves look easier than downside moves');
      return 8;
    }

    if (upsideToDownsideDepthRatio > 1.10) {
      constraints.add('CoinGecko depth does not show upside asymmetry');
    }

    return 0;
  }

  static int _scoreSmallCapReflexivity({
    required double marketCap,
    required List<String> findings,
  }) {
    if (marketCap <= 0) {
      return 0;
    }

    if (marketCap < 25000000) {
      findings.add('Very small market cap leaves room for reflexive vertical moves');
      return 18;
    }
    if (marketCap < 100000000) {
      findings.add('Small market cap can amplify coordinated upside');
      return 12;
    }
    if (marketCap < 500000000) {
      findings.add('Sub-\$500M market cap keeps squeeze risk meaningful');
      return 7;
    }
    if (marketCap < 2000000000) {
      findings.add('Sub-\$2B market cap still allows reflexive upside phases');
      return 3;
    }

    return 0;
  }

  static int _scoreDataConfidence({
    required int totalTickerCount,
    required int usableTickerCount,
    required double? usableTickerCoverageRatio,
    required double? volumeCoverageRatio,
    required double? upsideDepthUsd,
    required List<String> constraints,
  }) {
    if (totalTickerCount == 0) {
      constraints.add('CoinGecko returned no ticker data for this coin');
      return 5;
    }

    var score = 20;

    if (usableTickerCount > 0) {
      score += 20;
    } else {
      constraints.add(
        'No usable CoinGecko tickers remain after filtering stale and anomalous markets',
      );
    }

    final coverage = usableTickerCoverageRatio ?? 0;
    if (coverage >= 0.75) {
      score += 25;
    } else if (coverage >= 0.50) {
      score += 18;
    } else if (coverage >= 0.25) {
      score += 10;
      constraints.add('Only part of the CoinGecko ticker set has usable depth data');
    } else {
      score += 4;
      constraints.add('Most CoinGecko tickers are unusable for depth analysis');
    }

    if (usableTickerCount >= 10) {
      score += 20;
    } else if (usableTickerCount >= 5) {
      score += 15;
    } else if (usableTickerCount >= 3) {
      score += 10;
    } else if (usableTickerCount >= 2) {
      score += 6;
    } else if (usableTickerCount == 1) {
      score += 3;
    }

    if (volumeCoverageRatio != null) {
      if (volumeCoverageRatio >= 0.50) {
        score += 15;
      } else if (volumeCoverageRatio >= 0.20) {
        score += 10;
      } else if (volumeCoverageRatio >= 0.05) {
        score += 5;
      } else {
        constraints.add('Visible CoinGecko venue volume covers only a small slice of 24h volume');
      }
    } else {
      constraints.add('24h volume coverage across usable CoinGecko venues is unclear');
    }

    if (upsideDepthUsd != null) {
      score += 10;
    }

    if (totalTickerCount < 3) {
      score -= 10;
      constraints.add('CoinGecko ticker sample is narrow');
    }

    return score.clamp(0, 100);
  }

  static ExplosiveUpsideLevel _resolveExplosiveUpsideLevel(int score) {
    if (score >= 75) {
      return ExplosiveUpsideLevel.extreme;
    }
    if (score >= 50) {
      return ExplosiveUpsideLevel.high;
    }
    if (score >= 25) {
      return ExplosiveUpsideLevel.medium;
    }
    return ExplosiveUpsideLevel.low;
  }

  static DataConfidenceLevel _resolveDataConfidenceLevel(int score) {
    if (score >= 75) {
      return DataConfidenceLevel.high;
    }
    if (score >= 45) {
      return DataConfidenceLevel.medium;
    }
    return DataConfidenceLevel.low;
  }
}
