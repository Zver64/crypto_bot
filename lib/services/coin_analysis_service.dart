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
    var riskScore = 0;

    final marketCap = marketData.marketCap ?? 0;
    final volume24h = marketData.totalVolume;
    final twoPercentDepthUsd = _calculateTwoPercentDepthUsd(tickers);

    double? twoPercentDepthToMarketCapRatio;
    if (twoPercentDepthUsd != null && marketCap > 0) {
      twoPercentDepthToMarketCapRatio = twoPercentDepthUsd / marketCap;
    }

    double? volumeToMarketCapRatio;
    if (volume24h != null && marketCap > 0) {
      volumeToMarketCapRatio = volume24h / marketCap;
    }

    if (volumeToMarketCapRatio != null) {
      riskScore += _scoreVolumeToMarketCap(volumeToMarketCapRatio, findings);
    }

    if (twoPercentDepthToMarketCapRatio != null) {
      riskScore += _scoreDepthToMarketCap(
        twoPercentDepthToMarketCapRatio,
        findings,
      );
    } else {
      findings.add('CoinGecko 2% market depth data is unavailable');
    }

    if (twoPercentDepthUsd != null &&
        volume24h != null &&
        volumeToMarketCapRatio != null) {
      riskScore += _scoreLiquidityCrowding(
        twoPercentDepthUsd: twoPercentDepthUsd,
        volume24h: volume24h,
        volumeToMarketCapRatio: volumeToMarketCapRatio,
        findings: findings,
      );
    }

    final boundedRiskScore = riskScore.clamp(0, 100);
    return CoinAnalysisResult(
      name: marketData.name,
      symbol: marketData.symbol,
      marketCap: marketCap,
      riskScore: boundedRiskScore,
      riskLevel: _resolveRiskLevel(boundedRiskScore),
      findings: findings.take(4).toList(growable: false),
      twoPercentDepthUsd: twoPercentDepthUsd,
      volume24hUsd: volume24h,
      twoPercentDepthToMarketCapRatio: twoPercentDepthToMarketCapRatio,
      volumeToMarketCapRatio: volumeToMarketCapRatio,
      athPrice: marketData.ath,
      distanceFromAthPct: distanceFromAthPct,
    );
  }

  static double? _calculateTwoPercentDepthUsd(List<CoinGeckoTicker> tickers) {
    final usableTickers = tickers.where((ticker) => ticker.isUsableForDepth);
    double totalDepth = 0;
    var hasDepth = false;

    for (final ticker in usableTickers) {
      final conservativeDepth = ticker.conservativeDepthUsd;
      if (conservativeDepth == null) {
        continue;
      }

      totalDepth += conservativeDepth;
      hasDepth = true;
    }

    return hasDepth ? totalDepth : null;
  }

  static int _scoreVolumeToMarketCap(double ratio, List<String> findings) {
    if (ratio >= 0.25) {
      findings.add('24h volume is extreme relative to market cap');
      return 18;
    }
    if (ratio >= 0.10) {
      findings.add('24h volume is high relative to market cap');
      return 10;
    }
    if (ratio >= 0.03) {
      findings.add('24h volume is elevated relative to market cap');
      return 5;
    }
    return 0;
  }

  static int _scoreDepthToMarketCap(double ratio, List<String> findings) {
    if (ratio < 0.0000025) {
      findings.add('2% market depth is extremely thin for the market cap');
      return 18;
    }
    if (ratio < 0.00001) {
      findings.add('2% market depth is thin for the market cap');
      return 10;
    }
    if (ratio < 0.00003) {
      findings.add('2% market depth is modest relative to market cap');
      return 5;
    }
    return 0;
  }

  static int _scoreLiquidityCrowding({
    required double twoPercentDepthUsd,
    required double volume24h,
    required double volumeToMarketCapRatio,
    required List<String> findings,
  }) {
    if (volume24h <= 0) {
      return 0;
    }

    final depthToVolumeRatio = twoPercentDepthUsd / volume24h;

    if (depthToVolumeRatio < 0.003 && volumeToMarketCapRatio >= 0.10) {
      findings.add('Volume looks crowded versus available 2% market depth');
      return 12;
    }
    if (depthToVolumeRatio < 0.01 && volumeToMarketCapRatio >= 0.03) {
      findings.add('2% market depth looks light versus trading volume');
      return 6;
    }
    return 0;
  }

  static CoinRiskLevel _resolveRiskLevel(int riskScore) {
    if (riskScore >= 70) {
      return CoinRiskLevel.high;
    }
    if (riskScore >= 40) {
      return CoinRiskLevel.medium;
    }
    return CoinRiskLevel.low;
  }
}
