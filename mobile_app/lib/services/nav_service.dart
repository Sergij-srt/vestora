import 'package:flutter/foundation.dart';

/// Lightweight cross-screen navigation bridge so ANY screen can send the user to a main tab
/// (e.g. an empty "Stylist" screen can say "Add your first item" and jump straight to the Add tab)
/// without needing a callback chain through the widget tree.
///
/// `MainNavigationScreen` listens to [tabRequest]; when no listener exists (unit/widget tests of
/// a single screen) requests are simply ignored.
class AppNav {
  AppNav._();

  static const int tabCloset = 0;
  static const int tabStylist = 1;
  static const int tabAdd = 2;
  static const int tabCommunity = 3;
  static const int tabAnalytics = 4;

  static final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  /// Asks the main shell to switch to [tabIndex]. Pops nothing; callers that are pushed routes
  /// should `Navigator.pop` first if they want to reveal the tab.
  static void goToTab(int tabIndex) {
    tabRequest.value = tabIndex;
  }
}
