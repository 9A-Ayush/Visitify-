import 'package:cloud_firestore/cloud_firestore.dart';

class Visitor {
  final String id;
  final String name;
  final String visitingFlat;
  final String phone;
  final String? photoUrl;
  final String status;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? purpose;
  final String? qrCode;
  final String? hostId;
  final String? hostName;
  final String? vehicleType;
  final bool isPreApproved;
  final DateTime? validUntil;

  Visitor({
    required this.id,
    required this.name,
    required this.visitingFlat,
    required this.phone,
    this.photoUrl,
    required this.status,
    required this.entryTime,
    this.exitTime,
    this.purpose,
    this.qrCode,
    this.hostId,
    this.hostName,
    this.vehicleType,
    this.isPreApproved = false,
    this.validUntil,
  });

  factory Visitor.fromMap(Map<String, dynamic> map, String id) => Visitor(
    id: id,
    name: map['name'] ?? '',
    visitingFlat: map['visiting_flat'] ?? '',
    phone: map['phone'] ?? '',
    photoUrl: map['photo_url'],
    status: map['status'] ?? '',
    entryTime: (map['entry_time'] as Timestamp).toDate(),
    exitTime: map['exit_time'] != null ? (map['exit_time'] as Timestamp).toDate() : null,
    purpose: map['purpose'],
    qrCode: map['qr_code'],
    hostId: map['host_id'],
    hostName: map['host_name'],
    vehicleType: map['vehicle_type'],
    isPreApproved: map['is_pre_approved'] ?? false,
    validUntil: map['valid_until'] != null ? (map['valid_until'] as Timestamp).toDate() : null,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'visiting_flat': visitingFlat,
    'phone': phone,
    'photo_url': photoUrl,
    'status': status,
    'entry_time': entryTime,
    'exit_time': exitTime,
    'purpose': purpose,
    'qr_code': qrCode,
    'host_id': hostId,
    'host_name': hostName,
    'vehicle_type': vehicleType,
    'is_pre_approved': isPreApproved,
    'valid_until': validUntil,
  };
}