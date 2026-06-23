import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _initialized = false;

  // Persists across installs — tracks whether this device has ever completed
  // the post-login dashboard onboarding.
  bool _hasDoneOnboarding = false;

  AppUser? get user => _user;
  bool get initialized => _initialized;
  bool get isLoggedIn => _user != null;

  /// True once the user has completed (or dismissed) the post-login onboarding
  /// carousel. Persists in SharedPreferences so it survives logout/reinstall
  /// on the same device until app data is cleared.
  bool get hasDoneOnboarding => _hasDoneOnboarding;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hasDoneOnboarding = prefs.getBool('has_done_onboarding') ?? false;
    _user = await AuthService.tryAutoLogin();
    _initialized = true;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final user = await AuthService.signInWithGoogle();
    _user = user;
    notifyListeners();
  }

  Future<void> setUserType(UserType type) async {
    final updated = await AuthService.setUserType(type);
    _user = updated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _user = await AuthService.getMe();
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }

  /// Called once the user finishes or dismisses the dashboard onboarding sheet.
  Future<void> markOnboardingDone() async {
    if (_hasDoneOnboarding) return;
    _hasDoneOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_done_onboarding', true);
    notifyListeners();
  }
}
