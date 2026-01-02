
// File: presentation/widgets/ai_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai_service_interface.dart';
import '../../core/services/ai_service_manager.dart';

class AIStatusIndicator extends StatelessWidget {
  const AIStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AIServiceManager>(
      builder: (context, aiManager, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aiManager.currentProvider == AIProvider.gemini
                    ? Icons.auto_awesome
                    : Icons.code,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                aiManager.currentProviderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}