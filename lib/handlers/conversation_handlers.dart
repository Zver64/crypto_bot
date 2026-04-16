import 'dart:math';

import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/plugins/conversation.dart';
import '../models/coingecko_market_models.dart';
import '../services/bot_state.dart';
import '../services/price_service.dart';
import '../utils/common.dart';

Future<void> setThresholdHandler(Conversation conversation, Context ctx) async {
  await ctx.reply('Send me the min cap threshold (e.g., 200):');

  final minCapResponse = await conversation.waitFor(
    (ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''),
  );
  final int? minCap = int.tryParse(minCapResponse.text ?? '');

  if (minCap == null || minCap <= 0) {
    await minCapResponse.reply(
      'Invalid min cap. Please enter a positive integer.',
    );
    return;
  }

  await minCapResponse.reply('Send me the max cap threshold (e.g., 10):');

  final maxCapResponse = await conversation.waitFor(
    (ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''),
  );
  final int? maxCap = int.tryParse(maxCapResponse.text ?? '');

  if (maxCap != null && maxCap > 0) {
    BotState.setThreshold(minCap, maxCap);
    final threshold = BotState.priceThreshold;
    final midpointMarketCap = sqrt(
      threshold.minMarketCap * threshold.maxMarketCap,
    );
    await maxCapResponse.reply('''
🎯 *Thresholds Updated Successfully!*

📊 *Current Settings:*
• Min Cap Threshold: $minCap%
• Max Cap Threshold: $maxCap%
• Min Market Cap: ${formatCompactUsd(threshold.minMarketCap)}
• Max Market Cap: ${formatCompactUsd(threshold.maxMarketCap)}

📈 *Example Calculations:*
• ${formatCompactUsd(threshold.minMarketCap)} market cap → ${volatilityFromMcap(threshold.minMarketCap, smallMcap: threshold.minMarketCap, smallVol: minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold
• ${formatCompactUsd(midpointMarketCap)} market cap → ${volatilityFromMcap(midpointMarketCap, smallMcap: threshold.minMarketCap, smallVol: minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold
• ${formatCompactUsd(threshold.maxMarketCap)} market cap → ${volatilityFromMcap(threshold.maxMarketCap, smallMcap: threshold.minMarketCap, smallVol: minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold

✅ *Bot will now alert when coins exceed their calculated thresholds!*
''');
  } else {
    await maxCapResponse.reply(
      'Invalid max cap. Please enter a positive integer.',
    );
  }
}

Future<void> setMarketCapHandler(Conversation conversation, Context ctx) async {
  await ctx.reply(
    'Send me the min market cap anchor in USD (e.g., 50000000 for \$50M):',
  );

  final minMarketCapResponse = await conversation.waitFor(
    (ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''),
  );
  final int? minMarketCap = int.tryParse(minMarketCapResponse.text ?? '');

  if (minMarketCap == null || minMarketCap <= 0) {
    await minMarketCapResponse.reply(
      'Invalid min market cap. Please enter a positive integer in USD.',
    );
    return;
  }

  await minMarketCapResponse.reply(
    'Send me the max market cap anchor in USD (e.g., 2000000000000 for \$2T):',
  );

  final maxMarketCapResponse = await conversation.waitFor(
    (ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''),
  );
  final int? maxMarketCap = int.tryParse(maxMarketCapResponse.text ?? '');

  if (maxMarketCap == null ||
      maxMarketCap <= 0 ||
      maxMarketCap <= minMarketCap) {
    await maxMarketCapResponse.reply(
      'Invalid max market cap. Please enter a positive integer greater than the min market cap.',
    );
    return;
  }

  BotState.setMinMarketCap(minMarketCap.toDouble());
  BotState.setMaxMarketCap(maxMarketCap.toDouble());
  final threshold = BotState.priceThreshold;
  final midpointMarketCap = sqrt(threshold.minMarketCap * threshold.maxMarketCap);
  await maxMarketCapResponse.reply('''
🎯 *Market Cap Anchors Updated Successfully!*

📊 *Current Settings:*
• Min Market Cap: ${formatCompactUsd(threshold.minMarketCap)}
• Max Market Cap: ${formatCompactUsd(threshold.maxMarketCap)}
• Min Cap Threshold: ${threshold.minCap}%
• Max Cap Threshold: ${threshold.maxCap}%

📈 *Example Calculations:*
• ${formatCompactUsd(threshold.minMarketCap)} market cap → ${volatilityFromMcap(threshold.minMarketCap, smallMcap: threshold.minMarketCap, smallVol: threshold.minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: threshold.maxCap.toDouble()).toStringAsFixed(1)}% threshold
• ${formatCompactUsd(midpointMarketCap)} market cap → ${volatilityFromMcap(midpointMarketCap, smallMcap: threshold.minMarketCap, smallVol: threshold.minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: threshold.maxCap.toDouble()).toStringAsFixed(1)}% threshold
• ${formatCompactUsd(threshold.maxMarketCap)} market cap → ${volatilityFromMcap(threshold.maxMarketCap, smallMcap: threshold.minMarketCap, smallVol: threshold.minCap.toDouble(), largeMcap: threshold.maxMarketCap, largeVol: threshold.maxCap.toDouble()).toStringAsFixed(1)}% threshold
''');
}

Future<void> analyzeCoinHandler(Conversation conversation, Context ctx) async {
  await ctx.reply('Send the coin ticker to analyze, e.g. BTC, SIREN, PEPE:');

  final symbolResponse = await conversation.waitFor(
    (ctx) => (ctx.text ?? '').trim().isNotEmpty,
  );

  final ticker = (symbolResponse.text ?? '').trim().toUpperCase();
  final selection = await getAnalyzeCoinSelection(ticker);

  if (selection.requestedTicker.isEmpty) {
    await symbolResponse.reply('Send a valid coin ticker.');
    return;
  }

  if (selection.candidates.isEmpty) {
    await symbolResponse.reply(
      'No CoinGecko market data match for ${selection.requestedTicker}.',
    );
    return;
  }

  if (selection.hasSingleCandidate) {
    final message = await analyzeCoinById(selection.candidates.first.id);
    await symbolResponse.reply(message, parseMode: ParseMode.html);
    return;
  }

  await symbolResponse.reply(
    'Multiple CoinGecko matches found for ${selection.requestedTicker}. Choose by symbol, name, price, and market cap:',
    replyMarkup: InlineKeyboardMarkup(
      inlineKeyboard: selection.candidates
          .map((candidate) => <InlineKeyboardButton>[
                InlineKeyboardButton(
                  text: _buildAnalyzeCoinOptionLabel(candidate),
                  callbackData: 'analyze:${candidate.id}',
                ),
              ])
          .toList(growable: false),
    ),
  );
}

String _buildAnalyzeCoinOptionLabel(CoinGeckoMarketData candidate) {
  final priceLabel = candidate.currentPrice == null
      ? 'price n/a'
      : 'price ${formatUsdPrice(candidate.currentPrice!)}';
  final marketCapLabel = candidate.marketCap == null || candidate.marketCap! <= 0
      ? 'mcap n/a'
      : 'mcap ${formatCompactUsd(candidate.marketCap!)}';

  return '${candidate.symbol} - ${candidate.name} | $priceLabel | $marketCapLabel';
}
