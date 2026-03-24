import 'dart:math';

/// Calculate volatility based on market cap using inverse power law
double volatilityFromMcap(
  double mcap, {
  double smallMcap = 50000000,
  double smallVol = 300,
  double largeMcap = 2000000000000,
  double largeVol = 10,
}) {
  // Use inverse power law: volatility = a * mcap^(-b)
  // Calculate parameters to fit the two points
  final b = log(smallVol / largeVol) / log(largeMcap / smallMcap);
  final a = smallVol * pow(smallMcap, b);
  return a * pow(mcap, -b);
}

String formatCompactUsd(double value) {
  if (value >= 1000000000) {
    return '\$${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (value >= 1000000) {
    return '\$${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return '\$${(value / 1000).toStringAsFixed(2)}K';
  }
  return '\$${value.toStringAsFixed(2)}';
}

String formatPercentValue(double? value, {int decimals = 2}) {
  if (value == null) {
    return 'n/a';
  }

  return '${value.toStringAsFixed(decimals)}%';
}

String formatRatioAsPercent(double? value) {
  if (value == null) {
    return 'n/a';
  }

  final percentValue = value * 100;
  if (percentValue >= 10) {
    return '${percentValue.toStringAsFixed(1)}%';
  }
  if (percentValue >= 1) {
    return '${percentValue.toStringAsFixed(2)}%';
  }
  if (percentValue >= 0.1) {
    return '${percentValue.toStringAsFixed(3)}%';
  }
  if (percentValue >= 0.01) {
    return '${percentValue.toStringAsFixed(4)}%';
  }
  return '${percentValue.toStringAsFixed(5)}%';
}

String formatFundingPeriod(int? minutes) {
  if (minutes == null || minutes <= 0) {
    return 'n/a';
  }
  if (minutes % 60 == 0) {
    return '${minutes ~/ 60}h';
  }
  return '${minutes}m';
}

String formatNextFundingTime(DateTime? value) {
  if (value == null) {
    return 'n/a';
  }

  final utcValue = value.toUtc();
  final month = utcValue.month.toString().padLeft(2, '0');
  final day = utcValue.day.toString().padLeft(2, '0');
  final hour = utcValue.hour.toString().padLeft(2, '0');
  final minute = utcValue.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute UTC';
}
