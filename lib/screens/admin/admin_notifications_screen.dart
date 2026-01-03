import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String selectedFilter = 'all';
  final List<String> filters = [
    'all', 'unread', 'complaint', 'visitor', 'emergency'
  ];

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
                        'Notifications',
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
                                color: selectedFilter == filter ? AppTheme.success : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(_getFilterDisplayName(filter)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mark_email_read, color: Colors.white),
                      onPressed: _markAllAsRead,
                      tooltip: 'Mark all as read',
                    ),
                  ],
                ),
              ),
              
              // Stats Card
              _buildStatsCard(),
              
              // Notifications List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getNotificationsStream(),
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
                            Text('Error loading notifications',
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
                            Icon(Icons.notifications_none, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text('No notifications found',
                              style: AppTheme.headingSmall.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll see notifications here for complaints, visitors, and emergencies',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final notifications = snapshot.data!.docs
                        .map((doc) => AdminNotification.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(notifications[index]);
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
        stream: NotificationService.getAdminUnreadNotificationsCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unread Notifications',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text('$unreadCount',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_active, color: AppTheme.primary, size: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: notification.isRead ? AppTheme.cardShadow : AppTheme.softShadow,
        border: notification.isRead 
            ? null 
            : Border.all(color: AppTheme.primary, width: 2),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.title,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _getPriorityBadge(notification.priority),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(notification.message,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              if (notification.relatedId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToRelated(notification),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(_getActionText(notification.type)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _deleteNotification(notification.id),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppTheme.error,
                      tooltip: 'Delete',
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

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'complaint':
        iconData = Icons.report_problem;
        color = AppTheme.warning;
        break;
      case 'visitor':
        iconData = Icons.people;
        color = AppTheme.accent;
        break;
      case 'emergency':
        iconData = Icons.emergency;
        color = AppTheme.error;
        break;
      case 'announcement':
        iconData = Icons.campaign;
        color = AppTheme.primary;
        break;
      default:
        iconData = Icons.notifications;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _getPriorityBadge(String priority) {
    final color = AppTheme.getPriorityColor(priority);
    String text;

    switch (priority) {
      case 'urgent':
        text = 'URGENT';
        break;
      case 'high':
        text = 'HIGH';
        break;
      case 'medium':
        text = 'MED';
        break;
      case 'low':
        text = 'LOW';
        break;
      default:
        text = 'MED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    Query query = FirebaseFirestore.instance
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true);

    switch (selectedFilter) {
      case 'unread':
        query = query.where('isRead', isEqualTo: false);
        break;
      case 'complaint':
      case 'visitor':
      case 'emergency':
        query = query.where('type', isEqualTo: selectedFilter);
        break;
    }

    return query.snapshots();
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Notifications';
      case 'unread':
        return 'Unread Only';
      case 'complaint':
        return 'Complaints';
      case 'visitor':
        return 'Visitors';
      case 'emergency':
        return 'Emergency';
      default:
        return filter;
    }
  }

  String _getActionText(String type) {
    switch (type) {
      case 'complaint':
        return 'View Complaint';
      case 'visitor':
        return 'View Visitor';
      case 'emergency':
        return 'View Alert';
      default:
        return 'View Details';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  Future<void> _handleNotificationTap(AdminNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markAdminNotificationAsRead(notification.id);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAdminNotificationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notifications as read: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteAdminNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToRelated(AdminNotification notification) {
    switch (notification.type) {
      case 'complaint':
        Navigator.pushNamed(context, '/admin_complaints');
        break;
      case 'visitor':
        Navigator.pushNamed(context, '/admin_visitor_management');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon!')),
        );
    }
  }
}