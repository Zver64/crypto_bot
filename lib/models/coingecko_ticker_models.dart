class CoinGeckoTicker {
  final String base;
  final String target;
  final String marketName;
  final double? costToMoveUpUsd;
  final double? costToMoveDownUsd;
  final double? convertedVolumeUsd;
  final bool isAnomaly;
  final bool isStale;

  const CoinGeckoTicker({
    required this.base,
    required this.target,
    required this.marketName,
    required this.costToMoveUpUsd,
    required this.costToMoveDownUsd,
    required this.convertedVolumeUsd,
    required this.isAnomaly,
    required this.isStale,
  });

  double? get conservativeDepthUsd {
    final up = costToMoveUpUsd;
    final down = costToMoveDownUsd;
    if (up == null || down == null || up <= 0 || down <= 0) {
      return null;
    }

    return up < down ? up : down;
  }

  bool get isUsableForDepth {
    return !isAnomaly &&
        !isStale &&
        conservativeDepthUsd != null &&
        (convertedVolumeUsd ?? 0) > 0;
  }

  factory CoinGeckoTicker.fromJson(Map<String, dynamic> json) {
    final market = json['market'] as Map<String, dynamic>? ?? const {};
    final convertedVolume =
        json['converted_volume'] as Map<String, dynamic>? ?? const {};

    return CoinGeckoTicker(
      base: json['base']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      marketName: market['name']?.toString() ?? 'Unknown',
      costToMoveUpUsd: (json['cost_to_move_up_usd'] as num?)?.toDouble(),
      costToMoveDownUsd: (json['cost_to_move_down_usd'] as num?)?.toDouble(),
      convertedVolumeUsd: (convertedVolume['usd'] as num?)?.toDouble(),
      isAnomaly: json['is_anomaly'] as bool? ?? false,
      isStale: json['is_stale'] as bool? ?? false,
    );
  }
}
