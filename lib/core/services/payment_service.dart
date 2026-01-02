import 'package:aloulou_chat/data/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize a payment via Cloud Function
  Future<PaymentModel> initiatePayment({
    required String orderId,
    required int amount,
    required String description,
    Map<String, dynamic>? metadata,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Call Cloud Function
      final callable = _functions.httpsCallable('initiateKonnectPayment');
      final result = await callable.call({
        'orderId': orderId,
        'amount': amount,
        'description': description,
        'firstName': firstName,
        'lastName': lastName,
        'email': email ?? user.email,
        'phoneNumber': phoneNumber,
        'metadata': metadata,
      });

      final data = result.data as Map<String, dynamic>;
      
      // Return payment model
      return PaymentModel(
        id: data['paymentId'],
        userId: user.uid,
        orderId: orderId,
        amount: amount,
        status: 'pending',
        paymentRef: data['paymentRef'],
        payUrl: data['payUrl'],
        createdAt: DateTime.now(),
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }

  /// Get payment status
  Future<PaymentModel> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) {
        throw Exception('Payment not found');
      }

      return PaymentModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  /// Verify payment via Cloud Function
  Future<bool> verifyPayment(String paymentRef) async {
    try {
      final callable = _functions.httpsCallable('verifyKonnectPayment');
      final result = await callable.call({'paymentRef': paymentRef});
      return result.data['verified'] as bool;
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Listen to payment status changes
  Stream<PaymentModel> watchPayment(String paymentId) {
    return _firestore
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .map((doc) => PaymentModel.fromFirestore(doc));
  }

  /// Get user's payment history
  Stream<List<PaymentModel>> getUserPayments() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }
}