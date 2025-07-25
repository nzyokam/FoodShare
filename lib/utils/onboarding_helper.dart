// utils/onboarding_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingHelper {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  
  // Mark that user has seen onboarding
  static Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
  
  // Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }
  
  // Reset onboarding status (useful for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }
}

