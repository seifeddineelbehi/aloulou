import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback? onAttachFile;
  final VoidCallback? onShowMediaOptions;
  final bool isComposing;
  final bool isSending;
  final String hintText;
  final int maxLines;
  final int minLines;
  final bool enableAttachment;
  final bool enableVoiceNote;
  final VoidCallback? onVoiceNoteStart;
  final VoidCallback? onVoiceNoteStop;
  final VoidCallback? onVoiceNoteCancel;
  final bool isRecordingVoice;
  final Duration recordingDuration;
  final bool canSendMessage;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSend,
    this.onAttachFile,
    this.onShowMediaOptions,
    required this.isComposing,
    required this.isSending,
    this.hintText = 'Tapez votre message...',
    this.maxLines = 5,
    this.minLines = 1,
    this.enableAttachment = true,
    this.enableVoiceNote = true,
    this.onVoiceNoteStart,
    this.onVoiceNoteStop,
    this.onVoiceNoteCancel,
    this.isRecordingVoice = false,
    this.recordingDuration = Duration.zero,
    this.canSendMessage = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  late AnimationController _scaleAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isLongPressing = false;
  Offset _initialPanPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8, 
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: AppColors.primary,
    ).animate(_scaleAnimationController);
  }

  @override
  void didUpdateWidget(MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isComposing != oldWidget.isComposing) {
      if (widget.isComposing) {
        _scaleAnimationController.forward();
      } else {
        _scaleAnimationController.reverse();
      }
    }

    if (widget.isRecordingVoice != oldWidget.isRecordingVoice) {
      if (widget.isRecordingVoice) {
        _pulseAnimationController.repeat(reverse: true);
        _slideAnimationController.forward();
      } else {
        _pulseAnimationController.stop();
        _pulseAnimationController.reset();
        _slideAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty && 
        !widget.isSending && 
        widget.canSendMessage) {
      HapticFeedback.lightImpact();
      widget.onSend();
    }
  }

  void _handleVoiceStart() {
    if (!widget.canSendMessage || widget.isSending) return;
    
    setState(() {
      _isLongPressing = true;
    });
    HapticFeedback.mediumImpact();
    widget.onVoiceNoteStart?.call();
  }

  void _handleVoiceEnd() {
    if (!_isLongPressing) return;
    
    setState(() {
      _isLongPressing = false;
    });
    HapticFeedback.lightImpact();
    widget.onVoiceNoteStop?.call();
  }

  void _handleVoiceCancel() {
    if (!_isLongPressing) return;
    
    setState(() {
      _isLongPressing = false;
    });
    HapticFeedback.heavyImpact();
    widget.onVoiceNoteCancel?.call();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isRecordingVoice) return;
    
    final dx = details.globalPosition.dx - _initialPanPosition.dx;
    if (dx < -100) { // Slide left to cancel
      _handleVoiceCancel();
    }
  }

  Widget _buildAttachmentButton() {
    if (!widget.enableAttachment) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: widget.onShowMediaOptions ?? widget.onAttachFile,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            GestureDetector(
              onTap: _handleVoiceCancel,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Recording indicator
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Recording text and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enregistrement en cours...',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatDuration(widget.recordingDuration),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Send recording button
            GestureDetector(
              onTap: _handleVoiceEnd,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalInterface() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAttachmentButton(),
            Expanded(
              child: _buildTextInput(),
            ),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.focusNode.hasFocus
              ? AppColors.primary.withOpacity(0.5)
              : Colors.transparent,
          width: widget.focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: (_) => _handleSend(),
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.send,
        keyboardType: TextInputType.multiline,
        enabled: widget.canSendMessage && !widget.isRecordingVoice,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          counterText: '',
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1000),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (_shouldShowVoiceButton()) {
          _initialPanPosition = details.globalPosition;
        }
      },
      onLongPressStart: (_) {
        if (_shouldShowVoiceButton() && widget.canSendMessage) {
          _handleVoiceStart();
        }
      },
      onLongPressEnd: (_) {
        if (widget.isRecordingVoice) {
          _handleVoiceEnd();
        }
      },
      onPanUpdate: _handlePanUpdate,
      onTap: () {
        if (!_shouldShowVoiceButton() && 
            widget.isComposing && 
            !widget.isSending && 
            widget.canSendMessage) {
          _handleSend();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isRecordingVoice ? _pulseAnimation.value : _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getButtonColor(),
                shape: BoxShape.circle,
                boxShadow: _shouldShowShadow()
                    ? [
                        BoxShadow(
                          color: _getButtonColor().withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: _buildButtonIcon(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (widget.isSending) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (widget.isRecordingVoice) {
      return const Center(
        child: Icon(
          Icons.stop,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    if (_shouldShowVoiceButton()) {
      return const Center(
        child: Icon(
          Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    return const Center(
      child: Icon(
        Icons.send,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  bool _shouldShowVoiceButton() {
    return !widget.isComposing && 
           widget.enableVoiceNote && 
           !widget.isSending &&
           widget.canSendMessage;
  }

  bool _shouldShowShadow() {
    return widget.isComposing || 
           widget.isRecordingVoice || 
           (_shouldShowVoiceButton() && widget.canSendMessage);
  }

  Color _getButtonColor() {
    if (!widget.canSendMessage) {
      return Colors.grey[400]!;
    }
    
    if (widget.isRecordingVoice) {
      return Colors.red;
    }
    
    if (widget.isComposing) {
      return AppColors.primary;
    }
    
    if (_shouldShowVoiceButton()) {
      return AppColors.primary;
    }
    
    return Colors.grey[400]!;
  }

  void _showVoiceInstruction() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Maintenez appuyé pour enregistrer un message vocal'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRecordingVoice) {
      return _buildRecordingInterface();
    }
    return _buildNormalInterface();
  }
}

// Extensions pour des configurations prédéfinies
extension MessageInputExtension on MessageInput {
  // Configuration basique sans fonctionnalités avancées
  static MessageInput basic({
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onSend,
    required bool isComposing,
    required bool isSending,
    bool canSendMessage = true,
  }) {
    return MessageInput(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSend: onSend,
      isComposing: isComposing,
      isSending: isSending,
      enableAttachment: false,
      enableVoiceNote: false,
      canSendMessage: canSendMessage,
    );
  }

  // Configuration complète avec toutes les fonctionnalités
  static MessageInput complete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onSend,
    required VoidCallback onShowMediaOptions,
    required VoidCallback onVoiceNoteStart,
    required VoidCallback onVoiceNoteStop,
    required VoidCallback onVoiceNoteCancel,
    required bool isComposing,
    required bool isSending,
    required bool isRecordingVoice,
    Duration recordingDuration = Duration.zero,
    bool canSendMessage = true,
    String hintText = 'Tapez votre message...',
  }) {
    return MessageInput(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSend: onSend,
      onShowMediaOptions: onShowMediaOptions,
      onVoiceNoteStart: onVoiceNoteStart,
      onVoiceNoteStop: onVoiceNoteStop,
      onVoiceNoteCancel: onVoiceNoteCancel,
      isComposing: isComposing,
      isSending: isSending,
      isRecordingVoice: isRecordingVoice,
      recordingDuration: recordingDuration,
      canSendMessage: canSendMessage,
      hintText: hintText,
      enableAttachment: true,
      enableVoiceNote: true,
    );
  }

  // Configuration uniquement pour les messages texte avec pièces jointes
  static MessageInput withAttachments({
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onSend,
    required VoidCallback onShowMediaOptions,
    required bool isComposing,
    required bool isSending,
    bool canSendMessage = true
  }) {
    return MessageInput(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSend: onSend,
      onShowMediaOptions: onShowMediaOptions,
      isComposing: isComposing,
      isSending: isSending,
      enableAttachment: true,
      enableVoiceNote: false,
      canSendMessage: canSendMessage,
    );
  }
}