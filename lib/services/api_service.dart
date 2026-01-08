import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bybit_models.dart';

class ApiService {
  static Future<BybitResponse> getBybitTickers() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.bybit.com/v5/market/tickers?category=linear'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Bybit tickers: ${response.statusCode}');
      }
      
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return BybitResponse.fromJson(jsonData);
    } catch (e) {
      print('ERROR: Bybit API call failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, BigInt>> getCoinGeckoCirculatingSupply(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    
    try {
      final symbolsParam = symbols.join(',');
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=$symbolsParam'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch CoinGecko data: ${response.statusCode}');
      }
      
      final data = json.decode(response.body) as List<dynamic>;
      final circulatingSupplies = <String, BigInt>{};
      
      for (final coin in data) {
        final symbol = coin['symbol'].toString().toUpperCase();
        final circulatingSupply = coin['circulating_supply'];
        if (circulatingSupply != null) {
          circulatingSupplies[symbol] = BigInt.from(circulatingSupply.toDouble());
        }
      }
      
      return circulatingSupplies;
    } catch (e) {
      print('ERROR: CoinGecko API call failed: $e');
      rethrow;
    }
  }
}
