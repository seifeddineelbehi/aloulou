  import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/common/empty_state.dart';
import 'animated_session_card.dart';

class SessionsList extends StatelessWidget {
  final List<dynamic> sessions;
  final AnimationController animationController;
  final Function(String) onOpenSession;
  final Function(dynamic) onEditSession;
  final Function(String) onDeleteSession;
  final Function(dynamic) onShareSession;
  final Future<void> Function() onRefresh;

  const SessionsList({
    super.key,
    required this.sessions,
    required this.animationController,
    required this.onOpenSession,
    required this.onEditSession,
    required this.onDeleteSession,
    required this.onShareSession,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Aucune conversation',
        subtitle: 'Créez votre première conversation pour commencer à discuter',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return AnimatedSessionCard(
            session: session,
            index: index,
            totalSessions: sessions.length,
            animationController: animationController,
            onTap: () => onOpenSession(session.id),
            onEdit: () => onEditSession(session),
            onDelete: () => onDeleteSession(session.id),
            onShare: () => onShareSession(session),
          );
        },
      ),
    );
  }
}

