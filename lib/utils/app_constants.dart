class AppConstants {
  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 800);

  // Chart sizes
  static const double defaultChartSize = 120.0;
  static const maxMembersAllowed = 6; // included admin would be + 1
  static const documentsPath =
      '/storage/emulated/0/documents/split_smart_expenses'; // for android

  static const double largeSpacing = 32.0;

  // Border radius
  static const double cardBorderRadius = 16.0;
  static const double tagBorderRadius = 8.0;

  static const double itemIconSize = 18.0;

  // Activity threshold (days)
  static const int activityThresholdDays = 7;

  // Currency
  static const String currencySymbol = 'Rs ';
}
