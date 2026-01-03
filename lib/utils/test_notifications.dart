import 'package:cloud_firestore/cloud_firestore.dart';

class TestNotifications {
  static Future<void> createTestAdminNotification() async {
    try {
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'Test Admin Notification',
        'message': 'This is a test notification to verify the admin notification system is working.',
        'type': 'visitor',
        'priority': 'medium',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'test': true,
        },
      });
      print('Test admin notification created successfully');
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }

  static Future<void> createTestSOSAlert() async {
    try {
      // Create emergency alert
      final alertDoc = await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'type': 'SOS',
        'message': 'Test Emergency SOS alert from gate security',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'location': 'Main Gate',
        'test': true,
      });

      // Create admin notification for SOS alert
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': '🚨 TEST EMERGENCY SOS ALERT',
        'message': 'Test Emergency SOS alert from gate security at Main Gate. This is a test!',
        'type': 'emergency',
        'relatedId': alertDoc.id,
        'priority': 'urgent',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'location': 'Main Gate',
          'alert_type': 'SOS',
          'test': true,
        },
      });

      print('Test SOS alert created successfully');
    } catch (e) {
      print('Error creating test SOS alert: $e');
    }
  }
}