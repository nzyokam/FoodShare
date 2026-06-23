import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import '../models/user_model.dart';

class AuthService {
  // On web the client ID is read from the <meta name="google-signin-client_id">
  // tag in index.html — passing serverClientId on web throws an assertion error.
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: kIsWeb
        ? null
        : '383740409419-b3f1j87l3t5vlk6cu7ddo7fumq99ms8c.apps.googleusercontent.com',
  );

  /// Check stored JWT and return user if still valid (called on app start).
  static Future<AppUser?> tryAutoLogin() async {
    final token = await ApiClient.getAccessToken();
    if (token == null) return null;
    final res = await ApiClient.get('/auth/me');
    if (res.statusCode == 200) return AppUser.fromJson(jsonDecode(res.body));
    await ApiClient.clearTokens();
    return null;
  }

  /// Google OAuth → POST /auth/google (mobile) or /auth/google/access-token (web)
  static Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');

    final googleAuth = await googleUser.authentication;

    late dynamic res;

    if (kIsWeb) {
      // Web: google_sign_in popup flow returns accessToken, not idToken.
      // Backend verifies via Google's userinfo endpoint.
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw Exception('Failed to get Google access token');
      res = await ApiClient.post('/auth/google/access-token', body: {'access_token': accessToken});
    } else {
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');
      res = await ApiClient.post('/auth/google', body: {'id_token': idToken});
    }

    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await ApiClient.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    return AppUser.fromJson(data['user']);
  }

  /// PATCH /auth/user-type
  static Future<AppUser> setUserType(UserType type) async {
    final res = await ApiClient.patch('/auth/user-type', body: {'user_type': type.name});
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return AppUser.fromJson(jsonDecode(res.body));
  }

  /// GET /auth/me — refresh cached user data after profile changes.
  static Future<AppUser?> getMe() async {
    final res = await ApiClient.get('/auth/me');
    if (res.statusCode == 200) return AppUser.fromJson(jsonDecode(res.body));
    return null;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await ApiClient.clearTokens();
  }
}
