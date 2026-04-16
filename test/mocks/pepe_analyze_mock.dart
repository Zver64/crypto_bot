import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient buildPepeAnalyzeMockClient() {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url ==
        'https://api.bybit.com/v5/market/instruments-info?category=linear&baseCoin=PEPE') {
      return http.Response(_invalidBaseCoinResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/instruments-info?category=linear&baseCoin=10PEPE') {
      return http.Response(_invalidBaseCoinResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/instruments-info?category=linear&baseCoin=100PEPE') {
      return http.Response(_invalidBaseCoinResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/instruments-info?category=linear&baseCoin=1000PEPE') {
      return http.Response(_pepeInstrumentsResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/tickers?category=linear&symbol=1000PEPEPERP') {
      return http.Response(_pepeTickerResponseJson, 200);
    }

    if (url ==
        'https://api.bybit.com/v5/market/orderbook?category=linear&symbol=1000PEPEPERP&limit=50') {
      return http.Response(_pepeOrderbookResponseJson, 200);
    }

    if (url ==
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=PEPE') {
      return http.Response(_pepeCoinGeckoResponseJson, 200);
    }

    throw StateError('Unhandled PEPE analyze request: $url');
  });
}

const String pepeExpectedAnalyzeMessage = '''
<b>1000PEPEPERP</b> (PEPE)
<b>Risk:</b> LOW (0/100)
<b>Price:</b> \$0.00000354
<b>Market Cap:</b> \$1.49B
<b>ATH:</b> \$0.00002803
<b>Distance from ATH:</b> -87.36%
<b>Visible Depth:</b> \$52.97K
<b>Visible Depth vs Market Cap:</b> 0.00355%
''';

const String _invalidBaseCoinResponseJson = r'''{"retCode":10001,"retMsg":"params error: base_coin invalid","result":{"category":"","list":[],"nextPageCursor":""},"retExtInfo":{},"time":1774431017435}''';
const String _pepeInstrumentsResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"1000PEPEPERP","contractType":"LinearPerpetual","status":"Trading","baseCoin":"1000PEPE","quoteCoin":"USDC","launchTime":"1713960905000","deliveryTime":"0","deliveryFeeRate":"","priceScale":"7","leverageFilter":{"minLeverage":"1","maxLeverage":"50.00","leverageStep":"0.01"},"priceFilter":{"minPrice":"0.0000010","maxPrice":"19.9999980","tickSize":"0.0000010"},"lotSizeFilter":{"maxOrderQty":"6000000","minOrderQty":"100","qtyStep":"100","postOnlyMaxOrderQty":"6000000","maxMktOrderQty":"1200000","minNotionalValue":"5"},"unifiedMarginTrade":true,"fundingInterval":480,"settleCoin":"USDC","copyTrading":"none","upperFundingRate":"0.008","lowerFundingRate":"-0.008","isPreListing":false,"preListingInfo":null,"riskParameters":{"priceLimitRatioX":"0.05","priceLimitRatioY":"0.1"},"displayName":"1000PEPEUSDC","symbolType":"","forbidUplWithdrawal":false},{"symbol":"1000PEPEUSDT","contractType":"LinearPerpetual","status":"Trading","baseCoin":"1000PEPE","quoteCoin":"USDT","launchTime":"1683108271000","deliveryTime":"0","deliveryFeeRate":"","priceScale":"7","leverageFilter":{"minLeverage":"1","maxLeverage":"50.00","leverageStep":"0.01"},"priceFilter":{"minPrice":"0.0000010","maxPrice":"19.9999980","tickSize":"0.0000010"},"lotSizeFilter":{"maxOrderQty":"110000000","minOrderQty":"100","qtyStep":"100","postOnlyMaxOrderQty":"110000000","maxMktOrderQty":"42000000","minNotionalValue":"5"},"unifiedMarginTrade":true,"fundingInterval":480,"settleCoin":"USDT","copyTrading":"both","upperFundingRate":"0.01","lowerFundingRate":"-0.01","isPreListing":false,"preListingInfo":null,"riskParameters":{"priceLimitRatioX":"0.05","priceLimitRatioY":"0.1"},"displayName":"","symbolType":"","forbidUplWithdrawal":false}],"nextPageCursor":""},"retExtInfo":{},"time":1774431032230}''';
const String _pepeTickerResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"1000PEPEPERP","lastPrice":"0.0035440","indexPrice":"0.0035481","markPrice":"0.0035484","prevPrice24h":"0.0034620","price24hPcnt":"0.023685","highPrice24h":"0.0036130","lowPrice24h":"0.0033780","prevPrice1h":"0.0035880","openInterest":"92690400","openInterestValue":"328902.62","turnover24h":"98084.1019","volume24h":"28013200.0000","fundingRate":"0.0001","nextFundingTime":"1774454400000","predictedDeliveryPrice":"","basisRate":"","deliveryFeeRate":"","deliveryTime":"0","ask1Size":"1358000","bid1Price":"0.0035460","ask1Price":"0.0035480","bid1Size":"29200","basis":"","preOpenPrice":"","preQty":"","curPreListingPhase":"","fundingIntervalHour":"8","basisRateYear":"","fundingCap":"0.008"}]},"retExtInfo":{},"time":1774431017441}''';
const String _pepeOrderbookResponseJson = r'''{"retCode":0,"retMsg":"OK","result":{"s":"1000PEPEPERP","b":[["0.003549","29200"],["0.003547","30300"],["0.003546","129300"],["0.003545","14100"],["0.003544","10100"],["0.003543","1143100"],["0.003542","223000"],["0.003541","14200"],["0.00354","529500"],["0.003539","108800"],["0.003538","11000"],["0.003537","10000"],["0.003536","10500"],["0.003535","10600"],["0.003534","10000"],["0.003533","10700"],["0.003532","10300"],["0.003531","10200"],["0.00353","221700"],["0.003529","10200"],["0.003528","10700"],["0.003527","10600"],["0.003526","221400"],["0.003525","10000"],["0.003514","549800"],["0.003503","28500"],["0.003498","549000"],["0.003483","249000"],["0.003481","1973400"],["0.00348","2869900"],["0.003448","2537500"],["0.003442","2732400"],["0.003404","126800"],["0.003374","126500"],["0.00326","118100"],["0.003195","29700"],["0.00312","10000"],["0.003024","39200"],["0.002968","109200"],["0.0029","344800"],["0.002843","52200"],["0.002836","10000"],["0.00257","2000"],["0.00034","690000"]],"a":[["0.00355","230500"],["0.003551","532400"],["0.003552","14100"],["0.003553","111500"],["0.003554","14200"],["0.003555","14200"],["0.003556","11700"],["0.003557","15600"],["0.003558","12000"],["0.003559","15400"],["0.00356","15000"],["0.003561","1137200"],["0.003562","226300"],["0.003563","14200"],["0.003564","10400"],["0.003565","10100"],["0.003566","10200"],["0.003567","10700"],["0.003568","10700"],["0.003569","10400"],["0.00357","10200"],["0.003573","211000"],["0.003578","549800"],["0.003597","576200"],["0.003611","1973500"],["0.003617","6000000"],["0.003624","239300"],["0.00364","2743600"],["0.003642","2538100"],["0.003688","126800"],["0.003695","2545300"],["0.003722","126800"],["0.004804","600000"],["0.013015","23300"],["0.013481","7800"],["0.013564","9100"],["0.013896","8900"],["0.014761","5200"],["0.014982","5100"],["0.01562","6500"],["0.015797","7000"],["0.015928","2000"],["0.016055","7000"]],"ts":1774431031734,"u":2398316,"seq":17171467182,"cts":1774431031694},"retExtInfo":{},"time":1774431032201}''';
const String _pepeCoinGeckoResponseJson = r'''[{"id":"pepe","symbol":"pepe","name":"Pepe","image":"https://coin-images.coingecko.com/coins/images/29850/large/pepe-token.jpeg?1696528776","current_price":3.55e-06,"market_cap":1493487640,"market_cap_rank":54,"fully_diluted_valuation":1493487640,"total_volume":308929089,"high_24h":3.6e-06,"low_24h":3.39e-06,"price_change_24h":8.8513e-08,"price_change_percentage_24h":2.55837,"market_cap_change_24h":38021935,"market_cap_change_percentage_24h":2.61236,"circulating_supply":420690000000000.0,"total_supply":420690000000000.0,"max_supply":420690000000000.0,"ath":2.803e-05,"ath_change_percentage":-87.34049,"ath_date":"2024-12-09T16:30:35.828Z","atl":5.5142e-08,"atl_change_percentage":6334.67218,"atl_date":"2023-04-18T02:14:41.591Z","roi":null,"last_updated":"2026-03-25T09:30:16.477Z"}]''';
