import 'dart:async';
import '../config/app_config.dart';
import '../models/coin_analysis_models.dart';
import '../utils/common.dart';

class Threshold {
  int minCap;
  int maxCap;
  double minMarketCap;
  double maxMarketCap;

  Threshold(
    this.minCap,
    this.maxCap,
    this.minMarketCap,
    this.maxMarketCap,
  );

  @override
  String toString() {
    return 'min cap change: $minCap%, max cap change: $maxCap%, '
        'min market cap: ${formatCompactUsd(minMarketCap)}, '
        'max market cap: ${formatCompactUsd(maxMarketCap)}';
  }
}

class BotState {
  static final Set<int> subscribers = <int>{};
  static Threshold priceThreshold = Threshold(
    Config.defaultMinCapThreshold,
    Config.defaultMaxCapThreshold,
    Config.defaultMinMarketCap,
    Config.defaultMaxMarketCap,
  );
  static Timer? priceCheckTimer;
  static final Map<String, String> generatedTickerCache = <String, String>{};
  static final Map<String, String> baseCoinCache = <String, String>{};
  static final Map<String, double> marketCapCache = <String, double>{};
  static final Map<String, MarketSnapshot> marketSnapshots =
      <String, MarketSnapshot>{};
  static Timer? cacheRefreshTimer;
  static final Map<String, double> maxNotifiedPrices = <String, double>{};
  static Timer? midnightResetTimer;

  static String getThreshold() => priceThreshold.toString();
  static String getMarketCapAnchors() =>
      'min market cap: ${formatCompactUsd(priceThreshold.minMarketCap)}, '
      'max market cap: ${formatCompactUsd(priceThreshold.maxMarketCap)}';
  static void setThreshold(int minCap, int maxCap) {
    priceThreshold.minCap = minCap;
    priceThreshold.maxCap = maxCap;
  }

  static void setMinCapThreshold(int minCap) => priceThreshold.minCap = minCap;
  static void setMaxCapThreshold(int maxCap) => priceThreshold.maxCap = maxCap;
  static void setMinMarketCap(double minMarketCap) =>
      priceThreshold.minMarketCap = minMarketCap;
  static void setMaxMarketCap(double maxMarketCap) =>
      priceThreshold.maxMarketCap = maxMarketCap;
  static Timer? getTimer() => priceCheckTimer;
  static void setTimer(Timer? timer) => priceCheckTimer = timer;
  static void resetMaxPrices() => maxNotifiedPrices.clear();
}
