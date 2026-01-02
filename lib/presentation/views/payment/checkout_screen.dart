import 'package:aloulou_chat/core/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String orderId;
  final int amount; // in millimes
  final String description;
  final Map<String, dynamic>? orderData;

  const CheckoutScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.description,
    this.orderData,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showError('Please sign in to continue');
        return;
      }

      // Initiate payment
      final payment = await _paymentService.initiatePayment(
        orderId: widget.orderId,
        amount: widget.amount,
        description: widget.description,
        metadata: widget.orderData,
        email: user.email,
        firstName: user.displayName?.split(' ').first,
        lastName: user.displayName?.split(' ').last,
      );

      // Navigate to payment screen
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(payment: payment),
          ),
        );

        if (result != null && result['success'] == true) {
          _showSuccess('Payment completed successfully!');
          // Navigate to success screen or back
          Navigator.of(context).pop(true);
        } else {
          _showError('Payment was cancelled or failed');
        }
      }
    } catch (e) {
      _showError('Failed to process payment: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountInDinars = widget.amount / 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Order ID: ${widget.orderId}'),
                    const SizedBox(height: 8),
                    Text(widget.description),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${amountInDinars.toStringAsFixed(3)} TND',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Pay with Konnect',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure payment powered by Konnect',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}