import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String orderId;
  final int amount; // in millimes
  final String currency;
  final String status; // pending, completed, failed
  final String? paymentRef;
  final String? payUrl;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.amount,
    this.currency = 'TND',
    required this.status,
    this.paymentRef,
    this.payUrl,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'TND',
      status: data['status'] ?? 'pending',
      paymentRef: data['paymentRef'],
      payUrl: data['payUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentRef': paymentRef,
      'payUrl': payUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'metadata': metadata,
    };
  }
}