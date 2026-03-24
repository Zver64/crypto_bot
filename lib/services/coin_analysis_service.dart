import '../models/bybit_instrument_models.dart';
import '../models/bybit_models.dart';
import '../models/bybit_orderbook_models.dart';
import '../models/coin_analysis_models.dart';

class CoinAnalysisService {
  static CoinAnalysisResult analyze({
    required BybitTicker ticker,
    required BybitInstrument instrument,
    required BybitOrderbook orderbook,
    required String generatedTicker,
    required double marketCap,
    double? athPrice,
    double? distanceFromAthPct,
  }) {
    final findings = <String>[];
    var riskScore = 0;

    final turnover24h = double.tryParse(ticker.turnover24h ?? '');
    final fundingRatePct = _parsePercentFromDecimal(ticker.fundingRate);
    final nextFundingTime = _parseTimestamp(ticker.nextFundingTime);

    double? visibleDepthUsd;
    double? visibleDepthToMarketCapRatio;
    if (orderbook.bids.isNotEmpty && orderbook.asks.isNotEmpty) {
      final bidDepthUsd = orderbook.bids.fold<double>(
        0,
        (sum, level) => sum + level.notionalUsd,
      );
      final askDepthUsd = orderbook.asks.fold<double>(
        0,
        (sum, level) => sum + level.notionalUsd,
      );
      visibleDepthUsd = bidDepthUsd < askDepthUsd ? bidDepthUsd : askDepthUsd;

      if (marketCap > 0) {
        visibleDepthToMarketCapRatio = visibleDepthUsd / marketCap;
      }
    }

    double? turnoverToMarketCapRatio;
    if (turnover24h != null && marketCap > 0) {
      turnoverToMarketCapRatio = turnover24h / marketCap;
    }

    if (fundingRatePct != null) {
      riskScore += _scoreFundingRate(fundingRatePct, findings);
    }

    if (turnoverToMarketCapRatio != null) {
      riskScore += _scoreTurnoverToMarketCap(turnoverToMarketCapRatio, findings);
    }

    if (visibleDepthUsd != null &&
        turnoverToMarketCapRatio != null &&
        fundingRatePct != null) {
      riskScore += _scoreLiquidityCrowdingCombo(
        visibleDepthUsd: visibleDepthUsd,
        marketCap: marketCap,
        turnoverToMarketCapRatio: turnoverToMarketCapRatio,
        fundingRatePct: fundingRatePct,
        findings: findings,
      );
    }

    final boundedRiskScore = riskScore.clamp(0, 100);
    return CoinAnalysisResult(
      symbol: ticker.symbol,
      generatedTicker: generatedTicker,
      marketCap: marketCap,
      riskScore: boundedRiskScore,
      riskLevel: _resolveRiskLevel(boundedRiskScore),
      findings: findings.take(4).toList(growable: false),
      visibleDepthUsd: visibleDepthUsd,
      turnover24hUsd: turnover24h,
      visibleDepthToMarketCapRatio: visibleDepthToMarketCapRatio,
      turnoverToMarketCapRatio: turnoverToMarketCapRatio,
      fundingRatePct: fundingRatePct,
      fundingIntervalMinutes: instrument.fundingInterval,
      nextFundingTime: nextFundingTime,
      athPrice: athPrice,
      distanceFromAthPct: distanceFromAthPct,
    );
  }

  static int _scoreTurnoverToMarketCap(double ratio, List<String> findings) {
    if (ratio >= 0.25) {
      findings.add('24h turnover is extreme for this market cap');
      return 18;
    }
    if (ratio >= 0.10) {
      findings.add('24h turnover is high for this market cap');
      return 10;
    }
    if (ratio >= 0.03) {
      findings.add('24h turnover is elevated for this market cap');
      return 5;
    }
    return 0;
  }

  static int _scoreLiquidityCrowdingCombo({
    required double visibleDepthUsd,
    required double marketCap,
    required double turnoverToMarketCapRatio,
    required double fundingRatePct,
    required List<String> findings,
  }) {
    final visibleDepthToMarketCapRatio = marketCap > 0
        ? visibleDepthUsd / marketCap
        : 0;
    final absFunding = fundingRatePct.abs();

    if (visibleDepthToMarketCapRatio < 0.00001 &&
        turnoverToMarketCapRatio >= 0.10 &&
        absFunding >= 0.05) {
      findings.add('Market cap looks weakly backed by visible liquidity');
      return 18;
    }
    if (visibleDepthToMarketCapRatio < 0.00005 &&
        turnoverToMarketCapRatio >= 0.03 &&
        absFunding >= 0.02) {
      findings.add('Visible liquidity looks weak for the market cap');
      return 10;
    }
    return 0;
  }

  static int _scoreFundingRate(double fundingRatePct, List<String> findings) {
    final absFunding = fundingRatePct.abs();
    if (absFunding >= 0.15) {
      findings.add('Funding is extreme');
      return 18;
    }
    if (absFunding >= 0.05) {
      findings.add('Funding is elevated');
      return 10;
    }
    if (absFunding >= 0.02) {
      findings.add('Funding is mildly elevated');
      return 5;
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

  static double? _parsePercentFromDecimal(String? rawValue) {
    final parsed = double.tryParse(rawValue ?? '');
    if (parsed == null) {
      return null;
    }

    return parsed * 100;
  }

  static DateTime? _parseTimestamp(String? rawValue) {
    final parsed = int.tryParse(rawValue ?? '');
    if (parsed == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(parsed);
  }
}
