// message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/chat_message.dart';
import 'message_avatar.dart';
import 'message_content.dart';
import 'message_animations.dart';
import 'content_types/message_options_sheet.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final Function(String)? onPlayAudio;
  final Function(String)? onStopAudio;
  final Function(String)? onPauseAudio;
  final Function(String)? onResumeAudio;
  final bool isPlaying;
  final Function(String)? onOpenFile;
  final Function(String)? onOpenImage;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onDelete,
    this.onPlayAudio,
    this.onStopAudio,
    this.onPauseAudio,
    this.onResumeAudio,
    this.isPlaying = false,
    this.onOpenFile,
    this.onOpenImage,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late MessageAnimations _animations;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animations = MessageAnimations(this);
    _animations.startEntryAnimation(widget.message, widget.isPlaying);
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animations.handleStateChanges(
      widget.message,
      oldWidget.message,
      widget.isPlaying,
      oldWidget.isPlaying,
    );
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animations.combinedAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _animations.slideAnimation,
          child: FadeTransition(
            opacity: _animations.fadeAnimation,
            child: Transform.scale(
              scale: _isPressed 
                  ? 0.98 
                  : (_animations.pulseAnimation.value * _animations.scaleAnimation.value),
              child: _buildMessageContainer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContainer() {
    return Container(
      margin: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: widget.message.isUser ? 60 : 16,
        right: widget.message.isUser ? 16 : 60,
      ),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isUser) ...[
            MessageAvatar(
              message: widget.message,
              isPlaying: widget.isPlaying,
              pulseAnimation: _animations.pulseAnimation,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(child: _buildBubble()),
          if (widget.message.isUser) ...[
            const SizedBox(width: 12),
            MessageAvatar(
              message: widget.message,
              isPlaying: widget.isPlaying,
              pulseAnimation: _animations.pulseAnimation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: _showMessageOptions,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: MessageContent(
          message: widget.message,
          isPlaying: widget.isPlaying,
          isHovered: _isHovered,
          animations: _animations,
          onPlayAudio: widget.onPlayAudio,
          onStopAudio: widget.onStopAudio,
          onOpenFile: widget.onOpenFile,
          onOpenImage: widget.onOpenImage,
          onRetry: widget.onRetry,
        ),
      ),
    );
  }

  void _showMessageOptions() {
    HapticFeedback.mediumImpact();
    MessageOptionsSheet.show(
      context: context,
      message: widget.message,
      isPlaying: widget.isPlaying,
      onPlayAudio: widget.onPlayAudio,
      onStopAudio: widget.onStopAudio,
      onOpenFile: widget.onOpenFile,
      onOpenImage: widget.onOpenImage,
      onRetry: widget.onRetry,
      onDelete: widget.onDelete,
    );
  }
}