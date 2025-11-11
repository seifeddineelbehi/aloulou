import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/chat_message.dart';

class VoiceWaveAnimation extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final Animation<double> waveAnimation;

  const VoiceWaveAnimation({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.waveAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: (message.isUser ? Colors.white : AppColors.primary)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (message.isUser ? Colors.white : AppColors.primary)
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: waveAnimation,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (index) {
              final animationDelay = (index * 0.1) % 1.0;
              final animationValue = (((waveAnimation.value + animationDelay) % 1.0) * 2 - 1).abs();
              final height = isPlaying 
                  ? (10 + (index % 5) * 4 * animationValue).clamp(8.0, 24.0)
                  : (10 + (index % 3) * 2).toDouble();
              
              return Container(
                width: 2.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: (message.isUser ? Colors.white : AppColors.primary)
                      .withOpacity(isPlaying ? 0.9 : 0.6),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: isPlaying ? [
                    BoxShadow(
                      color: (message.isUser ? Colors.white : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 2,
                    ),
                  ] : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

