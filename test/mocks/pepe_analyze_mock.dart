import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient buildPepeAnalyzeMockClient() {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=pepe&include_tokens=all&order=market_cap_desc&precision=full') {
      return http.Response(_pepeCoinGeckoResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/pepe/tickers?depth=true&order=volume_desc&page=1') {
      return http.Response(_pepeTickersResponseJson, 200);
    }

    throw StateError('Unhandled PEPE analyze request: $url');
  });
}

const String pepeExpectedAnalyzeMessage =
    '<b>Pepe</b> (PEPE)\n'
    '<b>Risk:</b> LOW (16/100)\n'
    '<b>Price:</b> \$0.00000355\n'
    '<b>Market Cap:</b> \$1.49B\n'
    '<b>ATH:</b> \$0.00002803\n'
    '<b>Distance from ATH:</b> -87.33%\n'
    '<b>24h Volume:</b> \$308.93M\n'
    '<b>2% Market Depth:</b> \$2.50M\n'
    '<b>2% Depth vs Market Cap:</b> 0.167%';

const String _pepeCoinGeckoResponseJson =
    r'''[{"id":"pepe","symbol":"pepe","name":"Pepe","current_price":0.00000355,"market_cap":1493487640,"total_volume":308929089,"ath":0.00002803,"ath_change_percentage":-87.34049},{"id":"pepe-on-base","symbol":"pepe","name":"Pepe on Base","current_price":0.00000091,"market_cap":1200000,"total_volume":54000,"ath":0.0000018,"ath_change_percentage":-49.44}]''';

const String _pepeTickersResponseJson =
    r'''{"name":"Pepe","tickers":[{"base":"PEPE","target":"USDT","market":{"name":"Binance"},"cost_to_move_up_usd":3100000,"cost_to_move_down_usd":2100000,"converted_volume":{"usd":120000000},"is_anomaly":false,"is_stale":false},{"base":"PEPE","target":"USD","market":{"name":"Kraken"},"cost_to_move_up_usd":500000,"cost_to_move_down_usd":400000,"converted_volume":{"usd":35000000},"is_anomaly":false,"is_stale":false}]}''';
