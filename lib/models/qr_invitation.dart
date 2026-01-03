import 'package:cloud_firestore/cloud_firestore.dart';

class QRInvitation {
  final String id;
  final String hostId;
  final String hostName;
  final String flatNo;
  final String purpose;
  final DateTime validFrom;
  final DateTime validUntil;
  final int maxVisitors;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;
  final String? imageUrl;

  QRInvitation({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.flatNo,
    required this.purpose,
    required this.validFrom,
    required this.validUntil,
    required this.maxVisitors,
    this.usedCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.notes,
    this.imageUrl,
  });

  factory QRInvitation.fromMap(Map<String, dynamic> map, String id) => QRInvitation(
    id: id,
    hostId: map['host_id'] ?? '',
    hostName: map['host_name'] ?? '',
    flatNo: map['flat_no'] ?? '',
    purpose: map['purpose'] ?? '',
    validFrom: (map['valid_from'] as Timestamp).toDate(),
    validUntil: (map['valid_until'] as Timestamp).toDate(),
    maxVisitors: map['max_visitors'] ?? 1,
    usedCount: map['used_count'] ?? 0,
    isActive: map['is_active'] ?? true,
    createdAt: (map['created_at'] as Timestamp).toDate(),
    notes: map['notes'],
    imageUrl: map['image_url'],
  );

  Map<String, dynamic> toMap() => {
    'host_id': hostId,
    'host_name': hostName,
    'flat_no': flatNo,
    'purpose': purpose,
    'valid_from': validFrom,
    'valid_until': validUntil,
    'max_visitors': maxVisitors,
    'used_count': usedCount,
    'is_active': isActive,
    'created_at': createdAt,
    'notes': notes,
    'image_url': imageUrl,
  };

  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) && 
           usedCount < maxVisitors;
  }
}