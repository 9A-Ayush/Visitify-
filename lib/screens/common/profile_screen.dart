import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Custom App Bar with Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(context, user),
              ),

              // Profile Information
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      _buildInfoCard(context, user),
                      const SizedBox(height: 16),

                      // Role-Specific Information
                      _buildRoleSpecificInfo(context, user),
                      const SizedBox(height: 16),

                      // Account Status
                      _buildAccountStatus(context, user),
                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(context, user),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Back Button and Title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/profile_edit'),
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: user.profileImageUrl != null
                  ? Image.network(
                      user.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: AppTheme.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(user.role),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _getRoleDisplayName(user.role),
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withOpacity(0.8),
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: const Icon(Icons.person, size: 60, color: Colors.white),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            user.email,
            AppTheme.primary,
          ),
          const SizedBox(height: 12),

          // Phone
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            user.phone,
            AppTheme.success,
          ),

          // About (if available)
          if (user.about != null && user.about!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.info_outline,
              'About',
              user.about!,
              AppTheme.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSpecificInfo(BuildContext context, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Details',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Role
          _buildInfoRow(
            _getRoleIcon(user.role),
            'Role',
            _getRoleDisplayName(user.role),
            _getRoleColor(user.role),
          ),

          // Resident-specific info
          if (user.role == 'resident') ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.home_outlined,
              'Flat Number',
              user.flatNo.isNotEmpty ? user.flatNo : 'Not assigned',
              AppTheme.primary,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.apartment_outlined,
              'Society ID',
              user.societyId.isNotEmpty ? user.societyId : 'Not assigned',
              AppTheme.secondary,
            ),
          ],

          // Guard-specific info
          if (user.role == 'guard') ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.security_outlined,
              'Duty',
              'Gate Security',
              AppTheme.warning,
            ),
          ],

          // Admin-specific info
          if (user.role == 'admin') ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.admin_panel_settings_outlined,
              'Access Level',
              'Full Access',
              AppTheme.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountStatus(BuildContext context, AppUser user) {
    final isActive = user.status == 'approved';
    final isPending = user.status == 'pending';
    final isProfileComplete = user.profileComplete;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Status',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Account Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.success.withOpacity(0.1)
                      : isPending
                          ? AppTheme.warning.withOpacity(0.1)
                          : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isActive
                      ? Icons.check_circle_outline
                      : isPending
                          ? Icons.pending_outlined
                          : Icons.cancel_outlined,
                  color: isActive
                      ? AppTheme.success
                      : isPending
                          ? AppTheme.warning
                          : AppTheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Active'
                          : isPending
                              ? 'Pending Approval'
                              : user.status.toUpperCase(),
                      style: AppTheme.bodyMedium.copyWith(
                        color: isActive
                            ? AppTheme.success
                            : isPending
                                ? AppTheme.warning
                                : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Profile Completion
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isProfileComplete
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isProfileComplete
                      ? Icons.verified_outlined
                      : Icons.warning_amber_outlined,
                  color: isProfileComplete ? AppTheme.success : AppTheme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isProfileComplete ? 'Complete' : 'Incomplete',
                      style: AppTheme.bodyMedium.copyWith(
                        color: isProfileComplete
                            ? AppTheme.success
                            : AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Warning message for pending status
          if (isPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your account is pending admin approval',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppUser user) {
    return Column(
      children: [
        // Edit Profile Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.buttonRadius,
            boxShadow: AppTheme.buttonShadow,
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/profile_edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(
              'Edit Profile',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Logout Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonRadius,
            border: Border.all(color: AppTheme.error, width: 2),
          ),
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: Text(
              'Logout',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.cardRadius,
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.error),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.of(context).pop();
                
                // Get the auth provider
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                
                // Sign out
                await authProvider.signOut();
                
                // Navigate to login, clearing all previous routes
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(
                'Logout',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'guard':
        return Icons.security;
      case 'resident':
        return Icons.home;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'guard':
        return 'Security Guard';
      case 'resident':
        return 'Resident';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.error;
      case 'guard':
        return AppTheme.warning;
      case 'resident':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }
}
