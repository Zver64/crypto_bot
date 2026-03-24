class BybitInstrument {
  final String symbol;
  final String baseCoin;
  final String quoteCoin;
  final int? fundingInterval;

  const BybitInstrument({
    required this.symbol,
    required this.baseCoin,
    required this.quoteCoin,
    required this.fundingInterval,
  });

  factory BybitInstrument.fromJson(Map<String, dynamic> json) {
    return BybitInstrument(
      symbol: json['symbol']?.toString() ?? '',
      baseCoin: json['baseCoin']?.toString() ?? '',
      quoteCoin: json['quoteCoin']?.toString() ?? '',
      fundingInterval: int.tryParse(json['fundingInterval']?.toString() ?? ''),
    );
  }
}
