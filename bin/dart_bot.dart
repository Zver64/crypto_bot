import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';
import 'package:http/http.dart' as http;

final Set<int> subscribers = <int>{};
double priceThreshold = 100;
Timer? priceCheckTimer;

class BybitTicker {
  final String symbol;
  final String lastPrice;
  final String price24hPcnt;

  const BybitTicker({
    required this.symbol,
    required this.lastPrice,
    required this.price24hPcnt,
  });

  factory BybitTicker.fromJson(Map<String, Object?> json) {
    return BybitTicker(
      symbol: json['symbol'] as String,
      lastPrice: json['lastPrice'] as String,
      price24hPcnt: json['price24hPcnt'] as String,
    );
  }
}

class BybitResult {
  final List<BybitTicker> list;

  const BybitResult({required this.list});

  factory BybitResult.fromJson(Map<String, Object?> json) {
    final List<Object?> tickerList = json['list'] as List<Object?>;
    final List<BybitTicker> tickers = tickerList
        .map(
          (Object? item) => BybitTicker.fromJson(item as Map<String, Object?>),
        )
        .toList();

    return BybitResult(list: tickers);
  }
}

class BybitResponse {
  final BybitResult result;

  const BybitResponse({required this.result});

  factory BybitResponse.fromJson(Map<String, Object?> json) {
    return BybitResponse(
      result: BybitResult.fromJson(json['result'] as Map<String, Object?>),
    );
  }
}

void main() {
  String? token = Platform.environment['BOT_TOKEN'];

  if (token == null) {
    final DotEnv env = DotEnv()..load();
    token = env['BOT_TOKEN'];
  }

  if (token == null) {
    print('BOT_TOKEN not found in environment or .env file');
    exit(1);
  }

  final Bot bot = Bot(token);

  bot.command('start', (ctx) => ctx.reply('Welcome! Use /menu to see available options.'));

  bot.command('menu', (ctx) => ctx.reply(
    'Available commands:\n'
    '/subscribe - Get price alerts\n'
    '/unsubscribe - Stop price alerts\n'
    '/setthreshold - Set price threshold\n'
    '/status - Check current settings'
  ));

  bot.command('subscribe', (ctx) async {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    final bool wasEmpty = subscribers.isEmpty;
    subscribers.add(userId);
    ctx.reply('✅ Subscribed to ${priceThreshold}% price alerts!');

    if (wasEmpty) {
      await checkPrices(bot);
      priceCheckTimer = Timer.periodic(
        const Duration(minutes: 5),
        (Timer _) => checkPrices(bot),
      );
      print('Started price monitoring');
    }
  });

  bot.command('unsubscribe', (ctx) {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    subscribers.remove(userId);
    ctx.reply('❌ Unsubscribed from price alerts');

    if (subscribers.isEmpty) {
      priceCheckTimer?.cancel();
      priceCheckTimer = null;
      print('Stopped price monitoring');
    }
  });

  bot.command('setthreshold', (ctx) {
    ctx.reply('Send me the threshold percentage (e.g., 50):');
  });

  bot.hears(RegExp(r'^\d+\.?\d*$'), (ctx) {
    final String text = ctx.message!.text!;
    final double? newThreshold = double.tryParse(text);
    
    if (newThreshold != null && newThreshold > 0) {
      priceThreshold = newThreshold;
      ctx.reply('✅ Price threshold set to ${priceThreshold.toStringAsFixed(1)}%');
    } else {
      ctx.reply('Invalid percentage. Please enter a positive number.');
    }
  });

  bot.command('status', (ctx) {
    ctx.reply(
      'Current settings:\n'
      'Threshold: ${priceThreshold.toStringAsFixed(1)}%\n'
      'Subscribers: ${subscribers.length}\n'
      'Monitoring: ${priceCheckTimer != null ? "Active" : "Inactive"}'
    );
  });

  bot.start();
}

Future<void> checkPrices(Bot bot) async {
  print('Getting prices...');
  try {
    final http.Response response = await http.get(
      Uri.parse('https://api.bybit.com/v5/market/tickers?category=linear'),
    );
    final Map<String, Object?> jsonData =
        json.decode(response.body) as Map<String, Object?>;
    final BybitResponse bybitResponse = BybitResponse.fromJson(jsonData);

    for (final BybitTicker ticker in bybitResponse.result.list) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;

      if (change24h >= priceThreshold) {
        final double currentPrice = double.parse(ticker.lastPrice);
        final String message =
            '🚀 ALERT: ${ticker.symbol} is up ${change24h.toStringAsFixed(2)}% in 24h!\nPrice: \$${currentPrice.toStringAsFixed(4)}';

        for (final int userId in subscribers) {
          try {
            await bot.api.sendMessage(ChatID(userId), message);
          } catch (e) {
            print('Failed to send to $userId: $e');
          }
        }
      }
    }
    print('finished price check');
  } catch (e) {
    print('Error checking prices: $e');
  }
}
