import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient buildSirenAnalyzeMockClient() {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url ==
        'https://api.bybit.com/v5/market/instruments-info?category=linear&baseCoin=SIREN') {
      return http.Response(_sirenInstrumentsResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/tickers?category=linear&symbol=SIRENUSDT') {
      return http.Response(_sirenTickerResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/orderbook?category=linear&symbol=SIRENUSDT&limit=50') {
      return http.Response(_sirenOrderbookResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=SIREN') {
      return http.Response(_sirenCoinGeckoResponseJson, 200);
    }

    throw StateError('Unhandled SIREN analyze request: $url');
  });
}

const String sirenExpectedAnalyzeMessage = '''
<b>SIRENUSDT</b> (SIREN)
<b>Risk:</b> LOW (25/100)
<b>Price:</b> \$2.14
<b>Market Cap:</b> \$1.56B
<b>ATH:</b> \$3.61
<b>Distance from ATH:</b> -40.63%
<b>Visible Depth:</b> \$4.14K
<b>Visible Depth vs Market Cap:</b> 0.00027%
''';

const String _sirenInstrumentsResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"SIRENUSDT","contractType":"LinearPerpetual","status":"Trading","baseCoin":"SIREN","quoteCoin":"USDT","launchTime":"1742613642000","deliveryTime":"0","deliveryFeeRate":"","priceScale":"5","leverageFilter":{"minLeverage":"1","maxLeverage":"5.00","leverageStep":"0.01"},"priceFilter":{"minPrice":"0.00001","maxPrice":"199.99998","tickSize":"0.00001"},"lotSizeFilter":{"maxOrderQty":"100000","minOrderQty":"1","qtyStep":"1","postOnlyMaxOrderQty":"100000","maxMktOrderQty":"40000","minNotionalValue":"5"},"unifiedMarginTrade":true,"fundingInterval":240,"settleCoin":"USDT","copyTrading":"both","upperFundingRate":"0.05","lowerFundingRate":"-0.05","isPreListing":false,"preListingInfo":null,"riskParameters":{"priceLimitRatioX":"0.3","priceLimitRatioY":"0.6"},"displayName":"","symbolType":"innovation","forbidUplWithdrawal":false}],"nextPageCursor":""},"retExtInfo":{},"time":1774431017475}''';
const String _sirenTickerResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"SIRENUSDT","lastPrice":"2.14335","indexPrice":"2.14184","markPrice":"2.14004","prevPrice24h":"0.99562","price24hPcnt":"1.152779","highPrice24h":"2.45330","lowPrice24h":"0.92888","prevPrice1h":"2.22405","openInterest":"6137057","openInterestValue":"13133547.46","turnover24h":"136573100.4001","volume24h":"85853729.0000","fundingRate":"-0.0005572","nextFundingTime":"1774440000000","predictedDeliveryPrice":"","basisRate":"","deliveryFeeRate":"","deliveryTime":"0","ask1Size":"33","bid1Price":"2.14280","ask1Price":"2.14300","bid1Size":"3","basis":"","preOpenPrice":"","preQty":"","curPreListingPhase":"","fundingIntervalHour":"4","basisRateYear":"","fundingCap":"0.05"}]},"retExtInfo":{},"time":1774431017478}''';
const String _sirenOrderbookResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"s":"SIRENUSDT","b":[["2.13624","22"],["2.13623","12"],["2.1357","6"],["2.13569","231"],["2.13568","62"],["2.13567","4"],["2.13565","231"],["2.13563","231"],["2.13545","1"],["2.13495","3"],["2.13488","27"],["2.13477","1"],["2.13469","5"],["2.13468","12"],["2.13467","15"],["2.13463","9"],["2.13454","69"],["2.13447","27"],["2.13435","15"],["2.13431","26"],["2.1343","69"],["2.13429","1"],["2.13427","23"],["2.13426","12"],["2.13424","15"],["2.1341","56"],["2.13409","27"],["2.134","3"],["2.13397","12"],["2.13395","60"],["2.13392","26"],["2.13389","5"],["2.13388","27"],["2.13387","69"],["2.13376","15"],["2.13375","12"],["2.13366","69"],["2.13361","54"],["2.1336","44"],["2.13358","28"],["2.13356","8"],["2.13355","84"],["2.13354","12"],["2.13345","3"],["2.13342","15"],["2.13338","69"],["2.13334","12"],["2.13333","14"],["2.13329","60"],["2.13328","25"]],"a":[["2.13806","54"],["2.13807","360"],["2.13808","238"],["2.13811","3"],["2.13812","110"],["2.13849","56"],["2.13856","65"],["2.1386","65"],["2.13871","29"],["2.13875","69"],["2.13878","29"],["2.13882","30"],["2.13888","69"],["2.13889","231"],["2.13891","3"],["2.13895","3"],["2.13897","27"],["2.13907","69"],["2.13917","5"],["2.13918","27"],["2.13924","24"],["2.13928","25"],["2.13938","82"],["2.13939","12"],["2.13941","55"],["2.1395","3"],["2.13952","1"],["2.13957","69"],["2.13959","15"],["2.1396","12"],["2.13962","24"],["2.1398","105"],["2.13982","24"],["2.13984","69"],["2.13995","69"],["2.14","25"],["2.14001","27"],["2.14005","3"],["2.14006","69"],["2.14015","64"],["2.14017","69"],["2.14021","24"],["2.14022","27"],["2.14035","10"],["2.14036","69"],["2.14038","24"],["2.14043","27"],["2.14046","56"],["2.14047","69"],["2.14051","1"]],"ts":1774431032174,"u":6141831,"seq":243331971142,"cts":1774431032172},"retExtInfo":{},"time":1774431032216}''';
const String _sirenCoinGeckoResponseJson = r'''[{"id":"siren-2","symbol":"siren","name":"Siren","image":"https://coin-images.coingecko.com/coins/images/54479/large/siren.png?1739960056","current_price":2.15,"market_cap":1548222927,"market_cap_rank":53,"fully_diluted_valuation":1548222927,"total_volume":54262684,"high_24h":2.34,"low_24h":0.995471,"price_change_24h":1.14,"price_change_percentage_24h":113.75122,"market_cap_change_24h":817616052,"market_cap_change_percentage_24h":111.90916,"circulating_supply":728213818.6754465,"total_supply":728213818.6754465,"max_supply":1000000000.0,"ath":3.61,"ath_change_percentage":-41.94504,"ath_date":"2026-03-22T17:26:33.134Z","atl":0.02634736,"atl_change_percentage":7843.63722,"atl_date":"2025-03-11T06:21:52.561Z","roi":null,"last_updated":"2026-03-25T09:30:16.294Z"}]''';
