import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Complaint {
  final String id;
  final String raisedBy;
  final String flatNo;
  final String category;
  final String description;
  final String? imageUrl;
  final String status; // Open, In Progress, Resolved
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Status constants
  static const String statusOpen = 'Open';
  static const String statusInProgress = 'In Progress';
  static const String statusResolved = 'Resolved';

  Complaint({
    required this.id,
    required this.raisedBy,
    required this.flatNo,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Complaint.fromMap(Map<String, dynamic> map, String id) => Complaint(
    id: id,
    raisedBy: map['raised_by'] ?? '',
    flatNo: map['flat_no'] ?? '',
    category: map['category'] ?? '',
    description: map['description'] ?? '',
    imageUrl: map['image_url'],
    status: map['status'] ?? '',
    createdAt: map['created_at'] != null 
        ? (map['created_at'] as Timestamp).toDate() 
        : null,
    updatedAt: map['updated_at'] != null 
        ? (map['updated_at'] as Timestamp).toDate() 
        : null,
  );

  Map<String, dynamic> toMap() => {
    'raised_by': raisedBy,
    'flat_no': flatNo,
    'category': category,
    'description': description,
    'image_url': imageUrl,
    'status': status,
    'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  String get formattedCreatedDate {
    if (createdAt == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(createdAt!);
  }

  String get formattedCreatedDateTime {
    if (createdAt == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy hh:mm a').format(createdAt!);
  }
}