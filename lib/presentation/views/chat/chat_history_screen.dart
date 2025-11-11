// File: presentation/views/chat/chat_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../viewmodels/chat_history_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/chat/chat_history_app_bar.dart';
import '../../../widgets/chat/search_section.dart';
import '../../../widgets/chat/time_filter_tabs.dart';
import '../../../widgets/chat/sessions_content.dart';
import '../../../widgets/chat/new_chat_fab.dart';
import '../../../widgets/common/page_transitions.dart';
import '../../../core/utils/session_actions.dart';
import '../../../core/utils/snackbar_utils.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with TickerProviderStateMixin, ChatHistoryMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeHistory();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _tabController = TabController(length: 4, vsync: this);
    _animationController.forward();
  }

  void _initializeHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final historyViewModel = context.read<ChatHistoryViewModel>();

      if (authViewModel.currentUser?.uid != null) {
        historyViewModel.initialize(authViewModel.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: ChatHistoryAppBar(
        onRefresh: _handleRefresh,
      ),
      body: _buildBody(),
      floatingActionButton: NewChatFAB(onPressed: _handleCreateNewSession),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSearchSection(),
          TimeFilterTabs(tabController: _tabController),
          _buildSessionsContent(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SearchSection(
      controller: _searchController,
      onChanged: _handleSearch,
      onClear: _handleClearSearch,
    );
  }

  Widget _buildSessionsContent() {
    return Expanded(
      child: SessionsContent(
        tabController: _tabController,
        animationController: _animationController,
        onOpenSession: _handleOpenSession,
        onEditSession: _handleEditSession,
        onDeleteSession: _handleDeleteSession,
        onShareSession: _handleShareSession,
      ),
    );
  }

  // Event Handlers
  void _handleRefresh() {
    context.read<ChatHistoryViewModel>().refreshSessions();
  }

  void _handleSearch(String query) {
    context.read<ChatHistoryViewModel>().searchSessions(query);
  }

  void _handleClearSearch() {
    _searchController.clear();
    context.read<ChatHistoryViewModel>().clearSearch();
  }

  void _handleOpenSession(String sessionId) {
    context.go('/chat/session/$sessionId');
  }

  Future<void> _handleCreateNewSession() async {
    try {
      final historyViewModel = context.read<ChatHistoryViewModel>();
      final session = await historyViewModel.createNewSession();
      
      if (session != null && mounted) {
        context.go('/chat/session/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Erreur lors de la création de la conversation',
        );
      }
    }
  }

  void _handleEditSession(dynamic session) {
    SessionActions.showEditTitleDialog(
      context: context,
      session: session,
      onSave: (newTitle) => _updateSessionTitle(session.id, newTitle),
    );
  }

  void _handleDeleteSession(String sessionId) {
    SessionActions.showDeleteConfirmDialog(
      context: context,
      onConfirm: () => _deleteSession(sessionId),
    );
  }

  void _handleShareSession(dynamic session) {
    SessionActions.shareSession(context, session);
  }

  // Private Methods
  void _updateSessionTitle(String sessionId, String newTitle) {
    try {
      context.read<ChatHistoryViewModel>().updateSessionTitle(sessionId, newTitle);
      SnackbarUtils.showSuccess(context, 'Titre modifié avec succès');
    } catch (e) {
      SnackbarUtils.showError(context, 'Erreur lors de la modification');
    }
  }

  void _deleteSession(String sessionId) {
    try {
      context.read<ChatHistoryViewModel>().deleteSession(sessionId);
      SnackbarUtils.showSuccess(context, 'Conversation supprimée');
    } catch (e) {
      SnackbarUtils.showError(context, 'Erreur lors de la suppression');
    }
  }
}

// Mixin for better code organization
mixin ChatHistoryMixin<T extends StatefulWidget> on State<T> {
  // You can add shared functionality here if needed
  bool get isUserAuthenticated {
    final authViewModel = context.read<AuthViewModel>();
    return authViewModel.currentUser != null;
  }

  void checkAuthenticationState() {
    if (!isUserAuthenticated) {
      // Handle unauthenticated state
      GoRouter.of(context).go('/welcome');
    }
  }
}