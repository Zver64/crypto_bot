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
    final filteredCoinList = coinList.where((data) => double.parse(data.price24hPcnt) > 0.09).toList();
    print('${filteredCoinList.length} coins are filtered');
    final List<String> alerts = [];

    final symbolsWithoutGeneratedTicker = filteredCoinList
        .map((ticker) => ticker.symbol)
        .where((symbol) => !BotState.generatedTickerCache.containsKey(symbol))
        .toList();

    if (symbolsWithoutGeneratedTicker.isNotEmpty) {
      final instruments = await ApiService.getBybitInstrumentsBySymbols(symbolsWithoutGeneratedTicker);
      for (final symbol in symbolsWithoutGeneratedTicker) {
        final instrument = instruments[symbol];
        if (instrument == null) {
          continue;
        }

        BotState.generatedTickerCache[symbol] = _generateTickerFromBaseCoin(instrument.baseCoin);
      }
    }

    final missingSymbols = filteredCoinList
        .map((ticker) => ticker.symbol)
        .where((symbol) => !BotState.circulatingSupplyCache.containsKey(symbol))
        .toList();

    final missingGeneratedTickers = missingSymbols
        .map((symbol) => BotState.generatedTickerCache[symbol])
        .whereType<String>()
        .toSet()
        .toList();

    if (missingGeneratedTickers.isNotEmpty) {
      print('Fetching circulating supplies for ${missingGeneratedTickers.length} missing coins');
      try {
        final supplyResults = await BatchProcessor.batchProcess<Map<String, BigInt>, String>(
          missingGeneratedTickers,
          ApiService.getCoinGeckoCirculatingSupply,
          delay: Config.batchProcessDelay,
        );

        final mergedSupplies = <String, BigInt>{};
        for (final supplies in supplyResults) {
          mergedSupplies.addAll(supplies);
        }

        for (final symbol in missingSymbols) {
          final generatedTicker = BotState.generatedTickerCache[symbol];
          if (generatedTicker == null) continue;
          final circulatingSupply = mergedSupplies[generatedTicker];
          if (circulatingSupply != null) {
            BotState.circulatingSupplyCache[symbol] = circulatingSupply;
          }
        }

        final notFoundSymbols = missingSymbols
            .where((symbol) => !BotState.circulatingSupplyCache.containsKey(symbol))
            .toList();
        if (notFoundSymbols.isNotEmpty) {
          print('No CoinGecko supply match for: $notFoundSymbols');
        }

        print('Total circulating supplies cached: ${BotState.circulatingSupplyCache.length}');
      } catch (e) {
        print('ERROR: CoinGecko supply lookup failed: $e');
        alerts.add('⚠️ CoinGecko supply lookup failed for some filtered coins');
      }
    }

    for (final ticker in filteredCoinList) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      final BigInt? circulatingSupply = BotState.circulatingSupplyCache[ticker.symbol];
      
      if (circulatingSupply != null && circulatingSupply > BigInt.zero) {
        final double currentPrice = double.parse(ticker.lastPrice);
        // Scale price by 1e12 to preserve full double precision
        final BigInt scaledPrice = BigInt.from((currentPrice * 1e12).round());
        final BigInt scaledMarketCap = circulatingSupply * scaledPrice;
        final BigInt marketCapBigInt = scaledMarketCap ~/ BigInt.from(1e12.toInt());
        final double marketCap = marketCapBigInt.toDouble();

        final double dynamicThreshold = volatilityFromMcap(
          marketCap,
          smallVol: threshold.minCap.toDouble(),
          largeVol: threshold.maxCap.toDouble(),
        );

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

String _generateTickerFromBaseCoin(String baseCoin) {
  final normalizedBaseCoin = baseCoin.trim().toUpperCase();
  const allowedMultipliers = <String>[
    '10',
    '100',
    '1000',
    '10000',
    '100000',
    '1000000',
  ];

  for (final prefix in allowedMultipliers) {
    if (!normalizedBaseCoin.startsWith(prefix) || normalizedBaseCoin.length == prefix.length) {
      continue;
    }

    final candidate = normalizedBaseCoin.substring(prefix.length);
    if (RegExp(r'^[A-Z]+$').hasMatch(candidate)) {
      return candidate;
    }
  }

  return normalizedBaseCoin;
}
