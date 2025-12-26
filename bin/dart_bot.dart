import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';
import 'package:http/http.dart' as http;

Set<int> subscribers = {};

void main() {
  var env = DotEnv()..load();
  
  final token = env['BOT_TOKEN'] ?? Platform.environment['BOT_TOKEN'];
  if (token == null) {
    print('BOT_TOKEN not found');
    exit(1);
  }
  
  final bot = Bot(token);
  
  bot.command('start', (ctx) => ctx.reply('Welcome! Use /subscribe to get 100% price alerts'));
  
  bot.command('subscribe', (ctx) async {
    subscribers.add(ctx.from!.id);
    ctx.reply('✅ Subscribed to 100% price alerts!');
    // Immediate check when subscribing
    await checkPrices(bot);
  });
  
  bot.command('unsubscribe', (ctx) {
    subscribers.remove(ctx.from!.id);
    ctx.reply('❌ Unsubscribed from price alerts');
  });
  
  // Start price monitoring BEFORE bot.start()
  Timer.periodic(Duration(minutes: 5), (_) => checkPrices(bot));
  
  bot.start();
}

Future<void> checkPrices(Bot bot) async {
  print('getting price ...');
  try {
    final response = await http.get(Uri.parse('https://api.bybit.com/v5/market/tickers?category=spot'));
    final data = json.decode(response.body);
    print('the data: $data');
    
    for (final ticker in data['result']['list']) {
      String symbol = ticker['symbol'];
      double change24h = double.parse(ticker['price24hPcnt']) * 100;
      
      if (change24h >= 100) {
        double currentPrice = double.parse(ticker['lastPrice']);
        String message = '🚀 ALERT: $symbol is up ${change24h.toStringAsFixed(2)}% in 24h!\nPrice: \$${currentPrice.toStringAsFixed(4)}';
        
        for (int userId in subscribers) {
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
