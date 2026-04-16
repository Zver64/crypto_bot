import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient buildBtcAnalyzeMockClient() {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=btc&include_tokens=all&order=market_cap_desc&precision=full') {
      return http.Response(_btcCoinGeckoResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin&precision=full') {
      return http.Response(_btcCoinGeckoResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/bitcoin/tickers?depth=true&order=volume_desc&page=1') {
      return http.Response(_btcTickersResponseJson, 200);
    }

    throw StateError('Unhandled BTC analyze request: $url');
  });
}

const String btcExpectedAnalyzeMessage =
    '<b>Bitcoin</b> (BTC)\n'
    '<b>Explosive Upside Potential:</b> LOW (0/100)\n'
    '<b>Data Confidence:</b> MEDIUM (71/100)\n'
    '<b>Price:</b> \$71.26K\n'
    '<b>Market Cap:</b> \$1425.41B\n'
    '<b>ATH:</b> \$126.08K\n'
    '<b>Distance from ATH:</b> -43.48%\n'
    '<b>24h Volume:</b> \$40.56B\n'
    '<b>Upward 2% Depth:</b> \$29.32M\n'
    '<b>Upward Depth vs Market Cap:</b> 0.00206%\n'
    '<b>Upward Depth vs 24h Volume:</b> 0.0723%\n'
    '<b>Top Venue Volume Share:</b> 71.9%\n'
    '<b>Top Venue Upward Depth Share:</b> 65.9%\n'
    '<b>Pump Drivers:</b> No strong CoinGecko depth signals of an easy upside squeeze\n'
    '<b>Constraints:</b> Upward depth is substantial enough to resist a small squeeze; CoinGecko depth does not show upside asymmetry; Visible CoinGecko venue volume covers only a small slice of 24h volume';

const String _btcCoinGeckoResponseJson =
    r'''[{"id":"bitcoin","symbol":"btc","name":"Bitcoin","current_price":71259,"market_cap":1425408987537,"total_volume":40560127061,"ath":126080,"ath_change_percentage":-43.48077}]''';

const String _btcTickersResponseJson =
    r'''{"name":"Bitcoin","tickers":[{"base":"BTC","target":"USDT","market":{"name":"Binance"},"cost_to_move_up_usd":19320706.3958517,"cost_to_move_down_usd":16360235.3694131,"converted_volume":{"usd":1406996874},"is_anomaly":false,"is_stale":false},{"base":"BTC","target":"USD","market":{"name":"Coinbase Exchange"},"cost_to_move_up_usd":10000000,"cost_to_move_down_usd":9000000,"converted_volume":{"usd":550000000},"is_anomaly":false,"is_stale":false}]}''';
