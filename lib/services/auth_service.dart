import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodshare/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user has completed profile
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

  // Get user type
  Future<UserType?> getUserType() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return null;

      final userTypeString = doc.data()?['userType'];
      if (userTypeString == 'restaurant') return UserType.restaurant;
      if (userTypeString == 'shelter') return UserType.shelter;

      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Email Sign-In Error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await _createOrUpdateUserDocument(credential.user!);
      }

      return credential;
    } catch (e) {
      print('Registration Error: $e');
      rethrow;
    }
  }

  // Set user type after registration/sign-in
  Future<void> setUserType(UserType userType) async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      final doc = await userRef.get();
      
      if (!doc.exists) {
        // If document doesn't exist (social auth user), create it with user type
        await userRef.set({
          'uid': currentUser!.uid,
          'email': currentUser!.email,
          'displayName': currentUser!.displayName,
          'photoURL': currentUser!.photoURL,
          'userType': userType.toString().split('.').last,
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If document exists, just update the user type
        await userRef.update({
          'userType': userType.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error setting user type: $e');
      rethrow;
    }
  }

  // Mark profile as complete
  Future<void> markProfileComplete() async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      final doc = await userRef.get();
      
      if (!doc.exists) {
        // Create document if it doesn't exist
        await userRef.set({
          'uid': currentUser!.uid,
          'email': currentUser!.email,
          'displayName': currentUser!.displayName,
          'photoURL': currentUser!.photoURL,
          'profileComplete': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing document
        await userRef.update({
          'profileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking profile complete: $e');
      rethrow;
    }
  }

  // Sign out - Fixed for web compatibility
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _auth.signOut();
        print('User signed out successfully');
      } else {
        print('No user was signed in');
      }
    } catch (e) {
      print('Sign-Out Error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      rethrow;
    }
  }

  // Delete account - Fixed for web compatibility
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    try {
      final uid = user.uid;

      // Get user type before deletion
      final userType = await getUserType();

      // Create a batch for atomic operations
      final batch = _firestore.batch();

      // Delete user data from Firestore
      batch.delete(_firestore.collection('users').doc(uid));

      // Delete profile based on user type
      if (userType == UserType.restaurant) {
        final restaurantDoc = _firestore.collection('restaurants').doc(uid);
        final restaurantExists = await restaurantDoc.get();
        if (restaurantExists.exists) {
          batch.delete(restaurantDoc);
        }
      } else if (userType == UserType.shelter) {
        final shelterDoc = _firestore.collection('shelters').doc(uid);
        final shelterExists = await shelterDoc.get();
        if (shelterExists.exists) {
          batch.delete(shelterDoc);
        }
      }

      // Delete any donations or other related data
      final donationsQuery = await _firestore
          .collection('donations')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in donationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();

      // Finally, delete Firebase Auth account
      await user.delete();

      print('Account deleted successfully');
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}