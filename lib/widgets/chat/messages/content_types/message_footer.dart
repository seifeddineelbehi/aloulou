import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../data/models/chat_message.dart';
import '../../../../core/utils/file_utils.dart';
import '../message_animations.dart';
import 'message_status_icon.dart';

class MessageFooter extends StatelessWidget {
  final ChatMessage message;
  final MessageAnimations animations;
  final VoidCallback? onRetry;

  const MessageFooter({
    super.key,
    required this.message,
    required this.animations,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TimeUtils.formatTime(message.timestamp),
            style: TextStyle(
              color: message.isUser
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            MessageStatusIcon(
              message: message,
              animations: animations,
              onRetry: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

