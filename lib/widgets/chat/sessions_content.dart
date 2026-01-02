import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/viewmodels/chat_history_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/common/error_widget.dart';
import 'sessions_list.dart';

class SessionsContent extends StatelessWidget {
  final TabController tabController;
  final AnimationController animationController;
  final Function(String) onOpenSession;
  final Function(dynamic) onEditSession;
  final Function(String) onDeleteSession;
  final Function(dynamic) onShareSession;

  const SessionsContent({
    super.key,
    required this.tabController,
    required this.animationController,
    required this.onOpenSession,
    required this.onEditSession,
    required this.onDeleteSession,
    required this.onShareSession,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHistoryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && !viewModel.hasSessions) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (viewModel.errorMessage != null && !viewModel.hasSessions) {
          return CustomErrorWidget(
            message: viewModel.errorMessage!,
            onRetry: () => viewModel.loadSessions(),
          );
        }

        return TabBarView(
          controller: tabController,
          children: [
            SessionsList(
              sessions: viewModel.sessions,
              animationController: animationController,
              onOpenSession: onOpenSession,
              onEditSession: onEditSession,
              onDeleteSession: onDeleteSession,
              onShareSession: onShareSession,
              onRefresh: () => viewModel.refreshSessions(),
            ),
            SessionsList(
              sessions: viewModel.todaySessions,
              animationController: animationController,
              onOpenSession: onOpenSession,
              onEditSession: onEditSession,
              onDeleteSession: onDeleteSession,
              onShareSession: onShareSession,
              onRefresh: () => viewModel.refreshSessions(),
            ),
            SessionsList(
              sessions: viewModel.thisWeekSessions,
              animationController: animationController,
              onOpenSession: onOpenSession,
              onEditSession: onEditSession,
              onDeleteSession: onDeleteSession,
              onShareSession: onShareSession,
              onRefresh: () => viewModel.refreshSessions(),
            ),
            SessionsList(
              sessions: viewModel.thisMonthSessions,
              animationController: animationController,
              onOpenSession: onOpenSession,
              onEditSession: onEditSession,
              onDeleteSession: onDeleteSession,
              onShareSession: onShareSession,
              onRefresh: () => viewModel.refreshSessions(),
            ),
          ],
        );
      },
    );
  }
}

