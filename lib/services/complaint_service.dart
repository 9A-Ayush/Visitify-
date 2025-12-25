import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';

class ComplaintService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'complaints';

  // Create a new complaint
  static Future<String> createComplaint({
    required String raisedBy,
    required String flatNo,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'raised_by': raisedBy,
        'flat_no': flatNo,
        'category': category,
        'description': description,
        'image_url': imageUrl,
        'status': Complaint.statusOpen,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create complaint: $e');
    }
  }

  // Update complaint status
  static Future<void> updateComplaintStatus(String complaintId, String status) async {
    try {
      await _firestore.collection(_collection).doc(complaintId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }

  // Get complaints for a specific user
  static Stream<List<Complaint>> getUserComplaints(String userId, {String? statusFilter}) {
    // Simple query to avoid composite index requirement
    Query query = _firestore
        .collection(_collection)
        .where('raised_by', isEqualTo: userId);

    return query.snapshots().map((snapshot) {
      var complaints = snapshot.docs.map((doc) {
        return Complaint.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter by status in memory if needed
      if (statusFilter != null && statusFilter != 'All') {
        complaints = complaints.where((complaint) => complaint.status == statusFilter).toList();
      }

      // Sort by created date in memory (newest first)
      complaints.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return complaints;
    });
  }

  // Get all complaints (for admin)
  static Stream<List<Complaint>> getAllComplaints({String? statusFilter}) {
    // Simple query to get all complaints
    Query query = _firestore.collection(_collection);

    return query.snapshots().map((snapshot) {
      var complaints = snapshot.docs.map((doc) {
        return Complaint.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter by status in memory if needed
      if (statusFilter != null && statusFilter != 'All') {
        complaints = complaints.where((complaint) => complaint.status == statusFilter).toList();
      }

      // Sort by created date in memory (newest first)
      complaints.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return complaints;
    });
  }

  // Get complaint statistics
  static Stream<Map<String, int>> getComplaintStats() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final complaints = snapshot.docs;
      return {
        'total': complaints.length,
        'open': complaints.where((doc) => doc['status'] == Complaint.statusOpen).length,
        'in_progress': complaints.where((doc) => doc['status'] == Complaint.statusInProgress).length,
        'resolved': complaints.where((doc) => doc['status'] == Complaint.statusResolved).length,
      };
    });
  }

  // Delete complaint (admin only)
  static Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection(_collection).doc(complaintId).delete();
    } catch (e) {
      throw Exception('Failed to delete complaint: $e');
    }
  }
}