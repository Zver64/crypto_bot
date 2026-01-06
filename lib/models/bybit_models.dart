import 'package:json_annotation/json_annotation.dart';

part 'bybit_models.g.dart';

@JsonSerializable()
class BybitTicker {
  final String symbol;
  final String lastPrice;
  final String price24hPcnt;
  final String? indexPrice;
  final String? markPrice;
  final String? prevPrice24h;
  final String? highPrice24h;
  final String? lowPrice24h;
  final String? prevPrice1h;
  final String? openInterest;
  final String? openInterestValue;
  final String? turnover24h;
  final String? volume24h;
  final String? fundingRate;
  final String? nextFundingTime;
  final String? bid1Price;
  final String? bid1Size;
  final String? ask1Price;
  final String? ask1Size;

  const BybitTicker({
    required this.symbol,
    required this.lastPrice,
    required this.price24hPcnt,
    this.indexPrice,
    this.markPrice,
    this.prevPrice24h,
    this.highPrice24h,
    this.lowPrice24h,
    this.prevPrice1h,
    this.openInterest,
    this.openInterestValue,
    this.turnover24h,
    this.volume24h,
    this.fundingRate,
    this.nextFundingTime,
    this.bid1Price,
    this.bid1Size,
    this.ask1Price,
    this.ask1Size,
  });

  factory BybitTicker.fromJson(Map<String, dynamic> json) =>
      _$BybitTickerFromJson(json);

  Map<String, dynamic> toJson() => _$BybitTickerToJson(this);
}

@JsonSerializable()
class BybitResult {
  final List<BybitTicker> list;

  const BybitResult({required this.list});

  factory BybitResult.fromJson(Map<String, dynamic> json) =>
      _$BybitResultFromJson(json);

  Map<String, dynamic> toJson() => _$BybitResultToJson(this);
}

@JsonSerializable()
class BybitResponse {
  final BybitResult result;

  const BybitResponse({required this.result});

  factory BybitResponse.fromJson(Map<String, dynamic> json) =>
      _$BybitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BybitResponseToJson(this);
}
