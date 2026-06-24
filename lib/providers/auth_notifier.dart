import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final AppUser? user;
  final bool hasDoneOnboarding;

  const AuthState({this.user, this.hasDoneOnboarding = false});

  bool get isLoggedIn => user != null;

  AuthState copyWith({AppUser? user, bool? hasDoneOnboarding, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      hasDoneOnboarding: hasDoneOnboarding ?? this.hasDoneOnboarding,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDoneOnboarding = prefs.getBool('has_done_onboarding') ?? false;
    final user = await AuthService.tryAutoLogin();
    return AuthState(user: user, hasDoneOnboarding: hasDoneOnboarding);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await AuthService.signInWithGoogle();
      final current = state.asData?.value;
      return AuthState(user: user, hasDoneOnboarding: current?.hasDoneOnboarding ?? false);
    });
  }

  Future<void> setUserType(UserType type) async {
    final updated = await AuthService.setUserType(type);
    final current = state.asData?.value;
    state = AsyncData(AuthState(user: updated, hasDoneOnboarding: current?.hasDoneOnboarding ?? false));
  }

  Future<void> refreshUser() async {
    final user = await AuthService.getMe();
    final current = state.asData?.value;
    state = AsyncData(AuthState(user: user, hasDoneOnboarding: current?.hasDoneOnboarding ?? false));
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    final current = state.asData?.value;
    state = AsyncData(AuthState(user: null, hasDoneOnboarding: current?.hasDoneOnboarding ?? false));
  }

  Future<void> markOnboardingDone() async {
    final current = state.asData?.value;
    if (current == null || current.hasDoneOnboarding) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_done_onboarding', true);
    state = AsyncData(current.copyWith(hasDoneOnboarding: true));
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
