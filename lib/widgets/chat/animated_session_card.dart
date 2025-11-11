import 'package:flutter/material.dart';
import '../../../../widgets/chat/session_card.dart';

class AnimatedSessionCard extends StatelessWidget {
  final dynamic session;
  final int index;
  final int totalSessions;
  final AnimationController animationController;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const AnimatedSessionCard({
    super.key,
    required this.session,
    required this.index,
    required this.totalSessions,
    required this.animationController,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final animationValue = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Interval(
            (index / totalSessions) * 0.1,
            ((index + 1) / totalSessions) * 0.1 + 0.9,
            curve: Curves.easeOut,
          ),
        ));

        return FadeTransition(
          opacity: animationValue,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animationValue),
            child: SessionCard(
              session: session,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
              onShare: onShare,
            ),
          ),
        );
      },
    );
  }
}
