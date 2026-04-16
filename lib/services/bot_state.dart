import 'dart:async';
import '../config/app_config.dart';
import '../models/coin_analysis_models.dart';

class Threshold {
  int minCap;
  int maxCap;

  Threshold(this.minCap, this.maxCap);

  @override
  String toString() {
    return 'min cap change: $minCap, max cap change: $maxCap';
  }
}

class BotState {
  static final Set<int> subscribers = <int>{};
  static Threshold priceThreshold = Threshold(
    Config.defaultMinCapThreshold,
    Config.defaultMaxCapThreshold,
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
  static void setThreshold(int minCap, int maxCap) {
    priceThreshold.minCap = minCap;
    priceThreshold.maxCap = maxCap;
  }

  static void setMinCapThreshold(int minCap) => priceThreshold.minCap = minCap;
  static void setMaxCapThreshold(int maxCap) => priceThreshold.maxCap = maxCap;
  static Timer? getTimer() => priceCheckTimer;
  static void setTimer(Timer? timer) => priceCheckTimer = timer;
  static void resetMaxPrices() => maxNotifiedPrices.clear();
}
