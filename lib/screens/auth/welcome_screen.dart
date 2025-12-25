import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // Dynamic sizing
    final logoSize = width * 0.4; // 40% of screen width
    final buttonHeight = height * 0.07; // 7% of screen height
    final horizontalPadding = width * 0.06;
    final fontScale = (width / 400).clamp(0.8, 1.3);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // Top section with logo and branding
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.home_outlined,
                          size: logoSize * 0.5,
                          color: AppTheme.primary,
                        ),
                      ),

                      SizedBox(height: height * 0.05),

                      // App Name
                      Text(
                        'Visitify',
                        style: AppTheme.headingLarge.copyWith(
                          fontSize: 42 * fontScale,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      // Tagline
                      Text(
                        'Urban Smart Living',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: height * 0.015),

                      // Description
                      Text(
                        'Intelligent Society Management\nfor Modern Communities',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16 * fontScale,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Feature highlights
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: height * 0.015),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureHighlight(
                          Icons.qr_code_scanner,
                          'QR Access',
                          fontScale,
                        ),
                        _buildFeatureHighlight(
                          Icons.notifications_active_outlined,
                          'Real-time Alerts',
                          fontScale,
                        ),
                        _buildFeatureHighlight(
                          Icons.security_outlined,
                          'Secure Management',
                          fontScale,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18 * fontScale,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18 * fontScale,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // Guest access
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/qr_scanner');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white.withOpacity(0.8),
                              size: 20 * fontScale,
                            ),
                            SizedBox(width: width * 0.02),
                            Text(
                              'Scan QR as Visitor',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withOpacity(0.8),
                                fontSize: 14 * fontScale,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.05),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlight(IconData icon, String label, double fontScale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28 * fontScale,
          ),
        ),
        SizedBox(height: 12),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12 * fontScale,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
