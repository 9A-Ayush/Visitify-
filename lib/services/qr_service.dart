import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_invitation.dart';

class QRService {
  static const String _collection = 'qr_invitations';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  // Generate QR invitation
  static Future<QRInvitation> generateQRInvitation({
    required String hostId,
    required String hostName,
    required String flatNo,
    required String purpose,
    required DateTime validFrom,
    required DateTime validUntil,
    required int maxVisitors,
    String? notes,
    String? imageUrl,
  }) async {
    final id = _uuid.v4();
    
    final invitation = QRInvitation(
      id: id,
      hostId: hostId,
      hostName: hostName,
      flatNo: flatNo,
      purpose: purpose,
      validFrom: validFrom,
      validUntil: validUntil,
      maxVisitors: maxVisitors,
      createdAt: DateTime.now(),
      notes: notes,
      imageUrl: imageUrl,
    );

    await _firestore.collection(_collection).doc(id).set(invitation.toMap());
    return invitation;
  }

  // Get QR invitation by ID
  static Future<QRInvitation?> getQRInvitation(String invitationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(invitationId).get();
      if (doc.exists) {
        return QRInvitation.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting QR invitation: $e');
      return null;
    }
  }

  // Validate and use QR invitation
  static Future<bool> useQRInvitation(String invitationId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(invitationId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          throw Exception('Invitation not found');
        }

        final invitation = QRInvitation.fromMap(doc.data()!, doc.id);
        
        if (!invitation.isValid) {
          throw Exception('Invitation is not valid');
        }

        // Increment used count
        transaction.update(docRef, {
          'used_count': invitation.usedCount + 1,
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error using QR invitation: $e');
      return false;
    }
  }

  // Get host's QR invitations
  static Stream<List<QRInvitation>> getHostInvitations(String hostId) {
    return _firestore
        .collection(_collection)
        .where('host_id', isEqualTo: hostId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QRInvitation.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Deactivate QR invitation
  static Future<void> deactivateInvitation(String invitationId) async {
    await _firestore.collection(_collection).doc(invitationId).update({
      'is_active': false,
    });
  }

  // Generate QR data string
  static String generateQRData(String invitationId) {
    final qrData = {
      'type': 'visitor_invitation',
      'invitation_id': invitationId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(qrData);
  }

  // Parse QR data string
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      if (data['type'] == 'visitor_invitation') {
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing QR data: $e');
      return null;
    }
  }
}