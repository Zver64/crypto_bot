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
        (Timer _) => checkPrices(bot, BotState.subscribers, BotState.priceThreshold),
      );
      BotState.setTimer(timer);
      print('Started price monitoring');
    }
    
    return '✅ Subscribed to ${BotState.getThreshold()} price alerts!';
  }

  static String unsubscribe(int userId) {
    BotState.subscribers.remove(userId);
    
    if (BotState.subscribers.isEmpty) {
      BotState.getTimer()?.cancel();
      BotState.setTimer(null);
      print('Stopped price monitoring');
    }
    
    return '❌ Unsubscribed from price alerts';
  }

  static String getStatus() {
    return 'Current settings:\n'
        'Threshold: ${BotState.getThreshold()}\n'
        'Subscribers: ${BotState.subscribers.length}\n'
        'Monitoring: ${BotState.getTimer() != null ? "Active" : "Inactive"}\n'
        'Cached coins: ${BotState.marketCapCache.length}';
  }
}
