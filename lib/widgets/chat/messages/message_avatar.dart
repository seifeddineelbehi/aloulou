// widgets/message_avatar.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/chat_message.dart';

class MessageAvatar extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final Animation<double> pulseAnimation;

  const MessageAvatar({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPlaying && message.isVoice 
              ? pulseAnimation.value 
              : 1.0,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: message.isUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[400]!,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: message.isUser 
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              message.isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
              size: 18,
              color: message.isUser ? Colors.white : Colors.grey[600],
            ),
          ),
        );
      },
    );
  }
}