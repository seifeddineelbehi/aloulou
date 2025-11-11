import 'package:flutter/material.dart';
import '../../../../../data/models/chat_message.dart';
import '../message_animations.dart';

class MessageStatusIcon extends StatelessWidget {
  final ChatMessage message;
  final MessageAnimations animations;
  final VoidCallback? onRetry;

  const MessageStatusIcon({
    super.key,
    required this.message,
    required this.animations,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.status) {
      case MessageStatus.sending:
        return AnimatedBuilder(
          animation: animations.rotationAnimation,
          builder: (context, child) {
            animations.startRotation();
            return Transform.rotate(
              angle: animations.rotationAnimation.value,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            );
          },
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check_rounded,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.failed:
        return AnimatedBuilder(
          animation: animations.pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: animations.pulseAnimation.value,
              child: GestureDetector(
                onTap: onRetry,
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
