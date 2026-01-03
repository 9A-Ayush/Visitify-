import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'screen_state_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get AppUser from Firestore
  Future<AppUser?> getAppUser() async {
    final user = _auth.currentUser;
    print('AuthService: getAppUser - currentUser: ${user?.uid ?? 'null'}');
    
    if (user == null) {
      print('AuthService: No current user');
      return null;
    }
    
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      print('AuthService: Firestore doc exists: ${doc.exists}');
      
      if (!doc.exists) {
        print('AuthService: User document does not exist in Firestore');
        return null;
      }
      
      final appUser = AppUser.fromMap(doc.data()!, user.uid);
      print('AuthService: AppUser created - Role: ${appUser.role}, Status: ${appUser.status}');
      return appUser;
    } catch (e) {
      print('AuthService: Error getting app user: $e');
      return null;
    }
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Email/Password Register
  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Phone Sign In (OTP flow)
  Future<void> signInWithPhone(
    String phone,
    Function(String, int?) codeSent,
    Function(String) verificationFailed,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: codeSent,
      verificationFailed:
          (e) => verificationFailed(e.message ?? 'Verification failed'),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Configure Google Sign-In with explicit configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Add explicit client ID for better compatibility
        clientId: '155438760432-adeamb330sjbrj10md7g8ge884s3gasp.apps.googleusercontent.com',
      );
      
      // Sign out first to ensure clean state
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In: User cancelled');
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print('Google Sign-In: Attempting Firebase authentication...');
      final result = await _auth.signInWithCredential(credential);
      print('Google Sign-In: Success - User: ${result.user?.uid}');
      
      return result;
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Google Sign-Up for Registration
  Future<UserCredential?> registerWithGoogle({required String role}) async {
    try {
      // Configure Google Sign-In with explicit configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Add explicit client ID for better compatibility
        clientId: '155438760432-adeamb330sjbrj10md7g8ge884s3gasp.apps.googleusercontent.com',
      );
      
      // Sign out first to ensure clean state
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-Up: User cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Google Sign-Up: Attempting Firebase authentication...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      print('Google Sign-Up: Success - User: ${user.uid}');

      // Extract first 4 letters from Google display name
      String extractedName = 'User';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final cleanName = user.displayName!.replaceAll(
          RegExp(r'[^a-zA-Z]'),
          '',
        );
        extractedName =
            cleanName.length >= 4 ? cleanName.substring(0, 4) : cleanName;
      }

      // Create AppUser with Google account info
      final appUser = AppUser(
        uid: user.uid,
        name: extractedName,
        email: user.email ?? '',
        phone: '', // No phone for Google sign-up
        role: role,
        flatNo: '',
        societyId: '',
        status: role == 'resident' ? 'pending' : 'active',
        profileComplete:
            role != 'resident', // Residents need to complete profile
        profileImageUrl: user.photoURL,
      );

      await createOrUpdateUser(appUser);
      return userCredential;
    } catch (e) {
      print('Google Sign-Up Error: $e');
      throw Exception('Google registration failed: $e');
    }
  }

  // Create/Update user in Firestore
  Future<void> createOrUpdateUser(AppUser user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // Admin-invite registration (pre-filled)
  Future<UserCredential> registerWithAdminInvite({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String inviteCode,
  }) async {
    try {
      // Verify invite code (you can add validation logic here)
      // For now, we'll just create the user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = AppUser(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: 'admin',
        flatNo: '',
        societyId: '',
        status: 'active',
        profileComplete: true,
        profileImageUrl: '',
      );

      await _db.collection('users').doc(user.uid).set(user.toMap());
      return credential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Self-signup registration
  Future<UserCredential> registerWithSelfSignup({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required String flatNo,
    required String societyId,
  }) async {
    final cred = await registerWithEmail(email, password);
    final appUser = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      flatNo: flatNo,
      societyId: societyId,
      status: 'pending',
      profileComplete: false,
      profileImageUrl: null,
    );
    await createOrUpdateUser(appUser);
    return cred;
  }

  // Update profile completion
  Future<void> completeProfile(
    String uid,
    Map<String, dynamic> extraData,
  ) async {
    await _db.collection('users').doc(uid).update({
      ...extraData,
      'profileComplete': true,
    });
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear saved screen state when user logs out
      await ScreenStateService.clearLastScreen();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google Sign-In with explicit configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '155438760432-adeamb330sjbrj10md7g8ge884s3gasp.apps.googleusercontent.com',
      );
      await googleSignIn.signOut();
      
      print('AuthService: Sign out completed');
    } catch (e) {
      print('AuthService: Sign out error: $e');
      // Still clear screen state even if sign out fails
      await ScreenStateService.clearLastScreen();
    }
  }
}
