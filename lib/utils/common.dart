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
