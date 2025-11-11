// widgets/message_content.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/chat_message.dart';
import 'message_animations.dart';
import 'content_types/text_content.dart';
import 'content_types/voice_content.dart';
import 'content_types/image_content.dart';
import 'content_types/file_content.dart';
import 'content_types/message_footer.dart';
import 'content_types/shimmer_effect.dart';


class MessageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final bool isHovered;
  final MessageAnimations animations;
  final Function(String)? onPlayAudio;
  final Function(String)? onStopAudio;
  final Function(String)? onOpenFile;
  final Function(String)? onOpenImage;
  final VoidCallback? onRetry;

  const MessageContent({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.isHovered,
    required this.animations,
    this.onPlayAudio,
    this.onStopAudio,
    this.onOpenFile,
    this.onOpenImage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
        minWidth: 80,
      ),
      decoration: BoxDecoration(
        gradient: _getBubbleGradient(),
        borderRadius: _getBorderRadius(),
        boxShadow: _getBubbleShadow(),
        border: _getBubbleBorder(),
      ),
      child: Stack(
        children: [
          // Shimmer effect for sending messages
          if (message.status == MessageStatus.sending)
            ShimmerEffect(
              animation: animations.shimmerAnimation,
              borderRadius: _getBorderRadius(),
            ),
          
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMessageContent(),
              MessageFooter(
                message: message,
                animations: animations,
                onRetry: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.voice:
        return VoiceContent(
          message: message,
          isPlaying: isPlaying,
          animations: animations,
          onPlayAudio: onPlayAudio,
          onStopAudio: onStopAudio,
        );
      case MessageType.image:
        return ImageContent(
          message: message,
          onOpenImage: onOpenImage,
        );
      case MessageType.file:
      case MessageType.document:
        return FileContent(
          message: message,
          onOpenFile: onOpenFile,
        );
      case MessageType.text:
      default:
        return TextContent(message: message);
    }
  }

  Gradient _getBubbleGradient() {
    if (message.isUser) {
      switch (message.status) {
        case MessageStatus.failed:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.9),
              Colors.red.withOpacity(0.7),
            ],
          );
        case MessageStatus.sending:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.7),
              AppColors.primary.withOpacity(0.5),
            ],
          );
        default:
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          );
      }
    }
    
    // AI message gradient
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.grey[50]!,
      ],
    );
  }

  List<BoxShadow> _getBubbleShadow() {
    if (message.status == MessageStatus.failed) {
      return [
        BoxShadow(
          color: Colors.red.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: message.isUser 
            ? AppColors.primary.withOpacity(isHovered ? 0.4 : 0.25)
            : Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
        blurRadius: isHovered ? 20 : 12,
        offset: const Offset(0, 4),
        spreadRadius: isHovered ? 2 : 0,
      ),
      if (isHovered)
        BoxShadow(
          color: message.isUser 
              ? AppColors.primary.withOpacity(0.1)
              : Colors.black.withOpacity(0.03),
          blurRadius: 40,
          offset: const Offset(0, 8),
          spreadRadius: 4,
        ),
    ];
  }

  Border? _getBubbleBorder() {
    if (!message.isUser) {
      return Border.all(
        color: Colors.grey.withOpacity(0.15),
        width: 1,
      );
    }
    return null;
  }

  BorderRadius _getBorderRadius() {
    const radius = 24.0;
    const smallRadius = 8.0;
    
    return BorderRadius.only(
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: message.isUser
          ? const Radius.circular(radius)
          : const Radius.circular(smallRadius),
      bottomRight: message.isUser
          ? const Radius.circular(smallRadius)
          : const Radius.circular(radius),
    );
  }
}