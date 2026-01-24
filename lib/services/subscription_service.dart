import 'dart:async';
import 'package:televerse/televerse.dart';
import '../services/bot_state.dart';
import '../services/price_service.dart';
import '../services/batch_processor.dart';
import '../services/api_service.dart';
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
      
      // Start cache refresh timer
      final cacheTimer = Timer.periodic(
        Config.cacheRefreshInterval,
        (Timer _) => _refreshCache(),
      );
      BotState.cacheRefreshTimer = cacheTimer;
      
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
      print('Stopped price monitoring and cache refresh');
    }
    
    return '❌ Unsubscribed from price alerts';
  }

  static Future<void> _refreshCache() async {
    print('Resetting circulating supply cache...');
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
