import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bybit_models.dart';
import '../models/bybit_instrument_models.dart';

class ApiService {
  static const String _bybitBaseUrl = 'https://api.bybit.com';

  static Future<BybitResponse> getBybitTickers() async {
    try {
      final response = await http.get(
        Uri.parse('$_bybitBaseUrl/v5/market/tickers?category=linear'),
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

  static Future<Map<String, BybitInstrument>> getBybitInstrumentsBySymbols(List<String> symbols) async {
    final requestedSymbols = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toSet();

    if (requestedSymbols.isEmpty) {
      return <String, BybitInstrument>{};
    }

    final instruments = <String, BybitInstrument>{};
    String cursor = '';

    while (true) {
      final response = await http.get(
        Uri.parse(
          '$_bybitBaseUrl/v5/market/instruments-info?category=linear&limit=1000${cursor.isNotEmpty ? '&cursor=$cursor' : ''}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Bybit instruments: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final result = jsonData['result'] as Map<String, dynamic>? ?? const {};
      final list = result['list'] as List<dynamic>? ?? const [];

      for (final item in list.whereType<Map<String, dynamic>>()) {
        final instrument = BybitInstrument.fromJson(item);
        if (requestedSymbols.contains(instrument.symbol)) {
          instruments[instrument.symbol] = instrument;
        }
      }

      if (instruments.length >= requestedSymbols.length) {
        break;
      }

      cursor = result['nextPageCursor']?.toString() ?? '';
      if (cursor.isEmpty) {
        break;
      }
    }

    return instruments;
  }
}
