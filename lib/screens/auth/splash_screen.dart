import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_provider.dart' as my_auth;
import '../../route_helper.dart';
import '../../theme/app_theme.dart';
import '../../utils/onboarding_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Show splash screen for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final onboardingCompleted = await OnboardingHelper.isOnboardingCompleted();

    if (!onboardingCompleted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final authProvider =
        Provider.of<my_auth.AuthProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    await authProvider.loadUser();

    if (!mounted) return;

    RouteHelper.routeUser(
      context,
      authProvider.role ?? '',
      authProvider.isProfileComplete,
      status: authProvider.appUser?.status,
    );
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
