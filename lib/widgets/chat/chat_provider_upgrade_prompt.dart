import 'package:flutter/material.dart';
import '../../core/services/ai_service_interface.dart';

class ChatProviderUpgradePrompt extends StatelessWidget {
  final String userId;
  final AIProvider requestedProvider;
  final VoidCallback onCancel;
  final Function(bool success) onUpgradeComplete;

  const ChatProviderUpgradePrompt({
    super.key,
    required this.userId,
    required this.requestedProvider,
    required this.onCancel,
    required this.onUpgradeComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Abonnement requis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: Icon(Icons.close, color: Colors.orange[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getProviderMessage(),
            style: TextStyle(color: Colors.orange[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[300]!),
                  ),
                  child: const Text('Utiliser un service gratuit'),
                ),
              ),
              const SizedBox(width: 12),
              // Expanded(
              //   child: ElevatedButton(
              //     onPressed: () => _showUpgradeModal(context),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.orange[600],
              //       foregroundColor: Colors.white,
              //     ),
              //     child: const Text('S\'abonner'),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProviderMessage() {
    switch (requestedProvider) {
      case AIProvider.openAI:
        return 'ChatGPT nécessite un abonnement premium pour accéder aux fonctionnalités avancées.';
      default:
        return 'Ce service nécessite un abonnement premium.';
    }
  }

  // void _showUpgradeModal(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => SubscriptionModal(
  //       userId: userId,
  //       requestedProvider: requestedProvider,
  //       onPaymentComplete: onUpgradeComplete,
  //     ),
  //   );
  // }
}
