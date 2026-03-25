import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import '../models/bybit_instrument_models.dart';
import '../models/coin_analysis_models.dart';
import '../services/bot_state.dart';
import '../services/api_service.dart';
import '../services/batch_processor.dart';
import '../services/coin_analysis_service.dart';
import '../utils/common.dart';
import '../config/app_config.dart';

Future<void> checkPrices(
  Bot bot,
  Set<int> subscribers,
  Threshold threshold,
) async {
  print('Getting prices...');
  try {
    final bybitResponse = await ApiService.getBybitTickers();
    final coinList = bybitResponse.result.list;
    print('got ${coinList.length} coins');
    final filteredCoinList = coinList
        .where((data) => double.parse(data.price24hPcnt) > 0.09)
        .toList();
    print('${filteredCoinList.length} coins are filtered');
    final List<String> alerts = [];

    final symbolsWithoutGeneratedTicker = filteredCoinList
        .map((ticker) => ticker.symbol)
        .where((symbol) => !BotState.generatedTickerCache.containsKey(symbol))
        .toList();

    if (symbolsWithoutGeneratedTicker.isNotEmpty) {
      final instruments = await ApiService.getBybitInstrumentsBySymbols(
        symbolsWithoutGeneratedTicker,
      );
      for (final symbol in symbolsWithoutGeneratedTicker) {
        final instrument = instruments[symbol];
        if (instrument == null) {
          continue;
        }

        BotState.generatedTickerCache[symbol] = _generateTickerFromBaseCoin(
          instrument.baseCoin,
        );
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
      print(
        'Fetching circulating supplies for ${missingGeneratedTickers.length} missing coins',
      );
      try {
        final supplyResults =
            await BatchProcessor.batchProcess<Map<String, BigInt>, String>(
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
            .where(
              (symbol) => !BotState.circulatingSupplyCache.containsKey(symbol),
            )
            .toList();
        if (notFoundSymbols.isNotEmpty) {
          print('No CoinGecko supply match for: $notFoundSymbols');
        }

        print(
          'Total circulating supplies cached: ${BotState.circulatingSupplyCache.length}',
        );
      } catch (e) {
        print('ERROR: CoinGecko supply lookup failed: $e');
        alerts.add('⚠️ CoinGecko supply lookup failed for some filtered coins');
      }
    }

    for (final ticker in filteredCoinList) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      final BigInt? circulatingSupply =
          BotState.circulatingSupplyCache[ticker.symbol];

      if (circulatingSupply != null && circulatingSupply > BigInt.zero) {
        final double currentPrice = double.parse(ticker.lastPrice);
        // Scale price by 1e12 to preserve full double precision
        final BigInt scaledPrice = BigInt.from((currentPrice * 1e12).round());
        final BigInt scaledMarketCap = circulatingSupply * scaledPrice;
        final BigInt marketCapBigInt =
            scaledMarketCap ~/ BigInt.from(1e12.toInt());
        final double marketCap = marketCapBigInt.toDouble();

        final double dynamicThreshold = volatilityFromMcap(
          marketCap,
          smallVol: threshold.minCap.toDouble(),
          largeVol: threshold.maxCap.toDouble(),
        );

        if (change24h >= dynamicThreshold) {
          // Check if price exceeds previous max
          final double? previousMax = BotState.maxNotifiedPrices[ticker.symbol];
          if (previousMax == null || currentPrice > previousMax) {
            alerts.add(
              _buildAlertMessage(
                symbol: ticker.symbol,
                change24h: change24h,
                currentPrice: currentPrice,
                threshold: dynamicThreshold,
                marketCap: marketCap,
              ),
            );
            BotState.maxNotifiedPrices[ticker.symbol] = currentPrice;
          }
        }
      }
    }

    if (alerts.isNotEmpty) {
      final String message =
          '🚀 ALERTS:\n\n${alerts.join('\n\n──────────\n\n')}';

      final List<int> usersToRemove = [];

      for (final int userId in subscribers) {
        try {
          await bot.api.sendMessage(
            ChatID(userId),
            message,
            parseMode: ParseMode.html,
          );
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
  final multiplierPrefix = _extractMultiplierPrefix(normalizedBaseCoin);
  if (multiplierPrefix != null) {
    return normalizedBaseCoin.substring(multiplierPrefix.length);
  }

  return normalizedBaseCoin;
}

int _extractBaseCoinMultiplier(String baseCoin) {
  final normalizedBaseCoin = baseCoin.trim().toUpperCase();
  final multiplierPrefix = _extractMultiplierPrefix(normalizedBaseCoin);
  if (multiplierPrefix == null) {
    return 1;
  }

  return int.parse(multiplierPrefix);
}

String? _extractMultiplierPrefix(String normalizedBaseCoin) {
  const allowedMultipliers = <String>[
    '10',
    '100',
    '1000',
    '10000',
    '100000',
    '1000000',
  ];

  for (final prefix in allowedMultipliers) {
    if (!normalizedBaseCoin.startsWith(prefix) ||
        normalizedBaseCoin.length == prefix.length) {
      continue;
    }

    final candidate = normalizedBaseCoin.substring(prefix.length);
    if (RegExp(r'^[A-Z]+$').hasMatch(candidate)) {
      return prefix;
    }
  }

  return null;
}

double? _calculateDistanceFromAthPct(double currentPrice, double? athPrice) {
  if (athPrice == null || athPrice <= 0) {
    return null;
  }

  return ((currentPrice / athPrice) - 1) * 100;
}

Future<String> analyzeCoin(String rawTicker) async {
  final normalizedTicker = rawTicker.trim().toUpperCase();
  if (normalizedTicker.isEmpty) {
    return 'Send a valid coin ticker.';
  }

  try {
    final instruments = await ApiService.getAllBybitLinearInstruments();
    final matchingInstruments = instruments.where((instrument) {
      final generatedTicker = _generateTickerFromBaseCoin(instrument.baseCoin);
      return generatedTicker == normalizedTicker;
    }).toList();

    if (matchingInstruments.isEmpty) {
      return 'Ticker $normalizedTicker was not found on Bybit linear futures.';
    }

    final instrument = _selectInstrumentForTicker(
      matchingInstruments,
      normalizedTicker,
    );
    final normalizedSymbol = instrument.symbol;

    final tickers = await ApiService.getBybitTickers();
    final bybitTicker = tickers.result.list
        .where((item) => item.symbol == normalizedSymbol)
        .firstOrNull;
    if (bybitTicker == null) {
      return 'Symbol $normalizedSymbol was not found on Bybit linear futures.';
    }

    BotState.generatedTickerCache.putIfAbsent(
      normalizedSymbol,
      () => _generateTickerFromBaseCoin(instrument.baseCoin),
    );

    final generatedTicker = BotState.generatedTickerCache[normalizedSymbol]!;
    final marketData = await ApiService.getCoinGeckoMarketData([
      generatedTicker,
    ]);
    final coinGeckoMarketData = marketData[generatedTicker.toUpperCase()];
    final circulatingSupply = coinGeckoMarketData?.circulatingSupply;

    if (circulatingSupply == null || circulatingSupply <= BigInt.zero) {
      return 'No CoinGecko supply match for $normalizedSymbol.';
    }

    BotState.circulatingSupplyCache[normalizedSymbol] = circulatingSupply;

    final currentPrice = double.tryParse(bybitTicker.lastPrice);
    if (currentPrice == null) {
      return 'Could not parse price for $normalizedSymbol.';
    }

    final baseCoinMultiplier = _extractBaseCoinMultiplier(instrument.baseCoin);
    final normalizedPrice = currentPrice / baseCoinMultiplier;
    final scaledPrice = BigInt.from((normalizedPrice * 1e12).round());
    final scaledMarketCap = circulatingSupply * scaledPrice;
    final marketCapBigInt = scaledMarketCap ~/ BigInt.from(1e12.toInt());
    final marketCap = marketCapBigInt.toDouble();
    final distanceFromAthPct = _calculateDistanceFromAthPct(
      normalizedPrice,
      coinGeckoMarketData?.ath,
    );

    final orderbook = await ApiService.getBybitOrderbook(normalizedSymbol);
    final analysis = CoinAnalysisService.analyze(
      ticker: bybitTicker,
      instrument: instrument,
      orderbook: orderbook,
      generatedTicker: generatedTicker,
      marketCap: marketCap,
      athPrice: coinGeckoMarketData?.ath,
      distanceFromAthPct: distanceFromAthPct,
    );

    final riskLabel = switch (analysis.riskLevel) {
      CoinRiskLevel.low => 'LOW',
      CoinRiskLevel.medium => 'MEDIUM',
      CoinRiskLevel.high => 'HIGH',
    };

    return [
      '<b>${analysis.symbol}</b> (${analysis.generatedTicker})',
      '<b>Risk:</b> $riskLabel (${analysis.riskScore}/100)',
      '<b>Price:</b> ${formatUsdPrice(normalizedPrice)}',
      '<b>Market Cap:</b> ${formatCompactUsd(analysis.marketCap)}',
      '<b>ATH:</b> ${analysis.athPrice == null ? 'n/a' : formatUsdPrice(analysis.athPrice!)}',
      '<b>Distance from ATH:</b> ${formatPercentValue(analysis.distanceFromAthPct)}',
      '<b>Visible Depth:</b> ${analysis.visibleDepthUsd == null ? 'n/a' : formatCompactUsd(analysis.visibleDepthUsd!)}',
      '<b>Visible Depth vs Market Cap:</b> ${formatRatioAsPercent(analysis.visibleDepthToMarketCapRatio)}',
    ].join('\n');
  } on RateLimitedException catch (e) {
    return e.message;
  }
}

String getAnalyzeFaqMessage() {
  return [
    '<b>Как читать /analyze</b>',
    '',
    '<b>Risk</b>:',
    'LOW означает, что рынок сейчас не выглядит явно подозрительным по ключевым признакам.',
    'MEDIUM означает, что структура уже слабая и входить нужно осторожно.',
    'HIGH означает, что монета выглядит опасной для авто-шорта и легко двигаемой.',
    '',
    '<b>Market Cap</b>:',
    'Это капитализация на бумаге. Сама по себе она не доказывает, что рынок монеты реально глубокий и устойчивый.',
    '',
    '<b>ATH</b>:',
    'Исторический максимум цены. Нужен как контекст, чтобы понимать, насколько монета далеко от прошлой эйфории.',
    '',
    '<b>Distance from ATH</b>:',
    'Показывает, на сколько процентов текущая цена ниже исторического максимума.',
    '',
    '<b>Visible Depth</b>:',
    'Это видимая ликвидность в стакане около текущей цены. Чем она меньше, тем легче двигать рынок.',
    '',
    '<b>Visible Depth vs Market Cap</b>:',
    'Главный показатель для этой проверки.',
    'Он показывает, насколько капитализация реально подкреплена ликвидностью в стакане.',
    'Очень низкое значение означает, что монета может выглядеть крупной по market cap, но торговаться как тонкий и легко манипулируемый рынок.',
    '',
  ].join('\n');
}

BybitInstrument _selectInstrumentForTicker(
  List<BybitInstrument> instruments,
  String ticker,
) {
  for (final instrument in instruments) {
    if (instrument.symbol == '${ticker}USDT') {
      return instrument;
    }
  }

  for (final instrument in instruments) {
    if (instrument.symbol == '${ticker}PERP') {
      return instrument;
    }
  }

  return instruments.first;
}

String _buildAlertMessage({
  required String symbol,
  required double change24h,
  required double currentPrice,
  required double threshold,
  required double marketCap,
}) {
  return [
    '<b>$symbol</b>',
    '<b>Price:</b> \$${currentPrice.toStringAsFixed(4)}',
    '<b>24h Change:</b> +${change24h.toStringAsFixed(2)}%',
    '<b>Market Cap:</b> ${formatCompactUsd(marketCap)}',
    '<b>Alert Threshold:</b> ${threshold.toStringAsFixed(1)}%',
  ].join('\n');
}
