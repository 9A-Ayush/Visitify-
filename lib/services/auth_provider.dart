import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? firebaseUser;
  AppUser? appUser;
  bool isLoading = true;

  AuthProvider() {
    AuthService().authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    firebaseUser = user;
    if (user != null) {
      appUser = await AuthService().getAppUser();
    } else {
      appUser = null;
    }
    isLoading = false;
    notifyListeners();
  }

  bool get isLoggedIn => firebaseUser != null;
  String? get role => appUser?.role;
  bool get isProfileComplete => appUser?.profileComplete ?? false;

  Future<void> signOut() async {
    await AuthService().signOut();
  }

  Future<void> loadUser() async {
    if (firebaseUser != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser!.uid)
                .get();

        if (userDoc.exists) {
          appUser = AppUser.fromMap(userDoc.data()!, firebaseUser!.uid);
        } else {
          // User document doesn't exist in Firestore - this shouldn't happen
          // but if it does, clear the user data
          appUser = null;
          print(
            'Warning: Firebase user exists but no Firestore document found',
          );
        }
        notifyListeners();
      } catch (e) {
        print('Error loading user: $e');
        appUser = null;
        notifyListeners();
      }
    } else {
      // No Firebase user - clear app user data
      appUser = null;
      notifyListeners();
    }
  }
}
