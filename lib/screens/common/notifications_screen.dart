import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    return ResponsiveScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          icon: const Icon(Icons.mark_email_read),
          onPressed: () => _markAllAsRead(context, user?.uid ?? ''),
          tooltip: 'Mark all as read',
        ),
      ],
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: user?.role == 'guard' 
              ? NotificationService.getGuardNotifications()
              : NotificationService.getUserNotifications(user?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: ResponsiveUtils.getIconSize(context, size: 'xl'),
                      color: AppTheme.error,
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
                    Text(
                      'Error loading notifications',
                      style: ResponsiveUtils.getBodyStyle(context),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none,
                        size: ResponsiveUtils.getIconSize(context, size: 'xl'),
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
                    Text(
                      'No notifications yet',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                    Text(
                      'You\'ll see notifications here when visitors register, announcements are posted, or when there are updates',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: ResponsiveUtils.getResponsivePadding(context),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getSpacing(context, size: 'sm'),
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: notification.read ? AppTheme.cardShadow : AppTheme.softShadow,
        border: notification.read 
            ? null 
            : Border.all(color: AppTheme.primary, width: 2),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(context, notification),
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildNotificationIcon(notification.type),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'sm')),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDateTime(notification.timestamp),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                
                Text(
                  notification.message,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                if (notification.data.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                  _buildNotificationDetails(context, notification),
                ],
                
                if (!notification.read) ...[
                  SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _markAsRead(context, notification.id),
                        child: const Text('Mark as read'),
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

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'new_visitor':
        icon = Icons.person_add;
        color = AppTheme.primary;
        break;
      case 'visitor_arrival':
        icon = Icons.notifications_active;
        color = AppTheme.success;
        break;
      case 'visitor_status_update':
        icon = Icons.update;
        color = AppTheme.warning;
        break;
      case 'announcement':
        icon = Icons.campaign;
        color = AppTheme.accent;
        break;
      default:
        icon = Icons.notifications;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationDetails(BuildContext context, AppNotification notification) {
    final details = <Widget>[];

    if (notification.data['visitor_name'] != null) {
      details.add(_buildDetailRow('Visitor', notification.data['visitor_name']));
    }

    if (notification.data['flat_no'] != null) {
      details.add(_buildDetailRow('Flat', notification.data['flat_no']));
    }

    if (notification.data['host_name'] != null) {
      details.add(_buildDetailRow('Host', notification.data['host_name']));
    }

    if (notification.data['purpose'] != null) {
      details.add(_buildDetailRow('Purpose', notification.data['purpose']));
    }

    if (notification.data['visitor_phone'] != null) {
      details.add(_buildDetailRow('Phone', notification.data['visitor_phone']));
    }

    if (notification.data['status'] != null) {
      details.add(_buildDetailRow('Status', notification.data['status'].toString().toUpperCase()));
    }

    // Announcement specific details
    if (notification.data['announcement_title'] != null) {
      details.add(_buildDetailRow('Title', notification.data['announcement_title']));
    }

    if (notification.data['priority'] != null) {
      details.add(_buildDetailRow('Priority', notification.data['priority'].toString().toUpperCase()));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
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

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    if (!notification.read) {
      _markAsRead(context, notification.id);
    }

    // Navigate to relevant screen based on notification type
    switch (notification.type) {
      case 'new_visitor':
      case 'visitor_status_update':
        if (notification.data['visitor_id'] != null) {
          // Navigate to visitor details or visitor management
          Navigator.pushNamed(context, '/visitor_management');
        }
        break;
      case 'visitor_arrival':
        Navigator.pushNamed(context, '/visitor_management');
        break;
      case 'announcement':
        Navigator.pushNamed(context, '/announcements');
        break;
    }
  }

  Future<void> _markAsRead(BuildContext context, String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _markAllAsRead(BuildContext context, String userId) async {
    try {
      await NotificationService.markAllAsRead(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}