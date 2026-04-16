import 'dart:convert';

import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import '../models/coingecko_market_models.dart';
import '../models/coin_analysis_models.dart';
import '../services/bot_state.dart';
import '../services/api_service.dart';
import '../services/batch_processor.dart';
import '../services/coin_analysis_service.dart';
import '../utils/common.dart';
import '../config/app_config.dart';

class AnalyzeCoinSelection {
  final String requestedTicker;
  final List<CoinGeckoMarketData> candidates;

  const AnalyzeCoinSelection({
    required this.requestedTicker,
    required this.candidates,
  });

  bool get hasSingleCandidate => candidates.length == 1;
}

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
          smallMcap: threshold.minMarketCap,
          smallVol: threshold.minCap.toDouble(),
          largeMcap: threshold.maxMarketCap,
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
  try {
    final selection = await getAnalyzeCoinSelection(rawTicker);
    if (selection.candidates.isEmpty) {
      return 'No CoinGecko market data match for ${selection.requestedTicker}.';
    }

    if (!selection.hasSingleCandidate) {
      return 'Multiple CoinGecko matches found for ${selection.requestedTicker}.';
    }

    return analyzeCoinById(selection.candidates.first.id);
  } on RateLimitedException catch (e) {
    return e.message;
  }
}

Future<AnalyzeCoinSelection> getAnalyzeCoinSelection(String rawTicker) async {
  final normalizedTicker = rawTicker.trim().toUpperCase();
  if (normalizedTicker.isEmpty) {
    return const AnalyzeCoinSelection(
      requestedTicker: '',
      candidates: <CoinGeckoMarketData>[],
    );
  }

  final marketCandidates = await ApiService.getCoinGeckoMarketDataBySymbol(
    normalizedTicker,
  );
  final exactMatches = _selectCoinGeckoMarketDataCandidates(
    marketCandidates,
    normalizedTicker,
  );

  return AnalyzeCoinSelection(
    requestedTicker: normalizedTicker,
    candidates: exactMatches,
  );
}

Future<String> analyzeCoinById(String coinId) async {
  final normalizedCoinId = coinId.trim();
  if (normalizedCoinId.isEmpty) {
    return 'Send a valid CoinGecko coin id.';
  }

  try {
    final marketData = await ApiService.getCoinGeckoMarketDataById(
      normalizedCoinId,
    );

    if (marketData == null) {
      return 'No CoinGecko market data match for $normalizedCoinId.';
    }

    final marketCap = marketData.marketCap;
    if (marketCap == null || marketCap <= 0) {
      return 'No CoinGecko market cap match for ${marketData.symbol}.';
    }

    final currentPrice = marketData.currentPrice;
    if (currentPrice == null || currentPrice <= 0) {
      return 'Could not parse CoinGecko price for ${marketData.symbol}.';
    }

    final distanceFromAthPct = calculateDistanceFromAthPct(
      currentPrice,
      marketData.ath,
    );

    final tickers = await ApiService.getCoinGeckoCoinTickers(marketData.id);
    final analysis = CoinAnalysisService.analyze(
      marketData: marketData,
      tickers: tickers,
      distanceFromAthPct: distanceFromAthPct,
    );

    final explosiveUpsideLabel = switch (analysis.explosiveUpsideLevel) {
      ExplosiveUpsideLevel.low => 'LOW',
      ExplosiveUpsideLevel.medium => 'MEDIUM',
      ExplosiveUpsideLevel.high => 'HIGH',
      ExplosiveUpsideLevel.extreme => 'EXTREME',
    };
    final dataConfidenceLabel = switch (analysis.dataConfidenceLevel) {
      DataConfidenceLevel.low => 'LOW',
      DataConfidenceLevel.medium => 'MEDIUM',
      DataConfidenceLevel.high => 'HIGH',
    };
    final escapedName = const HtmlEscape().convert(analysis.name);

    return [
      '<b>$escapedName</b> (${analysis.symbol})',
      '<b>Explosive Upside Potential:</b> $explosiveUpsideLabel (${analysis.explosiveUpsideScore}/100)',
      '<b>Data Confidence:</b> $dataConfidenceLabel (${analysis.dataConfidenceScore}/100)',
      '<b>Price:</b> ${formatUsdPrice(currentPrice)}',
      '<b>Market Cap:</b> ${formatCompactUsd(analysis.marketCap)}',
      '<b>ATH:</b> ${analysis.athPrice == null ? 'n/a' : formatUsdPrice(analysis.athPrice!)}',
      '<b>Distance from ATH:</b> ${formatPercentValue(analysis.distanceFromAthPct)}',
      '<b>24h Volume:</b> ${analysis.volume24hUsd == null ? 'n/a' : formatCompactUsd(analysis.volume24hUsd!)}',
      '<b>Upward 2% Depth:</b> ${analysis.upsideDepthUsd == null ? 'n/a' : formatCompactUsd(analysis.upsideDepthUsd!)}',
      '<b>Upward Depth vs Market Cap:</b> ${formatRatioAsPercent(analysis.upsideDepthToMarketCapRatio)}',
      '<b>Upward Depth vs 24h Volume:</b> ${formatRatioAsPercent(analysis.upsideDepthToVolumeRatio)}',
      '<b>Top Venue Volume Share:</b> ${formatRatioAsPercent(analysis.topVenueVolumeShare)}',
      '<b>Top Venue Upward Depth Share:</b> ${formatRatioAsPercent(analysis.topVenueUpsideDepthShare)}',
      '<b>Pump Drivers:</b> ${analysis.findings.join('; ')}',
      '<b>Constraints:</b> ${analysis.constraints.join('; ')}',
    ].join('\n');
  } on RateLimitedException catch (e) {
    return e.message;
  }
}

String getAnalyzeFaqMessage() {
  return [
    '<b>Как читать /analyze</b>',
    '',
    '<b>Explosive Upside Potential</b>:',
    'Это оценка того, насколько монета структурно пригодна для резкого неестественного роста вверх.',
    'LOW означает, что по данным CoinGecko рынок не выглядит легко пампуемым.',
    'MEDIUM означает, что отдельные сигналы хрупкости уже есть.',
    'HIGH и EXTREME означают, что вверх цену потенциально можно сдвигать заметно легче, чем кажется по market cap.',
    'Больше = хуже с точки зрения риска пампа вверх.',
    '',
    '<b>Data Confidence</b>:',
    'Это оценка качества входных данных CoinGecko.',
    'Если confidence низкий, вывод по pump potential нужно трактовать осторожно, потому что usable ticker/depth данных мало.',
    'Больше = лучше, потому что вывод надёжнее.',
    '',
    '<b>Market Cap</b>:',
    'Это капитализация на бумаге. Сама по себе она не доказывает, что рынок монеты реально глубокий и устойчивый.',
    'При прочих равных меньше = хуже, потому что маленькую капитализацию легче разгонять.',
    '',
    '<b>ATH</b>:',
    'Исторический максимум цены. Нужен как контекст, чтобы понимать, насколько монета далеко от прошлой эйфории.',
    'Это просто ориентир, не good/bad метрика сама по себе.',
    '',
    '<b>Distance from ATH</b>:',
    'Показывает, на сколько процентов текущая цена ниже исторического максимума.',
    'Сильнее ниже ATH = выше пространство для рефлексивного роста, но это слабый вспомогательный сигнал.',
    '',
    '<b>24h Volume</b>:',
    'Это агрегированный объём торгов за 24 часа по данным CoinGecko.',
    'Сам по себе объём не good/bad: его нужно читать только вместе с глубиной.',
    '',
    '<b>Upward 2% Depth</b>:',
    'Это оценка того, сколько USD нужно, чтобы сдвинуть цену вверх примерно на 2% по usable CoinGecko venues.',
    'Меньше = хуже, потому что цену легче толкнуть вверх.',
    '',
    '<b>Upward Depth vs Market Cap</b>:',
    'Показывает, насколько рыночная капитализация подкреплена реальной глубиной именно на движении вверх.',
    'Меньше = хуже, потому что market cap слабее подкреплён реальной ликвидностью.',
    '',
    '<b>Upward Depth vs 24h Volume</b>:',
    'Показывает, насколько текущий торговый поток уже велик относительно глубины, которую нужно пройти для дальнейшего роста.',
    'Меньше = хуже, потому что текущий поток сильнее давит на тонкий рынок.',
    '',
    '<b>Top Venue Volume Share / Top Venue Upward Depth Share</b>:',
    'Показывают, насколько объём и глубина сконцентрированы на одной площадке.',
    'Чем выше концентрация, тем легче локально сделать сильное движение, не имея широкого рыночного участия.',
    'Больше = хуже, потому что рынок менее распределён.',
    '',
  ].join('\n');
}

List<CoinGeckoMarketData> _selectCoinGeckoMarketDataCandidates(
  List<CoinGeckoMarketData> candidates,
  String normalizedTicker,
) {
  final exactMatches = candidates
      .where((candidate) => candidate.symbol == normalizedTicker)
      .toList(growable: false);

  if (exactMatches.length <= 1) {
    return exactMatches;
  }

  exactMatches.sort((left, right) {
    final leftMarketCap = left.marketCap ?? 0;
    final rightMarketCap = right.marketCap ?? 0;
    return rightMarketCap.compareTo(leftMarketCap);
  });

  return <CoinGeckoMarketData>[exactMatches.first];
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
