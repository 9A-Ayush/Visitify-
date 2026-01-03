import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/visitor.dart';
import '../../theme/app_theme.dart';

class AdminVisitorManagementScreen extends StatefulWidget {
  const AdminVisitorManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminVisitorManagementScreen> createState() => _AdminVisitorManagementScreenState();
}

class _AdminVisitorManagementScreenState extends State<AdminVisitorManagementScreen> {
  String selectedFilter = 'all';
  final List<String> filters = ['all', 'pending', 'approved', 'rejected', 'active', 'exited'];

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
                        'Visitor Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onSelected: (value) => setState(() => selectedFilter = value),
                      itemBuilder: (context) => filters.map((filter) {
                        return PopupMenuItem(
                          value: filter,
                          child: Row(
                            children: [
                              Icon(
                                selectedFilter == filter ? Icons.check : Icons.circle_outlined,
                                size: 18,
                                color: selectedFilter == filter ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(_getFilterDisplayName(filter)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // Stats Card
              _buildStatsCard(),
              
              // Visitors List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getVisitorsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: AppTheme.error),
                            const SizedBox(height: 16),
                            Text('Error loading visitors',
                              style: AppTheme.bodyLarge.copyWith(color: AppTheme.error),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text('No visitors found',
                              style: AppTheme.headingSmall.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Visitors will appear here when they register to visit the society',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final visitors = snapshot.data!.docs
                        .map((doc) => Visitor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: visitors.length,
                      itemBuilder: (context, index) {
                        return _buildVisitorCard(visitors[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final visitors = snapshot.data!.docs;
          final totalVisitors = visitors.length;
          final pendingVisitors = visitors.where((doc) => 
            (doc.data() as Map<String, dynamic>)['status'] == 'pending').length;
          final activeVisitors = visitors.where((doc) => 
            (doc.data() as Map<String, dynamic>)['status'] == 'active').length;
          final todayVisitors = visitors.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final entryTime = (data['entry_time'] as Timestamp?)?.toDate();
            if (entryTime == null) return false;
            final today = DateTime.now();
            return entryTime.year == today.year && 
                   entryTime.month == today.month && 
                   entryTime.day == today.day;
          }).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visitor Statistics', style: AppTheme.headingSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Total', totalVisitors, AppTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatItem('Pending', pendingVisitors, AppTheme.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatItem('Active', activeVisitors, AppTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatItem('Today', todayVisitors, AppTheme.accent)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTheme.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorCard(Visitor visitor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () => _showVisitorDetails(visitor),
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: visitor.photoUrl != null 
                        ? NetworkImage(visitor.photoUrl!) 
                        : null,
                    child: visitor.photoUrl == null 
                        ? Icon(Icons.person, color: AppTheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitor.name,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Visiting: ${visitor.visitingFlat}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (visitor.hostName != null)
                          Text(
                            'Host: ${visitor.hostName}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(visitor.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    visitor.phone,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(visitor.entryTime),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (visitor.purpose != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Purpose: ${visitor.purpose}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (visitor.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateVisitorStatus(visitor.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateVisitorStatus(visitor.id, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = AppTheme.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getVisitorsStream() {
    Query query = FirebaseFirestore.instance
        .collection('visitors')
        .orderBy('entry_time', descending: true);

    if (selectedFilter != 'all') {
      query = query.where('status', isEqualTo: selectedFilter);
    }

    return query.snapshots();
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Visitors';
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'active':
        return 'Currently Inside';
      case 'exited':
        return 'Exited';
      default:
        return filter;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _updateVisitorStatus(String visitorId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .update({'status': status});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visitor status updated to $status'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating visitor status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showVisitorDetails(Visitor visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text('Visitor Details', style: AppTheme.headingSmall),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', visitor.name),
              _buildDetailRow('Phone', visitor.phone),
              _buildDetailRow('Visiting Flat', visitor.visitingFlat),
              if (visitor.hostName != null)
                _buildDetailRow('Host', visitor.hostName!),
              if (visitor.purpose != null)
                _buildDetailRow('Purpose', visitor.purpose!),
              _buildDetailRow('Status', visitor.status.toUpperCase()),
              _buildDetailRow('Entry Time', _formatFullDateTime(visitor.entryTime)),
              if (visitor.exitTime != null)
                _buildDetailRow('Exit Time', _formatFullDateTime(visitor.exitTime!)),
              if (visitor.vehicleType != null)
                _buildDetailRow('Vehicle', visitor.vehicleType!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}