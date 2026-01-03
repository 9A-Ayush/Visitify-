import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'screen_state_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? firebaseUser;
  AppUser? appUser;
  bool isLoading = true;

  AuthProvider() {
    AuthService().authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    print('AuthProvider: Auth state changed - User: ${user?.uid ?? 'null'}');
    firebaseUser = user;
    if (user != null) {
      print('AuthProvider: Loading app user data...');
      appUser = await AuthService().getAppUser();
      print('AuthProvider: App user loaded - Role: ${appUser?.role}, Status: ${appUser?.status}');
    } else {
      print('AuthProvider: No user, clearing app user');
      appUser = null;
    }
    isLoading = false;
    notifyListeners();
  }

  bool get isLoggedIn => firebaseUser != null;
  String? get role => appUser?.role;
  bool get isProfileComplete => appUser?.profileComplete ?? false;

  Future<void> signOut() async {
    await ScreenStateService.clearLastScreen();
    await AuthService().signOut();
  }

  Future<void> loadUser() async {
    print('AuthProvider: loadUser called - firebaseUser: ${firebaseUser?.uid ?? 'null'}');
    if (firebaseUser != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser!.uid)
                .get();

        if (userDoc.exists) {
          appUser = AppUser.fromMap(userDoc.data()!, firebaseUser!.uid);
          print('AuthProvider: User document loaded - Role: ${appUser?.role}, Status: ${appUser?.status}');
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
      print('AuthProvider: No Firebase user, clearing app user');
      appUser = null;
      notifyListeners();
    }
  }
}
