import 'dart:async';

class BotState {
  static final Set<int> subscribers = <int>{};
  static double priceThreshold = 100;
  static Timer? priceCheckTimer;
  
  static double getThreshold() => priceThreshold;
  static void setThreshold(double value) => priceThreshold = value;
  static Timer? getTimer() => priceCheckTimer;
  static void setTimer(Timer? timer) => priceCheckTimer = timer;
}
