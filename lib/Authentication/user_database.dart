import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mds_home/Authentication/user.dart';

class UserDatabase {
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("userDatabase");

  // Creates a new user document in Firestore
  // Stored via thier UID... contains their email and if they are a premium user
  // Default is not premium...
  Future<void> createUser(String uid, String email, String displayName) async {
    try {
      await userCollection.doc(uid).set({
        'email': email,
        'isPremium': false,
        'name': displayName,
      });
    } catch (e) {
      debugPrint("Error creating user: $e");
      throw Exception("Failed to create user in database");
    }
  }

  // Returns a mdsUser by their UID
  // If the user does not exist, returns null
  Stream<mdsUser?> getUserById(String uid) {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return mdsUser(
          uid: snapshot.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          isPremium: data['isPremium'] ?? false,
        );
      }
      return null;
    });
  }

  // Example method I thought you might find useful...

  // Update the user's premium status
  Future<void> updateUserPremium(String uid, bool isPremium) async {
    await userCollection.doc(uid).update({'isPremium': isPremium});
  }
}
