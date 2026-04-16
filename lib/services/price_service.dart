import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import '../models/bybit_instrument_models.dart';
import '../models/coingecko_market_models.dart';
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

        BotState.generatedTickerCache[symbol] = generateTickerFromBaseCoin(
          instrument.baseCoin,
        );
        BotState.baseCoinCache[symbol] = instrument.baseCoin;
      }
    }

    final missingSymbols = filteredCoinList
        .map((ticker) => ticker.symbol)
        .where((symbol) => !BotState.marketCapCache.containsKey(symbol))
        .toList();

    final missingGeneratedTickers = missingSymbols
        .map((symbol) => BotState.generatedTickerCache[symbol])
        .whereType<String>()
        .toSet()
        .toList();

    if (missingGeneratedTickers.isNotEmpty) {
      print(
        'Fetching CoinGecko market data for ${missingGeneratedTickers.length} missing coins',
      );
      try {
        final marketDataResults =
            await BatchProcessor.batchProcess<
              Map<String, CoinGeckoMarketData>,
              String
            >(
              missingGeneratedTickers,
              ApiService.getCoinGeckoMarketData,
              delay: Config.batchProcessDelay,
            );

        final mergedMarketData = <String, CoinGeckoMarketData>{};
        for (final marketData in marketDataResults) {
          mergedMarketData.addAll(marketData);
        }

        for (final symbol in missingSymbols) {
          final generatedTicker = BotState.generatedTickerCache[symbol];
          if (generatedTicker == null) continue;
          final marketCap = mergedMarketData[generatedTicker]?.marketCap;
          if (marketCap != null && marketCap > 0) {
            BotState.marketCapCache[symbol] = marketCap;
          }
        }

        final notFoundSymbols = missingSymbols
            .where((symbol) => !BotState.marketCapCache.containsKey(symbol))
            .toList();
        if (notFoundSymbols.isNotEmpty) {
          print('No CoinGecko market cap match for: $notFoundSymbols');
        }

        print(
          'Total CoinGecko market caps cached: ${BotState.marketCapCache.length}',
        );
      } catch (e) {
        print('ERROR: CoinGecko market data lookup failed: $e');
        alerts.add(
          '⚠️ CoinGecko market data lookup failed for some filtered coins',
        );
      }
    }

    for (final ticker in filteredCoinList) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      final double? marketCap = BotState.marketCapCache[ticker.symbol];

      if (marketCap != null && marketCap > 0) {
        final double currentPrice = double.parse(ticker.lastPrice);
        final baseCoin = BotState.baseCoinCache[ticker.symbol];
        final displayPrice = baseCoin == null
            ? currentPrice
            : normalizeContractPrice(currentPrice, baseCoin);

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
                currentPrice: displayPrice,
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

String generateTickerFromBaseCoin(String baseCoin) {
  final normalizedBaseCoin = baseCoin.trim().toUpperCase();
  final multiplierPrefix = extractMultiplierPrefix(normalizedBaseCoin);
  if (multiplierPrefix != null) {
    return normalizedBaseCoin.substring(multiplierPrefix.length);
  }

  return normalizedBaseCoin;
}

int extractBaseCoinMultiplier(String baseCoin) {
  final normalizedBaseCoin = baseCoin.trim().toUpperCase();
  final multiplierPrefix = extractMultiplierPrefix(normalizedBaseCoin);
  if (multiplierPrefix == null) {
    return 1;
  }

  return int.parse(multiplierPrefix);
}

String? extractMultiplierPrefix(String normalizedBaseCoin) {
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

double normalizeContractPrice(double contractPrice, String baseCoin) {
  return contractPrice / extractBaseCoinMultiplier(baseCoin);
}

double? calculateDistanceFromAthPct(double currentPrice, double? athPrice) {
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
    final matchingInstruments = await _findAnalyzeInstruments(normalizedTicker);

    if (matchingInstruments.isEmpty) {
      return 'Ticker $normalizedTicker was not found on Bybit linear futures.';
    }

    final instrument = _selectInstrumentForTicker(
      matchingInstruments,
      normalizedTicker,
    );
    final normalizedSymbol = instrument.symbol;

    final bybitTicker = await ApiService.getBybitTickerBySymbol(
      normalizedSymbol,
    );
    if (bybitTicker == null) {
      return 'Symbol $normalizedSymbol was not found on Bybit linear futures.';
    }

    BotState.generatedTickerCache.putIfAbsent(
      normalizedSymbol,
      () => generateTickerFromBaseCoin(instrument.baseCoin),
    );

    final generatedTicker = BotState.generatedTickerCache[normalizedSymbol]!;
    final marketData = await ApiService.getCoinGeckoMarketData([
      generatedTicker,
    ]);
    final coinGeckoMarketData = marketData[generatedTicker.toUpperCase()];
    final marketCap = coinGeckoMarketData?.marketCap;

    if (marketCap == null || marketCap <= 0) {
      return 'No CoinGecko market cap match for $normalizedSymbol.';
    }

    BotState.baseCoinCache[normalizedSymbol] = instrument.baseCoin;
    BotState.marketCapCache[normalizedSymbol] = marketCap;

    final currentPrice = double.tryParse(bybitTicker.lastPrice);
    if (currentPrice == null) {
      return 'Could not parse price for $normalizedSymbol.';
    }

    final normalizedPrice = normalizeContractPrice(
      currentPrice,
      instrument.baseCoin,
    );
    final distanceFromAthPct = calculateDistanceFromAthPct(
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

Future<List<BybitInstrument>> _findAnalyzeInstruments(
  String normalizedTicker,
) async {
  for (final candidateBaseCoin in _buildAnalyzeBaseCoinCandidates(
    normalizedTicker,
  )) {
    final instruments = await ApiService.getBybitLinearInstrumentsByBaseCoin(
      candidateBaseCoin,
    );
    final matchingInstruments = instruments
        .where((instrument) {
          return generateTickerFromBaseCoin(instrument.baseCoin) ==
              normalizedTicker;
        })
        .toList(growable: false);

    if (matchingInstruments.isNotEmpty) {
      return matchingInstruments;
    }
  }

  return const <BybitInstrument>[];
}

List<String> _buildAnalyzeBaseCoinCandidates(String normalizedTicker) {
  const allowedMultipliers = <String>[
    '10',
    '100',
    '1000',
    '10000',
    '100000',
    '1000000',
  ];

  return <String>[
    normalizedTicker,
    ...allowedMultipliers.map((prefix) => '$prefix$normalizedTicker'),
  ];
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
