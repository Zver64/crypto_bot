import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient buildSirenAnalyzeMockClient() {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=siren&include_tokens=all&order=market_cap_desc&precision=full') {
      return http.Response(_sirenCoinGeckoResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/siren-2/tickers?depth=true&order=volume_desc&page=1') {
      return http.Response(_sirenTickersResponseJson, 200);
    }

    throw StateError('Unhandled SIREN analyze request: $url');
  });
}

const String sirenExpectedAnalyzeMessage =
    '<b>Siren</b> (SIREN)\n'
    '<b>Risk:</b> LOW (11/100)\n'
    '<b>Price:</b> \$2.15\n'
    '<b>Market Cap:</b> \$1.55B\n'
    '<b>ATH:</b> \$3.61\n'
    '<b>Distance from ATH:</b> -40.44%\n'
    '<b>24h Volume:</b> \$54.26M\n'
    '<b>2% Market Depth:</b> \$400.00K\n'
    '<b>2% Depth vs Market Cap:</b> 0.0258%';

const String _sirenCoinGeckoResponseJson =
    r'''[{"id":"siren-2","symbol":"siren","name":"Siren","current_price":2.15,"market_cap":1548222927,"total_volume":54262684,"ath":3.61,"ath_change_percentage":-41.94504}]''';

const String _sirenTickersResponseJson =
    r'''{"name":"Siren","tickers":[{"base":"SIREN","target":"USDT","market":{"name":"MEXC"},"cost_to_move_up_usd":520000,"cost_to_move_down_usd":300000,"converted_volume":{"usd":18000000},"is_anomaly":false,"is_stale":false},{"base":"SIREN","target":"USDT","market":{"name":"Gate.io"},"cost_to_move_up_usd":160000,"cost_to_move_down_usd":100000,"converted_volume":{"usd":9000000},"is_anomaly":false,"is_stale":false}]}''';
