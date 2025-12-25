import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String role;
  const ProfileCompletionScreen({Key? key, required this.role})
    : super(key: key);

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final extraInfoController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    extraInfoController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (extraInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in the required information'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await AuthService().completeProfile(currentUser.uid, {
        'extraInfo': extraInfoController.text.trim(),
      });

      if (!mounted) return;

      // Route user based on their role
      switch (widget.role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin_home');
          break;
        case 'guard':
          Navigator.pushReplacementNamed(context, '/guard_home');
          break;

        default:
          Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile completion failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  String _getRoleSpecificHint() {
    switch (widget.role) {
      case 'guard':
        return 'Enter your assigned area and shift details';

      case 'admin':
        return 'Enter additional admin information';
      default:
        return 'Enter additional information';
    }
  }

  String _getRoleSpecificLabel() {
    switch (widget.role) {
      case 'guard':
        return 'Area & Shift Details';

      case 'admin':
        return 'Admin Information';
      default:
        return 'Additional Information';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Complete Profile',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Welcome Section
              Text(
                'Complete Your Profile',
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Additional info for ${widget.role.capitalize()}',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              // Role-specific information
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.inputRadius,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextFormField(
                  controller: extraInfoController,
                  maxLines: 3,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: _getRoleSpecificHint(),
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.buttonRadius,
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonRadius,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save & Continue',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const Spacer(),
              // Help Text
              Text(
                'This information helps us provide\nyou with better service',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
