import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String flatNo;
  final double amount;
  final String transactionId;
  final String method;
  final DateTime timestamp;
  final String? receiptUrl;

  Payment({
    required this.id,
    required this.flatNo,
    required this.amount,
    required this.transactionId,
    required this.method,
    required this.timestamp,
    this.receiptUrl,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String id) => Payment(
    id: id,
    flatNo: map['flat_no'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    transactionId: map['transaction_id'] ?? '',
    method: map['method'] ?? '',
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    receiptUrl: map['receipt_url'],
  );

  Map<String, dynamic> toMap() => {
    'flat_no': flatNo,
    'amount': amount,
    'transaction_id': transactionId,
    'method': method,
    'timestamp': timestamp,
    'receipt_url': receiptUrl,
  };
}