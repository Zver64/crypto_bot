import 'package:televerse/televerse.dart';
import '../services/bot_state.dart';
import '../services/api_service.dart';
import '../services/batch_processor.dart';
import '../utils/common.dart';
import '../config/app_config.dart';

Future<void> checkPrices(Bot bot, Set<int> subscribers, Threshold threshold) async {
  print('Getting prices...');
  try {
    final bybitResponse = await ApiService.getBybitTickers();
    final coinList = bybitResponse.result.list;
    print('got ${coinList.length} coins');
    final filteredCoinList = coinList.where((data) => double.parse(data.price24hPcnt) > 0.09);
    print('${filteredCoinList.length} coins are filtered');
    // Fetch market caps if cache is empty
    if (BotState.marketCapCache.isEmpty) {
      final symbols = filteredCoinList 
          .map((ticker) => ticker.symbol.replaceAll('USDT', '').replaceAll('USDC', ''))
          .toList();
      
      final marketCapResults = await BatchProcessor.batchProcess<Map<String, double>, String>(
        symbols,
        ApiService.getCoinGeckoMarketCaps,
        delay: Config.batchProcessDelay,
      );
      
      // Merge all results
      for (final marketCaps in marketCapResults) {
        BotState.marketCapCache.addAll(marketCaps);
      }
      
      print('Total market caps cached: ${BotState.marketCapCache.length}');
    }

    for (final ticker in filteredCoinList) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      final String baseSymbol = ticker.symbol.replaceAll('USDT', '').replaceAll('USDC', '');
      final double? marketCap = BotState.marketCapCache[baseSymbol];
      
      if (marketCap != null) {
        final double dynamicThreshold = volatilityFromMcap(marketCap, 
          smallMcap: threshold.minCap.toDouble(), 
          largeVol: threshold.maxCap.toDouble());

        if (change24h >= dynamicThreshold) {
          final double currentPrice = double.parse(ticker.lastPrice);
          final String message =
              '🚀 ALERT: ${ticker.symbol} is up ${change24h.toStringAsFixed(2)}% in 24h!\nPrice: \$${currentPrice.toStringAsFixed(4)}\nThreshold: ${dynamicThreshold.toStringAsFixed(1)}%';

          final List<int> usersToRemove = [];
          
          for (final int userId in subscribers) {
            try {
              await bot.api.sendMessage(ChatID(userId), message);
            } catch (e) {
              print('Failed to send to $userId: $e - Auto-unsubscribing');
              usersToRemove.add(userId);
            }
          }
          
          for (final int userId in usersToRemove) {
            subscribers.remove(userId);
          }
          
          if (usersToRemove.isNotEmpty) {
            print('Auto-unsubscribed ${usersToRemove.length} unreachable users');
          }
        }
      }
    }
    print('finished price check');
  } catch (e) {
    print('Error checking prices: $e');
  }
}
