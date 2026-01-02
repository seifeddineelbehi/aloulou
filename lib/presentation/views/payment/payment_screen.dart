import 'package:aloulou_chat/core/services/payment_service.dart';
import 'package:aloulou_chat/data/models/payment_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PaymentScreen extends StatefulWidget {
  final PaymentModel payment;

  const PaymentScreen({
    Key? key,   
    required this.payment,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _listenToPaymentStatus();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkPaymentCompletion(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payment.payUrl!));
  }

  void _listenToPaymentStatus() {
    _paymentService.watchPayment(widget.payment.id).listen((payment) {
      if (payment.status == 'completed') {
        _handleSuccess();
      } else if (payment.status == 'failed') {
        _handleFailure();
      }
    });
  }

  void _checkPaymentCompletion(String url) {
    if (url.contains('payment-success') || url.contains('success')) {
      _verifyAndComplete();
    } else if (url.contains('payment-failure') || url.contains('fail')) {
      _handleFailure();
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_isVerifying) return;
    
    setState(() => _isVerifying = true);

    try {
      final verified = await _paymentService.verifyPayment(
        widget.payment.paymentRef!,
      );

      if (verified) {
        _handleSuccess();
      } else {
        _handleFailure();
      }
    } catch (e) {
      _showError('Verification failed: $e');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _handleSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop({'success': true, 'payment': widget.payment});
  }

  void _handleFailure() {
    if (!mounted) return;
    Navigator.of(context).pop({'success': false, 'payment': widget.payment});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, {'success': false}),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isVerifying)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}