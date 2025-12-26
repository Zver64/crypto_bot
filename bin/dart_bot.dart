import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';
import 'package:http/http.dart' as http;

final Set<int> subscribers = <int>{};
double priceThreshold = 25;
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
        .map((Object? item) => BybitTicker.fromJson(item as Map<String, Object?>))
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
    try {
      final DotEnv env = DotEnv()..load();
      token = env['BOT_TOKEN'];
    } catch (e) {
      // .env file not found
    }
  }
  
  if (token == null) {
    print('BOT_TOKEN not found in environment or .env file');
    exit(1);
  }
  
  final Bot bot = Bot(token);
  
  bot.command('start', (ctx) => ctx.reply('Welcome! Use /subscribe to get 100% price alerts'));
  
  bot.command('subscribe', (ctx) async {
    final bool wasEmpty = subscribers.isEmpty;
    subscribers.add(ctx.from!.id);
    ctx.reply('✅ Subscribed to $priceThreshold% price alerts!');
    
    if (wasEmpty) {
      await checkPrices(bot);
      priceCheckTimer = Timer.periodic(const Duration(minutes: 5), (Timer _) => checkPrices(bot));
      print('Started price monitoring');
    }
  });
  
  bot.command('unsubscribe', (ctx) {
    subscribers.remove(ctx.from!.id);
    ctx.reply('❌ Unsubscribed from price alerts');
    
    if (subscribers.isEmpty) {
      priceCheckTimer?.cancel();
      priceCheckTimer = null;
      print('Stopped price monitoring');
    }
  });
  
  bot.command('setthreshold', (ctx) {
    final String? args = ctx.message?.text?.split(' ').skip(1).join(' ');
    if (args == null || args.isEmpty) {
      ctx.reply('Usage: /setthreshold <percentage>\nCurrent threshold: ${priceThreshold.toStringAsFixed(1)}%');
      return;
    }
    
    final double? newThreshold = double.tryParse(args);
    if (newThreshold == null || newThreshold <= 0) {
      ctx.reply('Invalid percentage. Please enter a positive number.');
      return;
    }
    
    priceThreshold = newThreshold;
    ctx.reply('✅ Price threshold set to ${priceThreshold.toStringAsFixed(1)}%');
  });
  
  bot.start();
}

Future<void> checkPrices(Bot bot) async {
  print('Getting prices...');
  try {
    final http.Response response = await http.get(Uri.parse('https://api.bybit.com/v5/market/tickers?category=spot'));
    final Map<String, Object?> jsonData = json.decode(response.body) as Map<String, Object?>;
    final BybitResponse bybitResponse = BybitResponse.fromJson(jsonData);
    
    for (final BybitTicker ticker in bybitResponse.result.list) {
      final double change24h = double.parse(ticker.price24hPcnt) * 100;
      
      if (change24h >= priceThreshold) {
        final double currentPrice = double.parse(ticker.lastPrice);
        final String message = '🚀 ALERT: ${ticker.symbol} is up ${change24h.toStringAsFixed(2)}% in 24h!\nPrice: \$${currentPrice.toStringAsFixed(4)}';
        
        for (final int userId in subscribers) {
          try {
            await bot.api.sendMessage(ChatID(userId), message);
          } catch (e) {
            print('Failed to send to $userId: $e');
          }
        }
      }
    }
  } catch (e) {
    print('Error checking prices: $e');
  }
}
