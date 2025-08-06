// services/social_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign In configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // For web, you need to configure the clientId
    clientId: kIsWeb
        ? '383740409419-b3f1j87l3t5vlk6cu7ddo7fumq99ms8c.apps.googleusercontent.com'
        : null,
  );

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );

        if (userCredential.user != null) {
          await _createOrUpdateUserDocument(userCredential.user!);
        }

        return userCredential;
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user != null) {
          await _createOrUpdateUserDocument(userCredential.user!);
        }

        return userCredential;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Sign in with Apple
  // Future<UserCredential?> signInWithApple() async {
  //   try {
  //     if (kIsWeb) {
  //       // Web implementation
  //       final appleProvider = AppleAuthProvider();
  //       appleProvider.addScope('email');
  //       appleProvider.addScope('fullName');

  //       final UserCredential userCredential = await _auth.signInWithPopup(
  //         appleProvider,
  //       );

  //       if (userCredential.user != null) {
  //         await _createOrUpdateUserDocument(userCredential.user!);
  //       }

  //       return userCredential;
  //     } else {
  //       // Mobile implementation - primarily for iOS
  //       final credential = await SignInWithApple.getAppleIDCredential(
  //         scopes: [
  //           AppleIDAuthorizationScopes.email,
  //           AppleIDAuthorizationScopes.fullName,
  //         ],
  //         webAuthenticationOptions: WebAuthenticationOptions(
  //           clientId: 'com.yourcompany.foodshare',
  //           redirectUri: Uri.parse(
  //             'https://foodsharing-5777b.firebaseapp.com/__/auth/handler',
  //           ),
  //         ),
  //       );

  //       final oauthCredential = OAuthProvider("apple.com").credential(
  //         idToken: credential.identityToken,
  //         accessToken: credential.authorizationCode,
  //       );

  //       final UserCredential userCredential = await _auth.signInWithCredential(
  //         oauthCredential,
  //       );

  //       // Update display name if available
  //       if (credential.givenName != null || credential.familyName != null) {
  //         final displayName =
  //             '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
  //                 .trim();
  //         if (displayName.isNotEmpty) {
  //           await userCredential.user?.updateDisplayName(displayName);
  //         }
  //       }

  //       if (userCredential.user != null) {
  //         await _createOrUpdateUserDocument(userCredential.user!);
  //       }

  //       return userCredential;
  //     }
  //   } catch (e) {
  //     print('Apple Sign-In Error: $e');
  //     rethrow;
  //   }
  // }

  // // Sign in with GitHub (Web only - using Firebase Auth directly)
  // Future<UserCredential?> signInWithGitHub() async {
  //   try {
  //     // GitHub OAuth is primarily supported on web through Firebase Auth
  //     if (kIsWeb) {
  //       // Web implementation using Firebase Auth
  //       GithubAuthProvider githubProvider = GithubAuthProvider();
  //       githubProvider.addScope('read:user');
  //       githubProvider.addScope('user:email');

  //       // You can add custom parameters if needed
  //       githubProvider.setCustomParameters({'allow_signup': 'true'});

  //       final UserCredential userCredential = await _auth.signInWithPopup(
  //         githubProvider,
  //       );

  //       if (userCredential.user != null) {
  //         await _createOrUpdateUserDocument(userCredential.user!);
  //       }

  //       return userCredential;
  //     } else {
  //       // For mobile platforms, GitHub OAuth requires custom implementation
  //       // or third-party services. For now, we'll show it's not supported
  //       throw UnsupportedError(
  //         'GitHub Sign-In is currently only supported on web platform. '
  //         'Please use Google or Apple Sign-In on mobile.',
  //       );
  //     }
  //   } catch (e) {
  //     print('GitHub Sign-In Error: $e');
  //     rethrow;
  //   }
  // }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // New user - create document
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? _extractNameFromEmail(user.email),
          'photoURL': user.photoURL,
          'provider': _getProviderName(user),
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user - update document
        await userRef.update({
          'displayName': user.displayName ?? doc.data()?['displayName'],
          'photoURL': user.photoURL ?? doc.data()?['photoURL'],
          'lastSignIn': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      rethrow;
    }
  }

  // Helper to extract name from email
  String _extractNameFromEmail(String? email) {
    if (email == null) return 'User';
    final parts = email.split('@');
    if (parts.isEmpty) return 'User';

    // Convert email prefix to readable name
    // e.g., john.doe -> John Doe
    final nameParts = parts[0].split('.');
    return nameParts
        .map(
          (part) => part.isNotEmpty
              ? '${part[0].toUpperCase()}${part.substring(1)}'
              : '',
        )
        .join(' ');
  }

  // Helper to get provider name
  String _getProviderName(User user) {
    if (user.providerData.isEmpty) return 'email';

    final providerId = user.providerData[0].providerId;
    switch (providerId) {
      case 'google.com':
        return 'google';
      case 'apple.com':
        return 'apple';
      case 'github.com':
        return 'github';
      default:
        return 'email';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        // Apple and GitHub don't need explicit sign out
      ]);
    } catch (e) {
      print('Sign-Out Error: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      return doc.exists && (doc.data()?['profileComplete'] ?? false);
    } catch (e) {
      print('Error checking profile: $e');
      return false;
    }
  }

  // Update user profile photo
  Future<void> updateProfilePhoto(String photoURL) async {
    final user = currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Update Firebase Auth profile
      await user.updatePhotoURL(photoURL);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profile photo: $e');
      rethrow;
    }
  }
}
