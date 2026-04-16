import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bybit_models.dart';
import '../models/bybit_instrument_models.dart';
import '../models/bybit_orderbook_models.dart';
import '../models/coingecko_market_models.dart';

class RateLimitedException implements Exception {
  final String message;

  const RateLimitedException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _bybitBaseUrl = 'https://api.bybit.com';
  static http.Client _httpClient = http.Client();

  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  static void resetHttpClient() {
    _httpClient = http.Client();
  }

  static Future<BybitResponse> getBybitTickers() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_bybitBaseUrl/v5/market/tickers?category=linear'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Bybit tickers: ${response.statusCode}',
        );
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return BybitResponse.fromJson(jsonData);
    } catch (e) {
      print('ERROR: Bybit API call failed: $e');
      rethrow;
    }
  }

  static Future<BybitTicker?> getBybitTickerBySymbol(String symbol) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
          '$_bybitBaseUrl/v5/market/tickers?category=linear&symbol=${symbol.trim().toUpperCase()}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Bybit ticker for $symbol: ${response.statusCode}',
        );
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final parsed = BybitResponse.fromJson(jsonData);
      return parsed.result.list.firstOrNull;
    } catch (e) {
      print('ERROR: Bybit ticker API call failed for $symbol: $e');
      rethrow;
    }
  }

  static Future<Map<String, BigInt>> getCoinGeckoCirculatingSupply(
    List<String> symbols,
  ) async {
    final marketData = await getCoinGeckoMarketData(symbols);
    final circulatingSupplies = <String, BigInt>{};
    for (final entry in marketData.entries) {
      final supply = entry.value.circulatingSupply;
      if (supply != null) {
        circulatingSupplies[entry.key] = supply;
      }
    }

    return circulatingSupplies;
  }

  static Future<Map<String, CoinGeckoMarketData>> getCoinGeckoMarketData(
    List<String> symbols,
  ) async {
    if (symbols.isEmpty) return {};

    try {
      final symbolsParam = symbols.join(',');
      final response = await _httpClient.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=$symbolsParam',
        ),
      );

      if (response.statusCode == 429) {
        throw RateLimitedException(
          'CoinGecko error 429: ${response.body}',
        );
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch CoinGecko data: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as List<dynamic>;
      final marketData = <String, CoinGeckoMarketData>{};

      for (final coin in data) {
        final parsed = CoinGeckoMarketData.fromJson(
          coin as Map<String, dynamic>,
        );
        if (parsed.symbol.isNotEmpty) {
          marketData[parsed.symbol] = parsed;
        }
      }

      return marketData;
    } catch (e) {
      print('ERROR: CoinGecko API call failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, BybitInstrument>> getBybitInstrumentsBySymbols(
    List<String> symbols,
  ) async {
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
      final response = await _httpClient.get(
        Uri.parse(
          '$_bybitBaseUrl/v5/market/instruments-info?category=linear&limit=1000${cursor.isNotEmpty ? '&cursor=$cursor' : ''}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Bybit instruments: ${response.statusCode}',
        );
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

  static Future<List<BybitInstrument>> getBybitLinearInstrumentsByBaseCoin(
    String baseCoin,
  ) async {
    final normalizedBaseCoin = baseCoin.trim().toUpperCase();
    if (normalizedBaseCoin.isEmpty) {
      return const <BybitInstrument>[];
    }

    final response = await _httpClient.get(
      Uri.parse(
        '$_bybitBaseUrl/v5/market/instruments-info?category=linear&baseCoin=$normalizedBaseCoin',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch Bybit instruments for $normalizedBaseCoin: ${response.statusCode}',
      );
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    final result = jsonData['result'] as Map<String, dynamic>? ?? const {};
    final list = result['list'] as List<dynamic>? ?? const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(BybitInstrument.fromJson)
        .toList(growable: false);
  }

  static Future<List<BybitInstrument>> getAllBybitLinearInstruments() async {
    final instruments = <BybitInstrument>[];
    String cursor = '';

    while (true) {
      final response = await _httpClient.get(
        Uri.parse(
          '$_bybitBaseUrl/v5/market/instruments-info?category=linear&limit=1000${cursor.isNotEmpty ? '&cursor=$cursor' : ''}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Bybit instruments: ${response.statusCode}',
        );
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final result = jsonData['result'] as Map<String, dynamic>? ?? const {};
      final list = result['list'] as List<dynamic>? ?? const [];

      for (final item in list.whereType<Map<String, dynamic>>()) {
        instruments.add(BybitInstrument.fromJson(item));
      }

      cursor = result['nextPageCursor']?.toString() ?? '';
      if (cursor.isEmpty) {
        break;
      }
    }

    return instruments;
  }

  static Future<BybitOrderbook> getBybitOrderbook(
    String symbol, {
    int limit = 50,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_bybitBaseUrl/v5/market/orderbook?category=linear&symbol=$symbol&limit=$limit',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch Bybit orderbook for $symbol: ${response.statusCode}',
      );
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return BybitOrderbook.fromJson(jsonData);
  }
}
