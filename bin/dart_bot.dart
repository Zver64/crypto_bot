import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';
import 'package:http/http.dart' as http;

final Set<int> subscribers = <int>{};

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
  final DotEnv env = DotEnv()..load();
  
  final String? token = env['BOT_TOKEN'] ?? Platform.environment['BOT_TOKEN'];
  if (token == null) {
    print('BOT_TOKEN not found');
    exit(1);
  }
  
  final Bot bot = Bot(token);
  
  bot.command('start', (ctx) => ctx.reply('Welcome! Use /subscribe to get 100% price alerts'));
  
  bot.command('subscribe', (ctx) async {
    subscribers.add(ctx.from!.id);
    ctx.reply('✅ Subscribed to 100% price alerts!');
    await checkPrices(bot);
  });
  
  bot.command('unsubscribe', (ctx) {
    subscribers.remove(ctx.from!.id);
    ctx.reply('❌ Unsubscribed from price alerts');
  });
  
  Timer.periodic(const Duration(minutes: 5), (Timer _) => checkPrices(bot));
  
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
      
      if (change24h >= 20) {
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
