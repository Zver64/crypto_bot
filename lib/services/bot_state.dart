import 'dart:async';
import '../config/app_config.dart';

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
  static Threshold priceThreshold = Threshold(Config.defaultMinCapThreshold, Config.defaultMaxCapThreshold);
  static Timer? priceCheckTimer;
  static final Map<String, BigInt> circulatingSupplyCache = <String, BigInt>{};

  static String getThreshold() => priceThreshold.toString();
  static void setThreshold(int minCap, int maxCap) {
    priceThreshold.minCap = minCap;
    priceThreshold.maxCap = maxCap;
  }
  static void setMinCapThreshold(int minCap) => priceThreshold.minCap = minCap;
  static void setMaxCapThreshold(int maxCap) => priceThreshold.maxCap = maxCap;
  static Timer? getTimer() => priceCheckTimer;
  static void setTimer(Timer? timer) => priceCheckTimer = timer;
}
