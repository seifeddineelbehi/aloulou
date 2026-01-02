// File: presentation/viewmodels/chat_viewmodel.dart
import 'dart:async';

import 'package:aloulou_chat/core/services/ai_service_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/media_service.dart';
import '../../core/services/gemini_service.dart'; // ✅ Import ajouté
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final MediaService _mediaService = MediaService.instance;
  final GeminiService _geminiService = GeminiService(); // ✅ Instance directe
  UserRepository? _userRepository;
  StreamSubscription? _audioPlayerSubscription;

  // Recording timer
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  ChatViewModel({
    required ChatRepository chatRepository,
    UserRepository? userRepository,
    required AIServiceManager aiServiceManager,
  }) : _chatRepository = chatRepository,
       _userRepository = userRepository;

  // State
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  String? _currentPlayingAudioId;
  String? _errorMessage;
  String? _currentUserId;
  Duration _recordingDuration = Duration.zero;

  // Getters
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isRecording => _isRecording;
  bool get isPlayingAudio => _isPlayingAudio;
  String? get currentPlayingAudioId => _currentPlayingAudioId;
  String? get errorMessage => _errorMessage;
  bool get hasSession => _currentSession != null;
  bool get hasMessages => _messages.isNotEmpty;
  Duration get recordingDuration => _recordingDuration;

  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _userRepository ??= UserRepository();
  }

  // Create new chat session
  Future<void> createNewSession() async {
    if (_currentUserId == null) return; 

    _setLoading(true);
    try {
      _currentSession = await _chatRepository.createChatSession(_currentUserId!);
      _messages.clear();
      
      // Add welcome message
      await _addWelcomeMessage();
      
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load existing session
  Future<void> loadSession(String sessionId) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      _currentSession = await _chatRepository.getChatSession(_currentUserId!, sessionId);
      
      if (_currentSession != null) {
        await _loadMessages();
      } else {
        _setError('Session not found');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load messages for current session
  Future<void> _loadMessages() async {
    if (_currentSession == null || _currentUserId == null) return;

    try {
      _messages = await _chatRepository.getSessionMessages(
        _currentUserId!,
        _currentSession!.id,
      );
      
      // Add welcome message if no messages exist
      if (_messages.isEmpty) {
        await _addWelcomeMessage();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Send text message
  Future<void> sendMessage(String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return;

    // Create session if none exists
    if (_currentSession == null) {
      await createNewSession();
      if (_currentSession == null) return;
    }

    _setSending(true);
    
    // Add user message immediately for UI responsiveness
    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      sessionId: _currentSession!.id,
      status: MessageStatus.sending,
      type: MessageType.text,
    );
    
   _messages.add(userMessage);
    _chatRepository.sendMessage(
      userId: userMessage.isUser ? _currentUserId! : 'AI',
      sessionId: userMessage.sessionId,
      text: userMessage.text,
      chatHistory: userMessage.isUser
          ? _messages.where((m) => m.id != userMessage.id).toList()
          : [],
    );
    notifyListeners();
    
    try {
      // ✅ Utiliser directement le GeminiService
      final aiResponseText = await _geminiService.sendMessage(
        message: text.trim(),
        sessionId: _currentSession!.id,
        chatHistory: _messages.where((m) => m.id != userMessage.id).toList(),
      );

      // Update user message status
      final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);
      final userIndex = _messages.indexWhere((m) => m.id == userMessage.id);
      if (userIndex != -1) {
        _messages[userIndex] = sentUserMessage;
      }

      // Add AI message
      final aiMessage = ChatMessage(
        text: aiResponseText,
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
      
      _messages.add(aiMessage);
    _chatRepository.sendMessage(
      userId: aiMessage.isUser ? _currentUserId! : 'AI',
      sessionId: aiMessage.sessionId,
      text: aiMessage.text,
      chatHistory: aiMessage.isUser
          ? _messages.where((m) => m.id != aiMessage.id).toList()
          : [],
    );
    notifyListeners();

      // Update user stats
      await _updateUserStats();

      _clearError();
    } catch (e) {
      // Update user message status to failed
      final failedUserMessage = userMessage.copyWith(status: MessageStatus.failed);
      final userIndex = _messages.indexWhere((m) => m.id == userMessage.id);
      if (userIndex != -1) {
        _messages[userIndex] = failedUserMessage;
      }
      
      // Add error message
      final errorMessage = ChatMessage(
        text: _getErrorMessage(e.toString()),
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
      _messages.add(errorMessage);
      
      _setError(e.toString());
    } finally {
      _setSending(false);
      notifyListeners();
    }
  }

  // === VOICE RECORDING FUNCTIONS ===

  // Start voice recording
  Future<void> startVoiceRecording() async {
    if (_currentUserId == null || _isRecording) return;

    try {
      _setRecording(true);
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;
      
      // Start the recording timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_recordingStartTime != null) {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          notifyListeners();
        }
      });
      
      final success = await _mediaService.startRecording();
      if (!success) {
        throw Exception('Failed to start recording');
      }

      print('🎤 Voice recording started');
    } catch (e) {
      _stopRecordingTimer();
      _setRecording(false);
      _setError('Erreur lors du démarrage de l\'enregistrement: $e');
    }
  }

  // Stop voice recording and send
  Future<void> stopVoiceRecording() async {
    if (!_isRecording) return;

    try {
      _stopRecordingTimer();
      final result = await _mediaService.stopRecording();
      _setRecording(false);

      if (result == null) {
        throw Exception('No recording result');
      }

      // Create session if none exists
      if (_currentSession == null) {
        await createNewSession();
        if (_currentSession == null) return;
      }

      _setSending(true);

      // Create voice message for UI
      final voiceMessage = ChatMessage.voice(
        sessionId: _currentSession!.id,
        isUser: true,
        filePath: result.filePath,
        audioDuration: result.duration,
        fileSize: result.fileSize,
        text: 'Message vocal', // Placeholder text
      );

      // Add voice message immediately for UI
      _messages.add(voiceMessage.copyWith(status: MessageStatus.sending));
      notifyListeners();

      // ✅ TRANSCRIPTION AVEC GEMINI
      final transcriptionResponse = await _geminiService.transcribeAudio(
        audioPath: result.filePath,
        message: 'Transcris ce message vocal en français et réponds au contenu si c\'est une question.',
        sessionId: _currentSession!.id,
      );

      // Update voice message status
      final sentVoiceMessage = voiceMessage.copyWith(status: MessageStatus.sent);
      final voiceIndex = _messages.indexWhere((m) => m.id == voiceMessage.id);
      if (voiceIndex != -1) {
        _messages[voiceIndex] = sentVoiceMessage;
      }

      // Add AI response
      final aiMessage = ChatMessage(
        text: transcriptionResponse,
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
      _messages.add(aiMessage);

      // Update user stats
      await _updateUserStats();
      _clearError();
      
      print('🎵 Voice message sent and transcribed: ${result.filePath}');
    } catch (e) {
      _stopRecordingTimer();
      _setRecording(false);
      _setError('Erreur lors de l\'envoi du message vocal: $e');
    } finally {
      _setSending(false);
      notifyListeners();
    }
  }

  // Cancel voice recording
  Future<void> cancelVoiceRecording() async {
    if (!_isRecording) return;

    try {
      _stopRecordingTimer();
      await _mediaService.cancelRecording();
      _setRecording(false);
      print('🚫 Voice recording canceled');
    } catch (e) {
      _stopRecordingTimer();
      _setRecording(false);
      print('Error canceling recording: $e');
    }
  }

  // Stop recording timer
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartTime = null;
    _recordingDuration = Duration.zero;
  }

  // === AUDIO PLAYBACK FUNCTIONS ===

  // Play audio message
  Future<void> playAudioMessage(String messageId) async {
    try {
      final message = _messages.firstWhere((m) => m.id == messageId);
      
      if (!message.isVoice || message.filePath == null) {
        throw Exception('Invalid audio message');
      }

      if (_isPlayingAudio) {
        await stopAudioMessage();
      }

      _setPlayingAudio(true, messageId);
      
      final success = await _mediaService.playAudio(message.filePath!);
      if (!success) {
        throw Exception('Failed to play audio');
      }

      // Cancel previous subscription if exists
      _audioPlayerSubscription?.cancel();
      
      // Listen for playback completion using position and duration streams
      if (_mediaService.audioPositionStream != null && _mediaService.audioDurationStream != null) {
        _audioPlayerSubscription = _mediaService.audioPositionStream!.listen((position) async {
          final duration = await _mediaService.audioDurationStream!.first;
          if (duration != null && position >= duration) {
            _setPlayingAudio(false, null);
          }
        });
      }

      print('🔊 Playing audio: ${message.filePath}');
    } catch (e) {
      _setPlayingAudio(false, null);
      print('Error playing audio: $e');
    }
  }

  // Stop audio playback
  Future<void> stopAudioMessage() async {
    try {
      await _mediaService.stopAudio();
      _setPlayingAudio(false, null);
      print('⏹️ Audio playback stopped');
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // Pause audio playback
  Future<void> pauseAudioMessage() async {
    try {
      await _mediaService.pauseAudio();
      print('⏸️ Audio playback paused');
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  // Resume audio playback
  Future<void> resumeAudioMessage() async {
    try {
      await _mediaService.resumeAudio();
      print('▶️ Audio playback resumed');
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  // === FILE FUNCTIONS ===

  // Send file (using the old method for general files)
  Future<void> sendFile() async {
    if (_currentUserId == null) return;

    try {
      _setSending(true);

      final result = await _mediaService.pickFile();
      if (result == null) {
        _setSending(false);
        return;
      }

      // Create session if none exists
      if (_currentSession == null) {
        await createNewSession();
        if (_currentSession == null) {
          _setSending(false);
          return;
        }
      }

      // Create file message
      final fileMessage = ChatMessage.file(
        sessionId: _currentSession!.id,
        isUser: true,
        filePath: result.filePath,
        fileName: result.fileName,
        fileSize: result.fileSize,
        mimeType: result.mimeType,
      );

      await _sendMediaMessage(fileMessage);
      
      print('📎 File sent: ${result.fileName}');
    } catch (e) {
      _setError('Erreur lors de l\'envoi du fichier: $e');
    } finally {
      _setSending(false);
    }
  }

  // Send image from camera
  Future<void> sendImageFromCamera() async {
    if (_currentUserId == null) return;

    try {
      _setSending(true);

      final result = await _mediaService.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (result == null) {
        _setSending(false);
        return;
      }

      await _sendImageWithAnalysis(result, 'Photo prise avec l\'appareil photo');
      
      print('📷 Image from camera sent: ${result.fileName}');
    } catch (e) {
      _setError('Erreur lors de la prise de photo: $e');
    } finally {
      _setSending(false);
    }
  }

  // Send image from gallery
  Future<void> sendImageFromGallery() async {
    if (_currentUserId == null) return;

    try {
      _setSending(true);

      final result = await _mediaService.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (result == null) {
        _setSending(false);
        return;
      }

      await _sendImageWithAnalysis(result, 'Image sélectionnée depuis la galerie');
      
      print('🖼️ Image from gallery sent: ${result.fileName}');
    } catch (e) {
      _setError('Erreur lors de l\'envoi de l\'image: $e');
    } finally {
      _setSending(false);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Envoyer une image avec analyse Gemini
  Future<void> _sendImageWithAnalysis(FilePickResult imageResult, String userText) async {
    // Create session if none exists
    if (_currentSession == null) {
      await createNewSession();
      if (_currentSession == null) return;
    }

    // Create image message for UI
    final imageMessage = ChatMessage.file(
      sessionId: _currentSession!.id,
      isUser: true,
      filePath: imageResult.filePath,
      fileName: imageResult.fileName,
      fileSize: imageResult.fileSize,
      mimeType: imageResult.mimeType,
      text: userText,
    );

    // Add image message immediately for UI
    _messages.add(imageMessage.copyWith(status: MessageStatus.sending));
    notifyListeners();

    try {
      // ✅ ANALYSE AVEC GEMINI
      final analysisResponse = await _geminiService.analyzeImage(
        imagePath: imageResult.filePath,
        message: 'Décris cette image en détail en français. Que vois-tu ?',
        sessionId: _currentSession!.id,
      );

      // Update image message status
      final sentImageMessage = imageMessage.copyWith(status: MessageStatus.sent);
      final imageIndex = _messages.indexWhere((m) => m.id == imageMessage.id);
      if (imageIndex != -1) {
        _messages[imageIndex] = sentImageMessage;
      }

      // Add AI response
      final aiMessage = ChatMessage(
        text: analysisResponse,
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
      _messages.add(aiMessage);

      // Update user stats
      await _updateUserStats();
      _clearError();
      
    } catch (e) {
      // Update message status to failed
      final failedMessage = imageMessage.copyWith(status: MessageStatus.failed);
      final messageIndex = _messages.indexWhere((m) => m.id == imageMessage.id);
      if (messageIndex != -1) {
        _messages[messageIndex] = failedMessage;
      }
      
      _setError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // === PRIVATE HELPER METHODS ===

  // Send media message (voice, file, image) - Version simplifiée pour les fichiers génériques
  Future<void> _sendMediaMessage(ChatMessage mediaMessage) async {
    // Add user message immediately for UI responsiveness
    _messages.add(mediaMessage.copyWith(status: MessageStatus.sending));
    notifyListeners();

    try {
      // Save the media message to repository
      final userIndex = _messages.indexWhere((m) => m.id == mediaMessage.id);
      if (userIndex != -1) {
        _messages[userIndex] = mediaMessage.copyWith(status: MessageStatus.sent);
      }

      // Generate AI response for media (générique pour les fichiers non-image/audio)
      final aiResponse = await _generateGenericAIResponse(mediaMessage);
      if (aiResponse != null) {
        _messages.add(aiResponse);
      }

      // Update user stats
      await _updateUserStats();

      _clearError();
    } catch (e) {
      // Update message status to failed
      final failedMessage = mediaMessage.copyWith(status: MessageStatus.failed);
      final messageIndex = _messages.indexWhere((m) => m.id == mediaMessage.id);
      if (messageIndex != -1) {
        _messages[messageIndex] = failedMessage;
      }
      
      _setError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // Generate AI response for non-multimodal media messages
  Future<ChatMessage?> _generateGenericAIResponse(ChatMessage mediaMessage) async {
    try {
      String prompt = '';
      
      switch (mediaMessage.type) {
        case MessageType.file:
        case MessageType.document:
          prompt = 'L\'utilisateur a partagé un fichier: ${mediaMessage.fileName} (${mediaMessage.fileSizeDisplay}). Comment puis-je vous aider avec ce fichier ?';
          break;
        default:
          return null;
      }

      // ✅ Utiliser GeminiService directement
      final responseText = await _geminiService.sendMessage(
        message: prompt,
        sessionId: _currentSession!.id,
        chatHistory: _messages,
      );

      return ChatMessage(
        text: responseText,
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
    } catch (e) {
      print('Error generating AI response for media: $e');
      return ChatMessage(
        text: 'J\'ai reçu votre ${mediaMessage.type.name}. Comment puis-je vous aider ?',
        isUser: false,
        sessionId: _currentSession!.id,
        status: MessageStatus.sent,
        type: MessageType.text,
      );
    }
  }

  // Show media options
  Future<void> showMediaOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Envoyer un média',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // Options
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Gemini analysera l\'image'),
              onTap: () {
                Navigator.pop(context);
                sendImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie photo'),
              subtitle: const Text('Gemini analysera l\'image'),
              onTap: () {
                Navigator.pop(context);
                sendImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Fichier'),
              subtitle: const Text('Documents, PDF, etc.'),
              onTap: () {
                Navigator.pop(context);
                sendFile();
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Retry failed message
  Future<void> retryMessage(String messageId) async {
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = _messages[messageIndex];
    if (message.isUser && message.status == MessageStatus.failed) {
      // Remove the failed message
      _messages.removeAt(messageIndex);
      notifyListeners();
      
      // Resend based on message type
      if (message.type == MessageType.text) {
        await sendMessage(message.text);
      } else if (message.type == MessageType.image && message.filePath != null) {
        // ✅ Retry image with analysis
        final imageResult = FilePickResult(
          fileName: message.fileName ?? 'retry_image.jpg',
          filePath: message.filePath!,
          fileSize: message.fileSize ?? 0,
          mimeType: message.mimeType ?? 'image/jpeg',
        );
        await _sendImageWithAnalysis(imageResult, message.text);
      } else {
        await _sendMediaMessage(message);
      }
    }
  }

  // Clear current session messages
  Future<void> clearMessages() async {
    if (_currentSession == null || _currentUserId == null) return;

    _setLoading(true);
    try {
      await _chatRepository.clearSessionMessages(_currentUserId!, _currentSession!.id);
      _messages.clear();
      await _addWelcomeMessage();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      _messages.removeAt(messageIndex);
      notifyListeners();
    }
  }

  // Add welcome message
  Future<void> _addWelcomeMessage() async {
    final welcomeMessage = ChatMessage(
      text: AppStrings.welcomeMessage,
      isUser: false,
      sessionId: _currentSession!.id,
      status: MessageStatus.sent,
      type: MessageType.text,
    );
    
    _messages.add(welcomeMessage);
    notifyListeners();
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (_currentUserId == null || _userRepository == null) return;

    try {
      await _userRepository!.incrementMessageCount(_currentUserId!);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Get messages stream for real-time updates
  Stream<List<ChatMessage>> getMessagesStream() {
    if (_currentSession == null || _currentUserId == null) {
      return Stream.value([]);
    }

    return _chatRepository.getSessionMessagesStream(_currentUserId!, _currentSession!.id);
  }

  // Search messages
  Future<List<ChatMessage>> searchMessages(String query) async {
    if (_currentUserId == null) return [];

    try {
      return await _chatRepository.searchMessages(_currentUserId!, query);
    } catch (e) {
      return [];
    }
  }

  // Generate session summary
  Future<String?> generateSessionSummary() async {
    if (_currentSession == null || _currentUserId == null) return null;

    try {
      return await _chatRepository.generateChatSummary(_currentUserId!, _currentSession!.id);
    } catch (e) {
      return null;
    }
  }

  // Get message by ID
  ChatMessage? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  // Get user messages count
  int get userMessagesCount => _messages.where((m) => m.isUser).length;

  // Get AI messages count
  int get aiMessagesCount => _messages.where((m) => !m.isUser).length;

  // Get last message
  ChatMessage? get lastMessage => _messages.isNotEmpty ? _messages.last : null;

  // Check if last message is from user and failed
  bool get hasFailedMessage => _messages.any((m) => 
      m.isUser && m.status == MessageStatus.failed);

  // Refresh messages
  Future<void> refreshMessages() async {
    if (_currentSession != null) {
      await _loadMessages();
    }
  }

  // Clear current session
  void clearCurrentSession() {
    _currentSession = null;
    _messages.clear();
    _clearError();
    notifyListeners();
  }

  // === STATE MANAGEMENT METHODS ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  void _setRecording(bool recording) {
    _isRecording = recording;
    if (!recording) {
      _stopRecordingTimer();
    }
    notifyListeners();
  }

  void _setPlayingAudio(bool playing, String? messageId) {
    _isPlayingAudio = playing;
    _currentPlayingAudioId = messageId;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return AppStrings.networkErrorMessage;
    } else if (error.contains('quota') || error.contains('limit')) {
      return 'Limite quotidienne atteinte. Veuillez réessayer demain.';
    } else if (error.contains('blocked') || error.contains('safety')) {
      return 'Message bloqué pour des raisons de sécurité. Veuillez reformuler.';
    } else if (error.contains('permission')) {
      return 'Permission requise. Veuillez autoriser l\'accès dans les paramètres.';
    }
    return AppStrings.errorMessage;
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // === UTILITY METHODS ===

  // Check if can send message
  bool get canSendMessage => !_isSending && !_isRecording;

  // Get typing indicator
  bool get showTypingIndicator => _isSending;

  // Get media attachment info
  Map<String, dynamic> getMediaInfo() {
    final mediaMessages = _messages.where((m) => m.hasMedia).toList();
    return {
      'totalMedia': mediaMessages.length,
      'voiceMessages': mediaMessages.where((m) => m.isVoice).length,
      'images': mediaMessages.where((m) => m.isImage).length,
      'files': mediaMessages.where((m) => m.isFile).length,
    };
  }

  // Dispose
  @override
  void dispose() {
    _audioPlayerSubscription?.cancel();
    _stopRecordingTimer();
    if (_isRecording) {
      _mediaService.cancelRecording();
    }
    if (_isPlayingAudio) {
      _mediaService.stopAudio();
    }
    super.dispose();
  }
}