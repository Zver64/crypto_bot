import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:televerse/televerse.dart';
import '../models/bybit_models.dart';

Future<void> checkPrices(Bot bot, Set<int> subscribers, double priceThreshold) async {
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

        final List<int> usersToRemove = [];
        
        for (final int userId in subscribers) {
          try {
            await bot.api.sendMessage(ChatID(userId), message);
          } catch (e) {
            print('Failed to send to $userId: $e - Auto-unsubscribing');
            usersToRemove.add(userId);
          }
        }
        
        // Remove users who couldn't receive messages
        for (final int userId in usersToRemove) {
          subscribers.remove(userId);
        }
        
        if (usersToRemove.isNotEmpty) {
          print('Auto-unsubscribed ${usersToRemove.length} unreachable users');
        }
      }
    }
    print('finished price check');
  } catch (e) {
    print('Error checking prices: $e');
  }
}
