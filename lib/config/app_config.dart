class Config {
  static const Duration priceCheckInterval = Duration(minutes: 5);
  static const int defaultMinCapThreshold = 200;
  static const int defaultMaxCapThreshold = 10;
  static const Duration batchProcessDelay = Duration(seconds: 10);
}
