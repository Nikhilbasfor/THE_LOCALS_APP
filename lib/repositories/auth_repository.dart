import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('AuthRepository.getUserProfile Error: $e');
    }
    return null;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Authentication failed. User ID is null.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      await _auth.signOut();
      throw Exception('User profile record not found in Firestore.');
    }

    final userModel = UserModel.fromMap(userDoc.data()!, userDoc.id);

    // ROLE-MISMATCH GUARD
    if (userModel.role.toLowerCase() != expectedRole.toLowerCase()) {
      await _auth.signOut();
      throw Exception(
        'Account Role Mismatch: This account is registered as a ${userModel.role.toUpperCase()}. '
        'Please sign in through the correct portal.',
      );
    }

    return userModel;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    String state = '',
    String city = '',
    int experienceYears = 0,
    String bio = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Registration failed. User ID is null.');
    }

    final newUser = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: role.toLowerCase(),
      phone: phone.trim(),
      state: state.trim(),
      city: city.trim(),
      experienceYears: experienceYears,
      bio: bio.trim(),
      verified: role.toLowerCase() == 'guide' ? false : true,
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
