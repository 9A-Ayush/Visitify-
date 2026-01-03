import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/visitor.dart';

class VisitorService {
  static const String _collection = 'visitors';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  // Log visitor entry from QR scan
  static Future<String> logVisitorFromQR({
    required String qrInvitationId,
    required String hostId,
    required String hostName,
    required String flatNo,
    required String purpose,
    String? visitorName,
    String? visitorPhone,
    String? imageUrl,
  }) async {
    final id = _uuid.v4();
    
    final visitor = Visitor(
      id: id,
      name: visitorName ?? 'QR Visitor',
      visitingFlat: flatNo,
      phone: visitorPhone ?? '',
      photoUrl: imageUrl,
      status: 'checked_in', // Auto check-in for QR visitors
      entryTime: DateTime.now(),
      purpose: purpose,
      qrCode: qrInvitationId,
      hostId: hostId,
      hostName: hostName,
      isPreApproved: true, // QR visitors are pre-approved
      validUntil: null,
    );

    await _firestore.collection(_collection).doc(id).set(visitor.toMap());
    return id;
  }

  // Manual visitor log entry
  static Future<String> logVisitor({
    required String name,
    required String visitingFlat,
    required String phone,
    String? photoUrl,
    String? purpose,
    String? hostId,
    String? hostName,
    String? vehicleType,
    bool isPreApproved = false,
    DateTime? validUntil,
  }) async {
    final id = _uuid.v4();
    
    final visitor = Visitor(
      id: id,
      name: name,
      visitingFlat: visitingFlat,
      phone: phone,
      photoUrl: photoUrl,
      status: isPreApproved ? 'approved' : 'pending',
      entryTime: DateTime.now(),
      purpose: purpose,
      hostId: hostId,
      hostName: hostName,
      vehicleType: vehicleType,
      isPreApproved: isPreApproved,
      validUntil: validUntil,
    );

    await _firestore.collection(_collection).doc(id).set(visitor.toMap());
    return id;
  }

  // Update visitor status
  static Future<void> updateVisitorStatus(String visitorId, String status) async {
    final updateData = <String, dynamic>{
      'status': status,
    };

    // Add timestamps for specific status changes
    if (status == 'checked_in') {
      updateData['check_in_time'] = FieldValue.serverTimestamp();
    } else if (status == 'checked_out') {
      updateData['exit_time'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection(_collection).doc(visitorId).update(updateData);
  }

  // Get visitor by ID
  static Future<Visitor?> getVisitor(String visitorId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(visitorId).get();
      if (doc.exists) {
        return Visitor.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting visitor: $e');
      return null;
    }
  }

  // Get all visitors stream
  static Stream<List<Visitor>> getAllVisitors() {
    return _firestore
        .collection(_collection)
        .orderBy('entry_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Visitor.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get visitors by status
  static Stream<List<Visitor>> getVisitorsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('entry_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Visitor.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get today's visitors
  static Stream<List<Visitor>> getTodaysVisitors() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('entry_time', isGreaterThanOrEqualTo: startOfDay)
        .where('entry_time', isLessThanOrEqualTo: endOfDay)
        .orderBy('entry_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Visitor.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete visitor record
  static Future<void> deleteVisitor(String visitorId) async {
    await _firestore.collection(_collection).doc(visitorId).delete();
  }
}