import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_notification.dart';
import '../../services/notification_service.dart';

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
    final scale = MediaQuery.of(context).size.width / 375.0; // scaling factor

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: 18 * scale),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, size: 22 * scale),
            onSelected: (value) => setState(() => selectedFilter = value),
            itemBuilder: (context) => filters.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Row(
                  children: [
                    Icon(
                      selectedFilter == filter ? Icons.check : Icons.circle_outlined,
                      size: 18 * scale,
                      color: selectedFilter == filter ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8 * scale),
                    Text(_getFilterDisplayName(filter), style: TextStyle(fontSize: 14 * scale)),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.mark_email_read, size: 22 * scale),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(scale),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64 * scale, color: Colors.red.shade300),
                        SizedBox(height: 16 * scale),
                        Text('Error loading notifications',
                          style: TextStyle(fontSize: 16 * scale, color: Colors.grey.shade600),
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
                        Icon(Icons.notifications_none, size: 64 * scale, color: Colors.grey.shade400),
                        SizedBox(height: 16 * scale),
                        Text('No notifications found',
                          style: TextStyle(fontSize: 18 * scale, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          'You\'ll see notifications here for complaints, visitors, and emergencies',
                          style: TextStyle(fontSize: 14 * scale, color: Colors.grey.shade500),
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
                  padding: EdgeInsets.all(16 * scale),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(notifications[index], scale);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(double scale) {
    return Container(
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getUnreadNotificationsCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unread Notifications',
                      style: TextStyle(fontSize: 14 * scale, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 4 * scale),
                    Text('$unreadCount',
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(Icons.notifications_active, color: const Color(0xFF4CAF50), size: 24 * scale),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotification notification, double scale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12 * scale),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12 * scale),
            border: notification.isRead
                ? null
                : Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(notification.type, scale),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.title,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(fontSize: 12 * scale, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _getPriorityBadge(notification.priority, scale),
                  if (!notification.isRead) ...[
                    SizedBox(width: 8 * scale),
                    Container(width: 8 * scale, height: 8 * scale,
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12 * scale),
              Text(notification.message,
                style: TextStyle(fontSize: 14 * scale, color: Colors.grey.shade700),
              ),
              if (notification.relatedId != null) ...[
                SizedBox(height: 12 * scale),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToRelated(notification),
                        icon: Icon(Icons.open_in_new, size: 16 * scale),
                        label: Text(_getActionText(notification.type), style: TextStyle(fontSize: 14 * scale)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    IconButton(
                      onPressed: () => _deleteNotification(notification.id),
                      icon: Icon(Icons.delete_outline, size: 20 * scale),
                      color: Colors.red.shade400,
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

  Widget _getNotificationIcon(String type, double scale) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'complaint':
        iconData = Icons.report_problem;
        color = Colors.red;
        break;
      case 'visitor':
        iconData = Icons.people;
        color = Colors.purple;
        break;
      case 'emergency':
        iconData = Icons.emergency;
        color = Colors.red.shade700;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Icon(iconData, color: color, size: 20 * scale),
    );
  }

  Widget _getPriorityBadge(String priority, double scale) {
    Color color;
    String text;

    switch (priority) {
      case 'urgent':
        color = Colors.red;
        text = 'URGENT';
        break;
      case 'high':
        color = Colors.orange;
        text = 'HIGH';
        break;
      case 'medium':
        color = Colors.blue;
        text = 'MED';
        break;
      case 'low':
        color = Colors.green;
        text = 'LOW';
        break;
      default:
        color = Colors.grey;
        text = 'MED';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.bold, color: color),
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
      await NotificationService.markAsRead(notification.id);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
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
      await NotificationService.deleteNotification(notificationId);
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