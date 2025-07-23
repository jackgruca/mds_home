import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds_home/Authentication/user.dart';
import 'package:mds_home/Authentication/user_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // FireBase Auth
  final UserDatabase _userDB = UserDatabase(); // User DB in Firestore

  // =============================================
  // === REGISTER USER WITH EMAIL AND PASSWORD ===
  // ==============================================
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Create user object from UserCredential
      User? user = result.user;

      // Create user data in Firestore
      await _userDB.createUser(user!.uid, user.email!);
      return user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
  // Add other user registration methods here... For example... Google Sign In...

  // ================================
  // === LOGIN WITH EMAIL & PASS ====
  // ================================
  Future<mdsUser?> signInWithEmailAndPassword(
      String email, String password) async {
    await FirebaseAnalytics.instance.logLogin();
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFireBase(user!);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Add other login methods here... For example... Google Sign In...

  // ================
  // === LOG OUT ===
  // ================
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      // ignore: prefer_interpolation_to_compose_strings
      debugPrint("Couldn't sign out, error = " + e.toString());
    }
  }

// Create user object based upon the FireBase user...
  // This is only used by the login functions... Create seperate getter methods
  // if attempting to retrieve other user data... Like isPremium() for example...
  mdsUser? _userFromFireBase(User user) {
    return mdsUser(
      uid: user.uid,
      email: user.email.toString(),
      isPremium: false,
    );
  }

  // User Stream  (For when the Auth Changes) ( Don't really need to worry about this )
  Stream<mdsUser> get user {
    return _auth
        .authStateChanges()
        .map((User? user) => _userFromFireBase(user!)!);
  }
}
