/// Application constants, anti-plagiarism metadata, and channel identifiers.
abstract class AppConstants {
  static const String packageName = 'com.example.cordash';
  static const String firstGitCommitHash =
      '4b8fea420da7b41d0a7c59535ddfaacfb0bc6e6e';

  /// Anti-plagiarism SALT = SHA256("${packageName}:${firstGitCommitHash}")
  static const String antiPlagiarismSalt =
      '53e4cf58eb6634c6149e062b2110da8712b6f9d1403a1d7b735589004348d5c7';

  // Native Platform Channels
  static const String passiveListenerChannel =
      'com.example.cordash/passive_listener';
  static const String healthPermissionsChannel =
      'com.example.cordash/health_permissions';

  // Performance HUD Targets
  static const double targetMaxBuildTimeMs = 8.0;
  static const int targetLatencySeconds = 10;

  // Charting defaults
  static const int defaultStepWindowMinutes = 60;
  static const int maxChartDecimationPoints = 300;
}
