// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'SkillSwap';
  static const String appVersion = '1.0.0';

  // Use mock repository (set to false to use real Firebase backend)
  static bool useMockRepo = false;
  static bool isFirebaseAvailable = false;

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border radii
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // Touch targets
  static const double minTouchTarget = 48.0;

  // Responsive breakpoints
  static const double tabletBreakpoint = 720.0;
  static const double desktopBreakpoint = 1200.0;

  // Pagination
  static const int pageSize = 20;

  // Search debounce
  static const int searchDebounceMs = 400;

  // Min review length
  static const int minReviewLength = 20;

  // Category list (also in SkillCategory enum but handy here)
  static const List<String> categoryLabels = [
    'All',
    'Technology',
    'Music',
    'Language',
    'Art',
    'Fitness',
    'Cooking',
    'Business',
  ];
}
