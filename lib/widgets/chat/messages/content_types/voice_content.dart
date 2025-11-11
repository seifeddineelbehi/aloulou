import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../data/models/chat_message.dart';
import '../message_animations.dart';
import 'voice_wave_animation.dart';

class VoiceContent extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final MessageAnimations animations;
  final Function(String)? onPlayAudio;
  final Function(String)? onStopAudio;

  const VoiceContent({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.animations,
    this.onPlayAudio,
    this.onStopAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced play button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (isPlaying) {
                onStopAudio?.call(message.id);
              } else {
                onPlayAudio?.call(message.id);
              }
            },
            child: AnimatedBuilder(
              animation: animations.pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isPlaying ? animations.pulseAnimation.value : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: message.isUser
                            ? [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ]
                            : [
                                AppColors.primary.withOpacity(0.9),
                                AppColors.primary.withOpacity(0.7),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (message.isUser ? Colors.white : AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: message.isUser ? AppColors.primary : Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Enhanced voice wave visualization
          Expanded(
            child: VoiceWaveAnimation(
              message: message,
              isPlaying: isPlaying,
              waveAnimation: animations.waveAnimation,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Enhanced duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (message.isUser ? Colors.white : AppColors.primary)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.audioDurationDisplay,
              style: TextStyle(
                color: message.isUser 
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

