// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bybit_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BybitTicker _$BybitTickerFromJson(Map<String, dynamic> json) => BybitTicker(
  symbol: json['symbol'] as String,
  lastPrice: json['lastPrice'] as String,
  price24hPcnt: json['price24hPcnt'] as String,
  indexPrice: json['indexPrice'] as String?,
  markPrice: json['markPrice'] as String?,
  prevPrice24h: json['prevPrice24h'] as String?,
  highPrice24h: json['highPrice24h'] as String?,
  lowPrice24h: json['lowPrice24h'] as String?,
  prevPrice1h: json['prevPrice1h'] as String?,
  openInterest: json['openInterest'] as String?,
  openInterestValue: json['openInterestValue'] as String?,
  turnover24h: json['turnover24h'] as String?,
  volume24h: json['volume24h'] as String?,
  fundingRate: json['fundingRate'] as String?,
  nextFundingTime: json['nextFundingTime'] as String?,
  bid1Price: json['bid1Price'] as String?,
  bid1Size: json['bid1Size'] as String?,
  ask1Price: json['ask1Price'] as String?,
  ask1Size: json['ask1Size'] as String?,
);

Map<String, dynamic> _$BybitTickerToJson(BybitTicker instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'lastPrice': instance.lastPrice,
      'price24hPcnt': instance.price24hPcnt,
      'indexPrice': instance.indexPrice,
      'markPrice': instance.markPrice,
      'prevPrice24h': instance.prevPrice24h,
      'highPrice24h': instance.highPrice24h,
      'lowPrice24h': instance.lowPrice24h,
      'prevPrice1h': instance.prevPrice1h,
      'openInterest': instance.openInterest,
      'openInterestValue': instance.openInterestValue,
      'turnover24h': instance.turnover24h,
      'volume24h': instance.volume24h,
      'fundingRate': instance.fundingRate,
      'nextFundingTime': instance.nextFundingTime,
      'bid1Price': instance.bid1Price,
      'bid1Size': instance.bid1Size,
      'ask1Price': instance.ask1Price,
      'ask1Size': instance.ask1Size,
    };

BybitResult _$BybitResultFromJson(Map<String, dynamic> json) => BybitResult(
  list: (json['list'] as List<dynamic>)
      .map((e) => BybitTicker.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BybitResultToJson(BybitResult instance) =>
    <String, dynamic>{'list': instance.list};

BybitResponse _$BybitResponseFromJson(Map<String, dynamic> json) =>
    BybitResponse(
      result: BybitResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BybitResponseToJson(BybitResponse instance) =>
    <String, dynamic>{'result': instance.result};
