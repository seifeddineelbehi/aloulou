// File: presentation/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_service_interface.dart';
import '../../../core/services/ai_service_manager.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/chat/messages/message_bubble.dart';
import '../../../widgets/chat/typing_indicator.dart';
import '../../../widgets/chat/messages/message_input.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/chat/loading_overlay.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? sessionId;
  
  const ChatScreen({
    super.key,
    this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  bool _isComposing = false;
  bool _showFab = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeChat();
    _setupScrollListener();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;
    
    if (_isKeyboardVisible != isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });
      
      if (isKeyboardVisible) {
        _scrollToBottomDelayed();
      }
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isAtBottom = _scrollController.offset >= 
          _scrollController.position.maxScrollExtent - 100;
      
      if (_showFab == isAtBottom) {
        setState(() {
          _showFab = !isAtBottom;
        });
        
        if (_showFab) {
          _fabController.forward();
        } else {
          _fabController.reverse();
        }
      }
    });
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final chatViewModel = context.read<ChatViewModel>();
      
      if (authViewModel.currentUser != null) {
        chatViewModel.initialize(authViewModel.currentUser!.uid);
        
        if (widget.sessionId != null) {
          chatViewModel.loadSession(widget.sessionId!);
        } else {
          chatViewModel.createNewSession();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      } else {
_scrollController.jumpTo(_scrollController.position.maxScrollExtent);      }
    }
  }

  void _scrollToBottomDelayed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    });
  }

  void _onMessageChanged(String text) {
    final isComposing = text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatViewModel = context.read<ChatViewModel>();
    
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
    
    await chatViewModel.sendMessage(text);
    _scrollToBottomDelayed();
    
    HapticFeedback.selectionClick();
  }

  // === MEDIA HANDLING METHODS ===
  
  Future<void> _startVoiceRecording() async {
    final chatViewModel = context.read<ChatViewModel>();
    await chatViewModel.startVoiceRecording();
  }

  Future<void> _stopVoiceRecording() async {
    final chatViewModel = context.read<ChatViewModel>();
    await chatViewModel.stopVoiceRecording();
    _scrollToBottomDelayed();
  }

  Future<void> _cancelVoiceRecording() async {
    final chatViewModel = context.read<ChatViewModel>();
    await chatViewModel.cancelVoiceRecording();
  }

  void _showMediaOptions() {
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.showMediaOptions(context);
  }

  // === AUDIO PLAYBACK METHODS ===
  
  void _playAudio(String messageId) {
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.playAudioMessage(messageId);
  }

  void _stopAudio(String messageId) {
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.stopAudioMessage();
  }

  void _pauseAudio(String messageId) {
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.pauseAudioMessage();
  }

  void _resumeAudio(String messageId) {
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.resumeAudioMessage();
  }

  void _openFile(String filePath) {
    // TODO: Implement file opening functionality
    // You can use url_launcher package to open files
    print('Opening file: $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture du fichier: ${filePath.split('/').last}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openImage(String filePath) {
    // TODO: Implement image viewing functionality
    // You can navigate to a full-screen image viewer
    print('Opening image: $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de l\'image: ${filePath.split('/').last}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Nouvelle conversation'),
          ],
        ),
        content: const Text(
          'Voulez-vous créer une nouvelle conversation ? '
          'La conversation actuelle sera sauvegardée.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatViewModel>().createNewSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildScrollToBottomFab(),
    );
  }

  Widget? _buildScrollToBottomFab() {
    if (!_showFab) return null;
    
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.small(
        onPressed: () => _scrollToBottom(),
        backgroundColor: AppColors.primary.withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.keyboard_arrow_down, size: 20),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      centerTitle: false,
      systemOverlayStyle: isDarkMode 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
      title: Consumer2<ChatViewModel, AIServiceManager>(
        builder: (context, chatViewModel, aiManager, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatViewModel.currentSession?.title ?? 'Chat avec Aloulou',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      aiManager.currentProviderName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (chatViewModel.isSending) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'En train d\'écrire...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (chatViewModel.isRecording) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Enregistrement...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.psychology,
          tooltip: 'Changer de modèle',
          onPressed: () => _showModelSelector(context),
        ),
        _buildAppBarAction(
          icon: Icons.add_circle_outline,
          tooltip: 'Nouvelle conversation',
          onPressed: _showNewChatDialog,
        ),
        _buildAppBarAction(
          icon: Icons.history,
          tooltip: 'Historique',
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ChatHistoryScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        _buildMoreMenu(),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(-8, 48),
      onSelected: (value) {
        switch (value) {
          case 'clear':
            _showClearChatDialog();
            break;
          case 'export':
            _exportChat();
            break;
          case 'settings':
            _showSettings();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'clear',
          icon: Icons.clear_all,
          text: 'Effacer la conversation',
        ),
        _buildPopupMenuItem(
          value: 'export',
          icon: Icons.download,
          text: 'Exporter la conversation',
        ),
        _buildPopupMenuItem(
          value: 'settings',
          icon: Icons.settings,
          text: 'Paramètres',
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    final aiManager = context.read<AIServiceManager>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Sélectionnez votre modèle IA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chaque modèle a ses propres forces et spécialités',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildModelTile(
                      context,
                      icon: Icons.g_mobiledata,
                      title: 'Gemini Pro',
                      subtitle: 'Modèle avancé de Google • Multimodal',
                      badge: 'Recommandé',
                      isSelected: aiManager.currentProvider == AIProvider.gemini,
                      onTap: () {
                        aiManager.switchProvider(AIProvider.gemini);
                        Navigator.pop(context);
                        _showProviderSwitchedSnackBar('Gemini Pro');
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildModelTile(
                      context,
                      icon: Icons.explore,
                      title: 'DeepSeek',
                      subtitle: 'Modèle open-source performant • Rapide',
                      isSelected: aiManager.currentProvider == AIProvider.deepSeek,
                      onTap: () {
                        aiManager.switchProvider(AIProvider.deepSeek);
                        Navigator.pop(context);
                        _showProviderSwitchedSnackBar('DeepSeek');
                      },
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProviderSwitchedSnackBar(String providerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Modèle changé vers $providerName'),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildModelTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? AppColors.primary.withOpacity(0.05) 
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1) 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey[600],
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: AppColors.primary)
            : Icon(Icons.circle_outlined, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatViewModel>(
      builder: (context, chatViewModel, child) {
        if (chatViewModel.isLoading && !chatViewModel.hasMessages) {
          return _buildLoadingState();
        }

        if (chatViewModel.errorMessage != null && !chatViewModel.hasMessages) {
          return CustomErrorWidget(
            message: chatViewModel.errorMessage!,
            onRetry: () => chatViewModel.refreshMessages(),
          );
        }

        if (!chatViewModel.hasMessages) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16, 
                16, 
                16, 
                _isKeyboardVisible ? 16 : 32
              ),
              itemCount: chatViewModel.messages.length + (chatViewModel.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatViewModel.messages.length && chatViewModel.isSending) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: TypingIndicator(),
                  );
                }
                
                final message = chatViewModel.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MessageBubble(
                    message: message,
                    onRetry: () => chatViewModel.retryMessage(message.id),
                    onDelete: () => _showDeleteMessageDialog(message.id),
                    onPlayAudio: _playAudio,
                    onStopAudio: _stopAudio,
                    onPauseAudio: _pauseAudio,
                    onResumeAudio: _resumeAudio,
                    isPlaying: chatViewModel.currentPlayingAudioId == message.id,
                    onOpenFile: _openFile,
                    onOpenImage: _openImage,
                  ),
                );
              },
            ),
            if (chatViewModel.isLoading)
              const LoadingOverlay(message: 'Chargement...'),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de la conversation...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez une conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posez une question, demandez de l\'aide ou dites simplement bonjour !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSuggestionChip('👋 Bonjour !'),
                _buildSuggestionChip('💡 Aidez-moi avec...'),
                _buildSuggestionChip('📚 Expliquez-moi...'),
                _buildSuggestionChip('🎯 Conseils pour...'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _messageController.text = text.replaceAll(RegExp(r'[^\w\s\-\.!?]'), '').trim();
          _onMessageChanged(_messageController.text);
          _messageFocusNode.requestFocus();
        },
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        elevation: 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<ChatViewModel>(
          builder: (context, chatViewModel, child) {
           return MessageInput(
  controller: _messageController,
  focusNode: _messageFocusNode,
  onChanged: _onMessageChanged,
  onSend: _sendMessage,
  onShowMediaOptions: _showMediaOptions,
  onVoiceNoteStart: _startVoiceRecording,
  onVoiceNoteStop: _stopVoiceRecording,
  onVoiceNoteCancel: _cancelVoiceRecording,
  isComposing: _isComposing,
  isSending: chatViewModel.isSending,
  isRecordingVoice: chatViewModel.isRecording,
  recordingDuration: chatViewModel.recordingDuration,
  canSendMessage: chatViewModel.canSendMessage,
  enableAttachment: true,
  enableVoiceNote: true,
);
          },
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Effacer la conversation'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment effacer tous les messages de cette conversation ? '
          'Cette action est irréversible.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatViewModel>().clearMessages();
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous supprimer ce message ?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatViewModel>().deleteMessage(messageId);
             HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Paramètres du chat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSettingsSection(
                      title: 'Préférences d\'affichage',
                      children: [
                        _buildSettingsTile(
                          icon: Icons.dark_mode,
                          title: 'Mode sombre',
                          subtitle: 'Activer le thème sombre',
                          trailing: Switch(
                            value: Theme.of(context).brightness == Brightness.dark,
                            onChanged: (value) {
                              // Implement theme switching
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        _buildSettingsTile(
                          icon: Icons.text_fields,
                          title: 'Taille du texte',
                          subtitle: 'Ajuster la taille des messages',
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Implement text size settings
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSettingsSection(
                      title: 'Comportement',
                      children: [
                        _buildSettingsTile(
                          icon: Icons.vibration,
                          title: 'Vibrations',
                          subtitle: 'Retour haptique lors des interactions',
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {
                              // Implement haptic settings
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        _buildSettingsTile(
                          icon: Icons.auto_awesome,
                          title: 'Suggestions automatiques',
                          subtitle: 'Afficher des suggestions de messages',
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {
                              // Implement auto suggestions settings
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSettingsSection(
                      title: 'Données',
                      children: [
                        _buildSettingsTile(
                          icon: Icons.cloud_download,
                          title: 'Sauvegarde automatique',
                          subtitle: 'Sauvegarder les conversations',
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Implement backup settings
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Effacer toutes les données',
                          subtitle: 'Supprimer toutes les conversations',
                          textColor: Colors.red[600],
                          onTap: () {
                            Navigator.pop(context);
                            _showClearAllDataDialog();
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Effacer toutes les données'),
          ],
        ),
        content: const Text(
          'Cette action supprimera définitivement toutes vos conversations '
          'et données. Cette action est irréversible.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear all data functionality
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
  }

  void _exportChat() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        title: const Text('Exporter la conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez le format d\'export :'),
            const SizedBox(height: 16),
            
            _buildExportOption(
              icon: Icons.text_snippet,
              title: 'Texte (.txt)',
              subtitle: 'Format texte simple',
              onTap: () {
                Navigator.pop(context);
                _performExport('txt');
              },
            ),
            
            const SizedBox(height: 8),
            
            _buildExportOption(
              icon: Icons.description,
              title: 'PDF',
              subtitle: 'Document formaté',
              onTap: () {
                Navigator.pop(context);
                _performExport('pdf');
              },
            ),
            
            const SizedBox(height: 8),
            
            _buildExportOption(
              icon: Icons.share,
              title: 'Partager',
              subtitle: 'Partager via une autre app',
              onTap: () {
                Navigator.pop(context);
                _performExport('share');
              },
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _performExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Export en format $format en cours...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Open export location
          },
        ),
      ),
    );
  }
}