import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/onboarding_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.home_work_outlined,
      title: 'Smart Society\nManagement',
      subtitle: 'Modern Living Redefined',
      description:
          'Transform your residential community with intelligent access control, seamless communication, and enhanced security.',
      gradient: AppTheme.primaryGradient,
      features: [
        'Digital Access Control',
        'Community Management',
        'Real-time Updates'
      ],
    ),
    OnboardingPage(
      icon: Icons.qr_code_2,
      title: 'Contactless\nEntry System',
      subtitle: 'Quick & Secure Access',
      description:
          'Generate unique QR codes for visitors and residents. Enable touchless entry with advanced security protocols.',
      gradient: AppTheme.accentGradient,
      features: ['QR Code Generation', 'Instant Verification', 'Access Logs'],
    ),
    OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Instant\nNotifications',
      subtitle: 'Stay Always Connected',
      description:
          'Receive real-time alerts for visitor arrivals, emergency updates, and important community announcements.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.success, AppTheme.primary],
      ),
      features: ['Visitor Alerts', 'Emergency Updates', 'Community News'],
    ),
    OnboardingPage(
      icon: Icons.verified_user_outlined,
      title: 'Advanced\nSecurity',
      subtitle: 'Complete Peace of Mind',
      description:
          'Multi-layer security with photo verification, visitor tracking, comprehensive access logs, and emergency protocols.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.warning, AppTheme.secondary],
      ),
      features: ['Photo Verification', 'Access Tracking', 'Emergency Protocols'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingHelper.completeOnboarding();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final fontScale = (width / 400).clamp(0.8, 1.2);
    final iconSize = width * 0.32;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildOnboardingPage(
              _pages[index],
              iconSize,
              fontScale,
            ),
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: _currentPage < _pages.length - 1
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: width * 0.06,
                right: width * 0.06,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.45),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  SizedBox(height: height * 0.04),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 16 * fontScale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) SizedBox(width: width * 0.04),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                _pages[_currentPage].gradient.colors.first,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              fontSize: 16 * fontScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(
      OnboardingPage page, double iconSize, double fontScale) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: page.gradient),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * fontScale),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight;
              return Column(
                children: [
                  SizedBox(height: maxHeight * 0.08),

                  // Icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Icon(
                      page.icon,
                      size: iconSize * 0.5,
                      color: page.gradient.colors.first,
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.05),

                  // Title
                  Text(
                    page.title,
                    style: AppTheme.headingLarge.copyWith(
                      color: Colors.white,
                      fontSize: 30 * fontScale,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: maxHeight * 0.02),

                  // Subtitle
                  Text(
                    page.subtitle,
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: maxHeight * 0.03),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      page.description,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16 * fontScale,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.04),

                  // Features
                  Container(
                    padding: EdgeInsets.all(20 * fontScale),
                    margin: EdgeInsets.symmetric(horizontal: 8 * fontScale),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: page.features
                          .map(
                            (feature) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14 * fontScale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const Spacer(),
                  SizedBox(height: maxHeight * 0.16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final LinearGradient gradient;
  final List<String> features;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.features,
  });
}
