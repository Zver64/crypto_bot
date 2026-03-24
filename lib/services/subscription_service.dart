import 'dart:async';
import 'package:televerse/televerse.dart';
import '../services/bot_state.dart';
import '../services/price_service.dart';
import '../config/app_config.dart';

class SubscriptionService {
  static Future<String> subscribe(int userId, Bot bot) async {
    final bool wasEmpty = BotState.subscribers.isEmpty;
    BotState.subscribers.add(userId);

    if (wasEmpty) {
      await checkPrices(bot, BotState.subscribers, BotState.priceThreshold);
      final timer = Timer.periodic(
        Config.priceCheckInterval,
        (Timer _) =>
            checkPrices(bot, BotState.subscribers, BotState.priceThreshold),
      );
      BotState.setTimer(timer);

      // Start cache refresh timer
      final cacheTimer = Timer.periodic(
        Config.cacheRefreshInterval,
        (Timer _) => _refreshCache(),
      );
      BotState.cacheRefreshTimer = cacheTimer;

      // Start midnight reset timer
      _scheduleMidnightReset();

      print('Started price monitoring and cache refresh');
    }

    return '✅ Subscribed to ${BotState.getThreshold()} price alerts!';
  }

  static String unsubscribe(int userId) {
    BotState.subscribers.remove(userId);

    if (BotState.subscribers.isEmpty) {
      BotState.getTimer()?.cancel();
      BotState.setTimer(null);
      BotState.cacheRefreshTimer?.cancel();
      BotState.cacheRefreshTimer = null;
      BotState.midnightResetTimer?.cancel();
      BotState.midnightResetTimer = null;
      print('Stopped price monitoring and cache refresh');
    }

    return '❌ Unsubscribed from price alerts';
  }

  static void _scheduleMidnightReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    BotState.midnightResetTimer = Timer(durationUntilMidnight, () {
      BotState.resetMaxPrices();
      BotState.midnightResetTimer = Timer.periodic(
        const Duration(days: 1),
        (Timer _) => BotState.resetMaxPrices(),
      );
    });
  }

  static Future<void> _refreshCache() async {
    print('Resetting circulating supply cache...');
    BotState.generatedTickerCache.clear();
    BotState.circulatingSupplyCache.clear();
    print('Cache reset: ${BotState.circulatingSupplyCache.length} coins');
  }

  static String getStatus() {
    return 'Current settings:\n'
        'Threshold: ${BotState.getThreshold()}\n'
        'Subscribers: ${BotState.subscribers.length}\n'
        'Monitoring: ${BotState.getTimer() != null ? "Active" : "Inactive"}\n'
        'Cached coins: ${BotState.circulatingSupplyCache.length}';
  }
}
