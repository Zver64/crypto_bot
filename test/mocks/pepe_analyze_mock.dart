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
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=pepe&precision=full') {
      return http.Response(_pepePrimaryCoinGeckoResponseJson, 200);
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
    '<b>Explosive Upside Potential:</b> MEDIUM (48/100)\n'
    '<b>Data Confidence:</b> HIGH (86/100)\n'
    '<b>Price:</b> \$0.00000355\n'
    '<b>Market Cap:</b> \$1.49B\n'
    '<b>ATH:</b> \$0.00002803\n'
    '<b>Distance from ATH:</b> -87.33%\n'
    '<b>24h Volume:</b> \$308.93M\n'
    '<b>Upward 2% Depth:</b> \$3.60M\n'
    '<b>Upward Depth vs Market Cap:</b> 0.241%\n'
    '<b>Upward Depth vs 24h Volume:</b> 1.17%\n'
    '<b>Top Venue Volume Share:</b> 77.4%\n'
    '<b>Top Venue Upward Depth Share:</b> 86.1%\n'
    '<b>Pump Drivers:</b> Upward depth is limited relative to the reported market cap; Trading flow could crowd a thin upside book; A single venue dominates visible volume; Upward depth is heavily dependent on one venue\n'
    '<b>Constraints:</b> CoinGecko depth does not show upside asymmetry; CoinGecko ticker sample is narrow';

const String _pepeCoinGeckoResponseJson =
    r'''[{"id":"pepe","symbol":"pepe","name":"Pepe","current_price":0.00000355,"market_cap":1493487640,"total_volume":308929089,"ath":0.00002803,"ath_change_percentage":-87.34049},{"id":"pepe-on-base","symbol":"pepe","name":"Pepe on Base","current_price":0.00000091,"market_cap":1200000,"total_volume":54000,"ath":0.0000018,"ath_change_percentage":-49.44}]''';

const String _pepePrimaryCoinGeckoResponseJson =
    r'''[{"id":"pepe","symbol":"pepe","name":"Pepe","current_price":0.00000355,"market_cap":1493487640,"total_volume":308929089,"ath":0.00002803,"ath_change_percentage":-87.34049}]''';

const String _pepeTickersResponseJson =
    r'''{"name":"Pepe","tickers":[{"base":"PEPE","target":"USDT","market":{"name":"Binance"},"cost_to_move_up_usd":3100000,"cost_to_move_down_usd":2100000,"converted_volume":{"usd":120000000},"is_anomaly":false,"is_stale":false},{"base":"PEPE","target":"USD","market":{"name":"Kraken"},"cost_to_move_up_usd":500000,"cost_to_move_down_usd":400000,"converted_volume":{"usd":35000000},"is_anomaly":false,"is_stale":false}]}''';
