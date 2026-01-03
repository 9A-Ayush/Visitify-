import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../route_helper.dart';
import '../../theme/app_theme.dart';
import '../../utils/onboarding_helper.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('SplashScreen: Starting initialization...');
    
    // Show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      // Check onboarding first
      final onboardingCompleted = await OnboardingHelper.isOnboardingCompleted();
      print('SplashScreen: Onboarding completed: $onboardingCompleted');

      if (!onboardingCompleted) {
        print('SplashScreen: Going to onboarding');
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      print('SplashScreen: Current user: ${currentUser?.uid ?? 'null'}');

      if (currentUser == null) {
        print('SplashScreen: No user found, going to welcome');
        Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      // User exists, get their data from Firestore
      print('SplashScreen: User exists, loading user data...');
      final appUser = await AuthService().getAppUser();
      print('SplashScreen: App user: ${appUser?.role ?? 'null'}, Status: ${appUser?.status ?? 'null'}, ProfileComplete: ${appUser?.profileComplete ?? false}');

      if (appUser == null) {
        print('SplashScreen: No app user data found, going to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Route user based on their role and status
      print('SplashScreen: Routing user...');
      await RouteHelper.routeUser(
        context,
        appUser.role,
        appUser.profileComplete,
        status: appUser.status,
      );

    } catch (e) {
      print('SplashScreen: Error during initialization: $e');
      // On error, go to welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final fontScale = (width / 400).clamp(0.8, 1.3);
    final logoSize = width * 0.35; // adaptive logo
    final spacing = height * 0.02;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Spacer (to keep content centered vertically)
                    SizedBox(height: availableHeight * 0.1),

                    // Logo + App Texts
                    Column(
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.home_outlined,
                            size: logoSize * 0.5,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: spacing * 2),

                        Text(
                          'Visitify',
                          style: AppTheme.headingLarge.copyWith(
                            fontSize: 36 * fontScale,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: spacing),

                        Text(
                          'Smart Visitor Management',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: spacing / 1.5),

                        Text(
                          'Seamless Society Access Control',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14 * fontScale,
                          ),
                        ),
                      ],
                    ),

                    // Loading Indicator
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: spacing),
                              Text(
                                'Initializing...',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14 * fontScale,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Feature Highlights (always visible at bottom)
                    Padding(
                      padding: EdgeInsets.only(bottom: height * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureIcon(Icons.qr_code, 'QR Check-in', fontScale),
                          _buildFeatureIcon(Icons.notifications_active, 'Alerts', fontScale),
                          _buildFeatureIcon(Icons.security, 'Secure', fontScale),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, double fontScale) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24 * fontScale,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10 * fontScale,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}