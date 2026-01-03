import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  // Send notification to guard about new visitor
  static Future<void> sendGuardNotification({
    required String visitorId,
    required String visitorName,
    required String flatNo,
    required String hostName,
    required String purpose,
  }) async {
    try {
      final notification = {
        'type': 'new_visitor',
        'title': 'New Visitor Registration',
        'message': '$visitorName has registered to visit $flatNo',
        'visitor_id': visitorId,
        'visitor_name': visitorName,
        'flat_no': flatNo,
        'host_name': hostName,
        'purpose': purpose,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'guard',
      };

      await _firestore.collection(_collection).add(notification);
      debugPrint('Guard notification sent successfully');
    } catch (e) {
      debugPrint('Error sending guard notification: $e');
    }
  }

  // Send notification to guard about QR code visitor (auto-approved)
  static Future<void> sendQRVisitorNotification({
    required String visitorId,
    required String visitorName,
    required String flatNo,
    required String hostName,
    required String purpose,
  }) async {
    try {
      final notification = {
        'type': 'qr_visitor_approved',
        'title': 'QR Visitor Auto-Approved',
        'message': '$visitorName has been auto-approved via QR code to visit $flatNo',
        'visitor_id': visitorId,
        'visitor_name': visitorName,
        'flat_no': flatNo,
        'host_name': hostName,
        'purpose': purpose,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'guard',
      };

      await _firestore.collection(_collection).add(notification);
      debugPrint('QR visitor notification sent successfully');
    } catch (e) {
      debugPrint('Error sending QR visitor notification: $e');
    }
  }

  // Send notification to resident about visitor arrival
  static Future<void> sendResidentNotification({
    required String hostId,
    required String visitorId,
    required String visitorName,
    required String visitorPhone,
    required String purpose,
  }) async {
    try {
      final notification = {
        'type': 'visitor_arrival',
        'title': 'Visitor Registered',
        'message': '$visitorName has registered for their visit',
        'visitor_id': visitorId,
        'visitor_name': visitorName,
        'visitor_phone': visitorPhone,
        'purpose': purpose,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_user_id': hostId,
      };

      await _firestore.collection(_collection).add(notification);
      debugPrint('Resident notification sent successfully');
    } catch (e) {
      debugPrint('Error sending resident notification: $e');
    }
  }

  // Send notification to resident about QR visitor (auto-approved)
  static Future<void> sendResidentQRVisitorNotification({
    required String hostId,
    required String visitorId,
    required String visitorName,
    required String visitorPhone,
    required String purpose,
  }) async {
    try {
      final notification = {
        'type': 'qr_visitor_approved',
        'title': 'Your QR Visitor Has Arrived',
        'message': '$visitorName has been automatically approved and is ready for entry',
        'visitor_id': visitorId,
        'visitor_name': visitorName,
        'visitor_phone': visitorPhone,
        'purpose': purpose,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_user_id': hostId,
      };

      await _firestore.collection(_collection).add(notification);
      debugPrint('Resident QR visitor notification sent successfully');
    } catch (e) {
      debugPrint('Error sending resident QR visitor notification: $e');
    }
  }

  // Get notifications for a specific user
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('target_user_id', isEqualTo: userId)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            final docs = snapshot.docs;
            // Sort manually by timestamp (descending)
            docs.sort((a, b) {
              final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              return bTime.compareTo(aTime);
            });
            return docs
                .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      debugPrint('Error in getUserNotifications: $e');
      // Return empty stream on error
      return Stream.value(<AppNotification>[]);
    }
  }

  // Get notifications for guards
  static Stream<List<AppNotification>> getGuardNotifications() {
    try {
      return _firestore
          .collection(_collection)
          .where('target_role', isEqualTo: 'guard')
          .limit(50)
          .snapshots()
          .map((snapshot) {
            final docs = snapshot.docs;
            // Sort manually by timestamp (descending)
            docs.sort((a, b) {
              final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              return bTime.compareTo(aTime);
            });
            return docs
                .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      debugPrint('Error in getGuardNotifications: $e');
      // Return empty stream on error
      return Stream.value(<AppNotification>[]);
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark admin notification as read
  static Future<void> markAdminNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications').doc(notificationId).update({
        'isRead': true,
      });
      debugPrint('Admin notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking admin notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllAsRead([String? userId]) async {
    try {
      final batch = _firestore.batch();
      Query query = _firestore
          .collection(_collection)
          .where('read', isEqualTo: false);
      
      if (userId != null) {
        query = query.where('target_user_id', isEqualTo: userId);
      }

      final notifications = await query.get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Mark all admin notifications as read
  static Future<void> markAllAdminNotificationsAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('admin_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('All admin notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all admin notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Delete admin notification
  static Future<void> deleteAdminNotification(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications').doc(notificationId).delete();
      debugPrint('Admin notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting admin notification: $e');
      rethrow;
    }
  }

  // Get unread notifications count for a user (returns QuerySnapshot for compatibility)
  static Stream<QuerySnapshot> getUnreadNotificationsCount([String? userId]) {
    if (userId != null) {
      return _firestore
          .collection(_collection)
          .where('target_user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots();
    } else {
      // For admin/general unread count
      return _firestore
          .collection(_collection)
          .where('read', isEqualTo: false)
          .snapshots();
    }
  }

  // Send notification to admin about SOS alert
  static Future<void> sendSOSAlertToAdmin({
    required String alertId,
    required String guardId,
    required String location,
  }) async {
    try {
      // Create admin notification
      await _firestore.collection('admin_notifications').add({
        'title': '🚨 EMERGENCY SOS ALERT',
        'message': 'Emergency SOS alert from gate security at $location. Immediate attention required!',
        'type': 'emergency',
        'relatedId': alertId,
        'priority': 'urgent',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'location': location,
          'alert_type': 'SOS',
          'guard_id': guardId,
        },
      });

      // Also create general notification for all admins
      await _firestore.collection(_collection).add({
        'type': 'emergency_sos',
        'title': '🚨 EMERGENCY SOS ALERT',
        'message': 'Emergency SOS alert from gate security. Check admin panel immediately!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'admin',
        'priority': 'urgent',
        'alert_id': alertId,
        'location': location,
        'guard_id': guardId,
      });

      debugPrint('SOS alert notification sent to admin successfully');
    } catch (e) {
      debugPrint('Error sending SOS alert notification: $e');
    }
  }

  // Get admin notifications stream
  static Stream<List<AdminNotification>> getAdminNotifications() {
    return _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get admin notifications count
  static Stream<QuerySnapshot> getAdminUnreadNotificationsCount() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }



  // Send notification when visitor is approved/denied
  static Future<void> sendVisitorStatusNotification({
    required String visitorId,
    required String visitorName,
    required String status, // 'approved' or 'denied'
    required String flatNo,
    required String hostName,
  }) async {
    try {
      final isApproved = status == 'approved';
      final notification = {
        'type': 'visitor_status_update',
        'title': isApproved ? 'Visitor Approved' : 'Visitor Denied',
        'message': isApproved 
            ? '$visitorName has been approved to visit $flatNo'
            : '$visitorName\'s visit to $flatNo has been denied',
        'visitor_id': visitorId,
        'visitor_name': visitorName,
        'flat_no': flatNo,
        'host_name': hostName,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'guard',
      };

      await _firestore.collection(_collection).add(notification);
      debugPrint('Visitor status notification sent successfully');
    } catch (e) {
      debugPrint('Error sending visitor status notification: $e');
    }
  }

  // Send announcement notification to all users
  static Future<void> sendAnnouncementNotification({
    required String announcementId,
    required String title,
    required String description,
    required String priority,
  }) async {
    try {
      // Get all users to send notifications to
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      // Create notification for each user
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        
        // Skip admin users from receiving announcement notifications
        if (userData['role'] == 'admin') continue;
        
        final notificationRef = _firestore.collection(_collection).doc();
        
        final notification = {
          'type': 'announcement',
          'title': 'New Announcement: $title',
          'message': description.length > 100 
              ? '${description.substring(0, 100)}...' 
              : description,
          'announcement_id': announcementId,
          'announcement_title': title,
          'announcement_description': description,
          'priority': priority,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'target_user_id': userId,
        };
        
        batch.set(notificationRef, notification);
      }
      
      // Also create a general notification for guards
      final guardNotificationRef = _firestore.collection(_collection).doc();
      final guardNotification = {
        'type': 'announcement',
        'title': 'New Community Announcement',
        'message': 'A new announcement has been posted: $title',
        'announcement_id': announcementId,
        'announcement_title': title,
        'announcement_description': description,
        'priority': priority,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'target_role': 'guard',
      };
      
      batch.set(guardNotificationRef, guardNotification);
      
      // Commit all notifications
      await batch.commit();
      
      debugPrint('Announcement notifications sent to all users successfully');
    } catch (e) {
      debugPrint('Error sending announcement notifications: $e');
    }
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final String? targetUserId;
  final String? targetRole;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
    this.targetUserId,
    this.targetRole,
    this.data = const {},
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
      targetUserId: map['target_user_id'],
      targetRole: map['target_role'],
      data: Map<String, dynamic>.from(map)..remove('type')..remove('title')..remove('message')..remove('timestamp')..remove('read')..remove('target_user_id')..remove('target_role'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'read': read,
      'target_user_id': targetUserId,
      'target_role': targetRole,
      ...data,
    };
  }
}