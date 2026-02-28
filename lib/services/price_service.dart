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
    // Check for missing circulating supplies and fetch only those
    final symbols = filteredCoinList 
        .map((ticker) => ticker.symbol.replaceAll('USDT', '').replaceAll('USDC', ''))
        .toList();
    
    final missingSymbols = symbols.where((symbol) => !BotState.circulatingSupplyCache.containsKey(symbol)).toList();
    
    if (missingSymbols.isNotEmpty) {
      print('Fetching circulating supplies for ${missingSymbols.length} missing coins');
      final supplyResults = await BatchProcessor.batchProcess<Map<String, BigInt>, String>(
        missingSymbols,
        ApiService.getCoinGeckoCirculatingSupply,
        delay: Config.batchProcessDelay,
      );
      
      // Merge all results
      for (final supplies in supplyResults) {
        BotState.circulatingSupplyCache.addAll(supplies);
      }
      
      print('Total circulating supplies cached: ${BotState.circulatingSupplyCache.length}');
    }

    final List<String> alerts = [];

    for (final ticker in filteredCoinList) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      final String baseSymbol = ticker.symbol.replaceAll('USDT', '').replaceAll('USDC', '');
      final BigInt? circulatingSupply = BotState.circulatingSupplyCache[baseSymbol];
      
      if (circulatingSupply != null && circulatingSupply > BigInt.zero) {
        final double currentPrice = double.parse(ticker.lastPrice);
        // Scale price by 1e12 to preserve full double precision
        final BigInt scaledPrice = BigInt.from((currentPrice * 1e12).round());
        final BigInt scaledMarketCap = circulatingSupply * scaledPrice;
        final BigInt marketCapBigInt = scaledMarketCap ~/ BigInt.from(1e12.toInt());
        final double marketCap = marketCapBigInt.toDouble();
        
        final double dynamicThreshold = volatilityFromMcap(marketCap, 
          smallMcap: threshold.minCap.toDouble(), 
          largeVol: threshold.maxCap.toDouble());

        if (change24h >= dynamicThreshold) {
          final double currentPrice = double.parse(ticker.lastPrice);
          
          // Check if price exceeds previous max
          final double? previousMax = BotState.maxNotifiedPrices[ticker.symbol];
          if (previousMax == null || currentPrice > previousMax) {
            alerts.add('${ticker.symbol}: +${change24h.toStringAsFixed(2)}% | \$${currentPrice.toStringAsFixed(4)} (threshold: ${dynamicThreshold.toStringAsFixed(1)}%)');
            BotState.maxNotifiedPrices[ticker.symbol] = currentPrice;
          }
        }
      }
    }

    if (alerts.isNotEmpty) {
      final String message = '🚀 ALERTS:\n\n${alerts.join('\n')}';
      
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

    print('finished price check');
  } catch (e) {
    print('Error checking prices: $e');
  }
}
