import 'package:dart_bot/services/api_service.dart';
import 'package:dart_bot/services/bot_state.dart';
import 'package:dart_bot/services/price_service.dart';
import 'package:test/test.dart';

import 'mocks/btc_analyze_mock.dart';
import 'mocks/pepe_analyze_mock.dart';
import 'mocks/siren_analyze_mock.dart';

void main() {
  tearDown(() {
    ApiService.resetHttpClient();
    BotState.generatedTickerCache.clear();
    BotState.baseCoinCache.clear();
    BotState.marketCapCache.clear();
  });

  group('analyzeCoin', () {
    test(
      'returns the full BTC analysis message from mocked CoinGecko responses',
      () async {
        ApiService.setHttpClient(buildBtcAnalyzeMockClient());

        final message = await analyzeCoin('btc');

        expect(message, btcExpectedAnalyzeMessage);
      },
    );

    test(
      'returns the full SIREN analysis message from mocked CoinGecko responses',
      () async {
        ApiService.setHttpClient(buildSirenAnalyzeMockClient());

        final message = await analyzeCoin('siren');

        expect(message, sirenExpectedAnalyzeMessage);
      },
    );

    test('selects the highest market cap CoinGecko match for a symbol', () async {
      ApiService.setHttpClient(buildPepeAnalyzeMockClient());

      final message = await analyzeCoin('pepe');

      expect(message, pepeExpectedAnalyzeMessage);
    });
  });
}
