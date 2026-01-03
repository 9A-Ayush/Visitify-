import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // --- User statistics ---
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      int totalUsers = usersSnapshot.docs.length;
      int residents = 0;
      int vendors = 0;
      int guards = 0;
      int pendingApprovals = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? '';
        final status = data['status'] ?? '';

        switch (role) {
          case 'resident':
            residents++;
            if (status == 'pending') pendingApprovals++;
            break;
          case 'vendor':
            vendors++;
            break;
          case 'guard':
            guards++;
            break;
        }
      }

      // --- Visitor statistics ---
      final visitorsSnapshot =
          await FirebaseFirestore.instance.collection('visitors').get();

      int totalVisitors = visitorsSnapshot.docs.length;
      int approvedVisitors = 0;
      int pendingVisitors = 0;

      for (var doc in visitorsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'approved') approvedVisitors++;
        if (status == 'pending') pendingVisitors++;
      }

      // --- Complaint statistics ---
      final complaintsSnapshot =
          await FirebaseFirestore.instance.collection('complaints').get();

      int totalComplaints = complaintsSnapshot.docs.length;
      int resolvedComplaints = 0;
      int pendingComplaints = 0;

      for (var doc in complaintsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'resolved') resolvedComplaints++;
        if (status == 'pending') pendingComplaints++;
      }

      // --- Vendor statistics ---
      final servicesSnapshot =
          await FirebaseFirestore.instance.collection('vendor_services').get();
      final adsSnapshot =
          await FirebaseFirestore.instance.collection('vendor_ads').get();

      int totalServices = servicesSnapshot.docs.length;
      int activeServices = 0;
      int totalAds = adsSnapshot.docs.length;
      int activeAds = 0;

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true) activeServices++;
      }

      for (var doc in adsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'active') activeAds++;
      }

      setState(() {
        _analytics = {
          'totalUsers': totalUsers,
          'residents': residents,
          'vendors': vendors,
          'guards': guards,
          'pendingApprovals': pendingApprovals,
          'totalVisitors': totalVisitors,
          'approvedVisitors': approvedVisitors,
          'pendingVisitors': pendingVisitors,
          'totalComplaints': totalComplaints,
          'resolvedComplaints': resolvedComplaints,
          'pendingComplaints': pendingComplaints,
          'totalServices': totalServices,
          'activeServices': activeServices,
          'totalAds': totalAds,
          'activeAds': activeAds,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(context, 'User Statistics'),
                            _buildStatWrap(context, [
                              _buildStatCard(context, 'Total Users',
                                  '${_analytics['totalUsers'] ?? 0}', Icons.people, AppTheme.primary),
                              _buildStatCard(context, 'Residents',
                                  '${_analytics['residents'] ?? 0}', Icons.home, AppTheme.success),
                              _buildStatCard(context, 'Vendors',
                                  '${_analytics['vendors'] ?? 0}', Icons.business, AppTheme.warning),
                              _buildStatCard(context, 'Guards',
                                  '${_analytics['guards'] ?? 0}', Icons.security, AppTheme.secondary),
                            ]),

                            const SizedBox(height: 24),

                            _buildSectionTitle(context, 'Pending Approvals'),
                            _buildStatWrap(context, [
                              _buildStatCard(context, 'Pending Residents',
                                  '${_analytics['pendingApprovals'] ?? 0}', Icons.pending_actions, AppTheme.warning),
                              _buildStatCard(context, 'Pending Visitors',
                                  '${_analytics['pendingVisitors'] ?? 0}', Icons.people_outline, AppTheme.warning),
                            ]),

                            const SizedBox(height: 24),

                            _buildSectionTitle(context, 'Visitor Management'),
                            _buildStatWrap(context, [
                              _buildStatCard(context, 'Total Visitors',
                                  '${_analytics['totalVisitors'] ?? 0}', Icons.people_alt, AppTheme.accent),
                              _buildStatCard(context, 'Approved Visitors',
                                  '${_analytics['approvedVisitors'] ?? 0}', Icons.check_circle, AppTheme.success),
                            ]),

                            const SizedBox(height: 24),

                            _buildSectionTitle(context, 'Complaint Management'),
                            _buildStatWrap(context, [
                              _buildStatCard(context, 'Total Complaints',
                                  '${_analytics['totalComplaints'] ?? 0}', Icons.report_problem, AppTheme.error),
                              _buildStatCard(context, 'Resolved',
                                  '${_analytics['resolvedComplaints'] ?? 0}', Icons.check_circle_outline, AppTheme.success),
                              _buildStatCard(context, 'Pending',
                                  '${_analytics['pendingComplaints'] ?? 0}', Icons.pending, AppTheme.warning),
                            ]),

                            const SizedBox(height: 24),

                            _buildSectionTitle(context, 'Vendor Management'),
                            _buildStatWrap(context, [
                              _buildStatCard(context, 'Total Services',
                                  '${_analytics['totalServices'] ?? 0}', Icons.build, AppTheme.accent),
                              _buildStatCard(context, 'Active Services',
                                  '${_analytics['activeServices'] ?? 0}', Icons.verified, AppTheme.success),
                              _buildStatCard(context, 'Total Ads',
                                  '${_analytics['totalAds'] ?? 0}', Icons.campaign, AppTheme.secondary),
                              _buildStatCard(context, 'Active Ads',
                                  '${_analytics['activeAds'] ?? 0}', Icons.ads_click, AppTheme.warning),
                            ]),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTheme.headingMedium,
      ),
    );
  }

  Widget _buildStatWrap(BuildContext context, List<Widget> children) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children,
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      constraints: BoxConstraints(
        minWidth: screenW * 0.4,
        maxWidth: screenW * 0.9,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  softWrap: true,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headingLarge.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
