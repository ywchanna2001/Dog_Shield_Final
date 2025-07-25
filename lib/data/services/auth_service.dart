import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/data/models/user_model.dart' as model;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login time
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      // Save user token in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTokenKey, await userCredential.user!.getIdToken() ?? '');
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email, 
    String password,
    String name,
  ) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'email': email,
        'name': name,
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Update user display name
      await userCredential.user!.updateDisplayName(name);

      // Save user token in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTokenKey, await userCredential.user!.getIdToken() ?? '');
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user document in Firestore
        await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'imageUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login time
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Save user token in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTokenKey, await userCredential.user!.getIdToken() ?? '');
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user info
  Future<model.User?> getCurrentUserInfo() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return model.User.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // User is already authenticated in Firebase Auth
        return true;
      }
      
      // Try to restore session from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);
      
      if (token != null && userId != null) {
        // We have stored credentials, but Firebase Auth doesn't have a current user
        // This can happen after app restart. Let's check if the token is still valid
        try {
          // If we can get user info from Firestore, the session should be valid
          final doc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .get();
          return doc.exists;
        } catch (e) {
          // If Firestore check fails, clear invalid credentials
          await prefs.remove(AppConstants.userTokenKey);
          await prefs.remove(AppConstants.userIdKey);
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Try to restore authentication session
  Future<bool> restoreAuthSession() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // User is already authenticated
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      
      if (userId != null) {
        // Check if user still exists in Firestore
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        
        if (doc.exists) {
          // User exists in Firestore, Firebase Auth should handle the session
          // We'll return true as the auth state should be restored
          return true;
        } else {
          // User no longer exists, clear stored credentials
          await prefs.remove(AppConstants.userTokenKey);
          await prefs.remove(AppConstants.userIdKey);
        }
      }
      
      return false;
    } catch (e) {
      print('Error restoring auth session: $e');
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (name != null) {
        await user.updateDisplayName(name);
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update({
          'name': name,
        });
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update({
          'imageUrl': photoURL,
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }
  // Get current user profile from Firestore
  Future<model.User?> getCurrentUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();
          
      if (!doc.exists) return null;
      
      return model.User.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to load user profile');
    }
  }
  
  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('The email is already in use by another account');
      case 'weak-password':
        return Exception('The password provided is too weak');
      case 'invalid-email':
        return Exception('The email address is not valid');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed');
      case 'too-many-requests':
        return Exception('Too many unsuccessful login attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error occurred. Check your connection and try again.');
      default:
        return Exception('An unknown error occurred: ${e.message}');
    }
  }
}
