import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_provider.dart' as app_auth;

import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

class GuardHomeScreen extends StatelessWidget {
  const GuardHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.appUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                _buildCustomAppBar(context, user),
                
                // Welcome Card
                _buildWelcomeCard(context, user),
                
                const SizedBox(height: 24),
                
                // Quick Stats
                _buildQuickStats(context),
                
                const SizedBox(height: 24),
                
                // Emergency SOS
                _buildEmergencySection(context),
                
                const SizedBox(height: 32),
                
                // Guard Services
                _buildGuardServices(context),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildCustomAppBar(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Dashboard',
                style: AppTheme.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getShift()} Shift • Gate Security',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Icon(
                  Icons.language,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: user?.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            user!.profileImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.security,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name ?? 'Guard'}',
                  style: AppTheme.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep the community safe and secure with smart monitoring tools',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/guard_qr_scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: Text(
                      'Scan QR Code',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Overview',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getTodaysVisitorsStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatCard(
                      'Total Visitors',
                      count.toString(),
                      Icons.people_outline,
                      AppTheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getTodaysPreApprovedVisitorsStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatCard(
                      'Pre-approved',
                      count.toString(),
                      Icons.check_circle_outline,
                      AppTheme.success,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getTodaysVisitorsStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('visitors')
        .where('entry_time', isGreaterThanOrEqualTo: startOfDay)
        .where('entry_time', isLessThanOrEqualTo: endOfDay)
        .snapshots();
  }

  Stream<QuerySnapshot> _getTodaysPreApprovedVisitorsStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('visitors')
        .where('entry_time', isGreaterThanOrEqualTo: startOfDay)
        .where('entry_time', isLessThanOrEqualTo: endOfDay)
        .where('is_pre_approved', isEqualTo: true)
        .snapshots();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Text(
                value,
                style: AppTheme.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emergency,
              color: AppTheme.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency SOS',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to send emergency alert to admin and residents immediately',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: AppTheme.buttonRadius,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _sendSOSAlert(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              child: Text(
                'SEND SOS ALERT',
                style: AppTheme.bodyLarge.copyWith(
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

  Widget _buildGuardServices(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guard Services',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildServiceCard(
                'Scan QR Code',
                Icons.qr_code_scanner,
                AppTheme.accent,
                'Verify QR codes',
                () => Navigator.pushNamed(context, '/guard_qr_scanner'),
              ),
              _buildServiceCard(
                'Log Visitor',
                Icons.person_add_outlined,
                AppTheme.primary,
                'Manual entry',
                () => Navigator.pushNamed(context, '/guard_visitor_log'),
              ),
              _buildServiceCard(
                'Pre-approved',
                Icons.verified_outlined,
                AppTheme.success,
                'Approved visitors',
                () => Navigator.pushNamed(context, '/guard_preapproved_visitors'),
              ),
              _buildServiceCard(
                'All Visitors',
                Icons.people_alt_outlined,
                AppTheme.indigo,
                'Visitor logs',
                () => Navigator.pushNamed(context, '/guard_all_visitors'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendSOSAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.cardRadius,
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(
              'Emergency SOS',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to send an emergency alert? This will notify all admins and residents immediately.',
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendEmergencyAlert(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                'SEND ALERT',
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

  Future<void> _sendEmergencyAlert(BuildContext context) async {
    try {
      // Create emergency alert record
      final alertDoc = await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'type': 'SOS',
        'message': 'Emergency SOS alert from gate security',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'location': 'Main Gate',
        'guard_id': FirebaseAuth.instance.currentUser?.uid,
      });

      // Create admin notification for SOS alert
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': '🚨 EMERGENCY SOS ALERT',
        'message': 'Emergency SOS alert from gate security at Main Gate. Immediate attention required!',
        'type': 'emergency',
        'relatedId': alertDoc.id,
        'priority': 'urgent',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'location': 'Main Gate',
          'alert_type': 'SOS',
          'guard_id': FirebaseAuth.instance.currentUser?.uid,
        },
      });

      // Also create general notification for all admins
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'emergency_sos',
        'title': '🚨 EMERGENCY SOS ALERT',
        'message': 'Emergency SOS alert from gate security. Check admin panel immediately!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'admin',
        'priority': 'urgent',
        'alert_id': alertDoc.id,
        'location': 'Main Gate',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency alert sent successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending alert: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _getShift() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'Morning';
    if (hour >= 14 && hour < 22) return 'Evening';
    return 'Night';
  }
}