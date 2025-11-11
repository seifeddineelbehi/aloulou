// File: data/repositories/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/ai_service_interface.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ai_service_manager.dart'; // ✅ CHANGÉ: Import du nouveau service manager
import '../../core/services/storage_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatRepository {
  final AIServiceManager _aiServiceManager; // ✅ CHANGÉ: Utilisation du service manager

  // ✅ NOUVEAU: Constructeur pour injecter le service manager
  ChatRepository({AIServiceManager? aiServiceManager}) 
      : _aiServiceManager = aiServiceManager ?? AIServiceManager();

  // ✅ NOUVEAU: Méthodes pour gérer le fournisseur IA
  AIProvider get currentProvider => _aiServiceManager.currentProvider;
  String get currentProviderName => _aiServiceManager.currentProviderName;
  
  void switchAIProvider(AIProvider provider) {
    _aiServiceManager.switchProvider(provider);
  }

  Future<Map<AIProvider, bool>> getAvailableProviders() {
    return _aiServiceManager.getAvailableProviders();
  }

  Future<void> autoSelectProvider() {
    return _aiServiceManager.autoSelectProvider();
  }

  // Create new chat session
  Future<ChatSession> createChatSession(String userId, {String? title}) async {
    final session = ChatSession(
      userId: userId,
      title: title,
    );

    try {
      // Save to Firebase using toFirestoreJson()
      await FirebaseService.userChatSessions(userId)
          .doc(session.id)
          .set(session.toFirestoreJson());

      // Save to local storage using toJson()
      await StorageService.saveChatSession(session);

      return session;
    } catch (e) {
      // If Firebase fails, still save locally
      await StorageService.saveChatSession(session);
      throw Exception('Failed to create chat session: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Get chat sessions for user
  Future<List<ChatSession>> getChatSessions(String userId) async {
    try {
      // Try to get from Firebase first
      final snapshot = await FirebaseService.getUserChatSessionsQuery(userId)
          .limit(50)
          .get();

      final sessions = snapshot.docs
          .map((doc) => ChatSession.fromFirestore(doc))
          .toList();

      // Update local storage
      await StorageService.saveChatSessions(sessions);

      return sessions;
    } catch (e) {
      // Fallback to local storage
      return StorageService.getChatSessions();
    }
  }

  // Get chat sessions stream
  Stream<List<ChatSession>> getChatSessionsStream(String userId) {
    return FirebaseService.getUserChatSessionsQuery(userId)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromFirestore(doc))
            .toList());
  }

  // Get specific chat session
  Future<ChatSession?> getChatSession(String userId, String sessionId) async {
    try {
      // Try Firebase first
      final doc = await FirebaseService.userChatSessions(userId)
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final session = ChatSession.fromFirestore(doc);
        // Update local storage
        await StorageService.saveChatSession(session);
        return session;
      }
    } catch (e) {
      // Fallback to local storage
      return StorageService.getChatSession(sessionId);
    }

    return null;
  }

  // Update chat session
  Future<void> updateChatSession(ChatSession session) async {
    try {
      // Update in Firebase using toFirestoreJson()
      await FirebaseService.userChatSessions(session.userId)
          .doc(session.id)
          .update(session.toFirestoreJson());

      // Update local storage using toJson()
      await StorageService.saveChatSession(session);
    } catch (e) {
      // If Firebase fails, still update locally
      await StorageService.saveChatSession(session);
      throw Exception('Failed to update chat session: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(String userId, String sessionId) async {
    try {
      // Delete from Firebase
      await FirebaseService.userChatSessions(userId)
          .doc(sessionId)
          .delete();

      // Delete messages from Firebase
      final messagesSnapshot = await FirebaseService.sessionMessages(userId, sessionId).get();
      final batch = FirebaseService.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete from local storage
      await StorageService.deleteChatSession(sessionId);
    } catch (e) {
      // If Firebase fails, delete locally
      await StorageService.deleteChatSession(sessionId);
      throw Exception('Failed to delete chat session: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // ✅ MODIFIÉ: Send message and get AI response - maintenant utilise AIServiceManager
  Future<ChatMessage> sendMessage({
    required String userId,
    required String sessionId,
    required String text,
    List<ChatMessage>? chatHistory,
  }) async {
    // Create user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      sessionId: sessionId,
      status: MessageStatus.sending,
    );

    try {
      // Save user message
      await _saveMessage(userId, userMessage);
      
      // Mark as sent
      final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);
      await _updateMessage(userId, sentUserMessage);

      // ✅ CHANGÉ: Get AI response using AIServiceManager
      final aiResponse = await _aiServiceManager.sendMessage(
        message: text,
        sessionId: sessionId,
        chatHistory: chatHistory,
      );

      // Create AI message
      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        sessionId: sessionId,
        status: MessageStatus.sent,
      );

      // Save AI message
      await _saveMessage(userId, aiMessage);

      // Update session title if it's the first user message
      if (chatHistory?.isEmpty == true || chatHistory == null) {
        // ✅ CHANGÉ: Generate title using AIServiceManager
        final newTitle = await _aiServiceManager.generateChatTitle(text);
        final session = await getChatSession(userId, sessionId);
        if (session != null) {
          await updateChatSession(session.copyWith(title: newTitle));
        }
      }

      return aiMessage;
    } catch (e) {
      // Mark user message as failed
      final failedMessage = userMessage.copyWith(status: MessageStatus.failed);
      await _updateMessage(userId, failedMessage);
      
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for session
  Future<List<ChatMessage>> getSessionMessages(String userId, String sessionId) async {
    try {
      // Try Firebase first
      final snapshot = await FirebaseService.getSessionMessagesQuery(userId, sessionId)
          .get();

      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();

      // Update local storage
      await StorageService.saveChatMessages(messages);

      return messages;
    } catch (e) {
      // Fallback to local storage
      return StorageService.getSessionMessages(sessionId);
    }
  }

  // Get messages stream for session
  Stream<List<ChatMessage>> getSessionMessagesStream(String userId, String sessionId) {
    return FirebaseService.getSessionMessagesQuery(userId, sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Clear session messages
  Future<void> clearSessionMessages(String userId, String sessionId) async {
    try {
      // Clear from Firebase
      final snapshot = await FirebaseService.sessionMessages(userId, sessionId).get();
      final batch = FirebaseService.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear from local storage
      await StorageService.deleteSessionMessages(sessionId);

      // ✅ CHANGÉ: Clear AI session using AIServiceManager
      _aiServiceManager.clearChatSession(sessionId);
    } catch (e) {
      // If Firebase fails, clear locally
      await StorageService.deleteSessionMessages(sessionId);
      _aiServiceManager.clearChatSession(sessionId);
      throw Exception('Failed to clear messages: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // ✅ MODIFIÉ: Generate chat summary using AIServiceManager
  Future<String?> generateChatSummary(String userId, String sessionId) async {
    try {
      final messages = await getSessionMessages(userId, sessionId);
      return await _aiServiceManager.generateChatSummary(messages);
    } catch (e) {
      return null;
    }
  }

  // Search messages
  Future<List<ChatMessage>> searchMessages(String userId, String query) async {
    try {
      // This is a simple text search - for better search, consider using Algolia or similar
      final sessions = await getChatSessions(userId);
      final List<ChatMessage> allMessages = [];

      for (final session in sessions) {
        final messages = await getSessionMessages(userId, session.id);
        allMessages.addAll(messages);
      }

      return allMessages
          .where((message) => 
              message.text.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  // ✅ NOUVEAU: Test current AI provider connection
  Future<bool> testAIConnection() async {
    return await _aiServiceManager.testApiConnection();
  }

  // ✅ NOUVEAU: Get AI provider status
  Future<Map<String, dynamic>> getAIProviderStatus() async {
    return await _aiServiceManager.getProviderStatus();
  }

  // ✅ NOUVEAU: Force switch to specific provider with validation
  Future<bool> switchToProvider(AIProvider provider) async {
    try {
      final available = await getAvailableProviders();
      if (available[provider] == true) {
        switchAIProvider(provider);
        return true;
      }
      return false;
    } catch (e) {
      print('Error switching provider: $e');
      return false;
    }
  }

  // ✅ NOUVEAU: Get AI service information for debugging
  Map<String, dynamic> getAIServiceInfo() {
    return {
      'currentProvider': currentProvider.name,
      'providerName': currentProviderName,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods
Future<void> _saveMessage(String userId, ChatMessage message) async {
  try {
    await FirebaseService.sessionMessages(userId, message.sessionId)
        .doc(message.id)
        .set(message.toFirestoreJson());
    await StorageService.saveChatMessage(message);
  } catch (e) {
    // Try to save locally if Firebase fails
    await StorageService.saveChatMessage(message);
    throw Exception('Failed to save message: ${FirebaseService.getErrorMessage(e)}');
  }
}

Future<void> _updateMessage(String userId, ChatMessage message) async {
  try {
    await FirebaseService.sessionMessages(userId, message.sessionId)
        .doc(message.id)
        .update(message.toFirestoreJson());
    await StorageService.saveChatMessage(message);
  } catch (e) {
    // Try to update locally if Firebase fails
    await StorageService.saveChatMessage(message);
    throw Exception('Failed to update message: ${FirebaseService.getErrorMessage(e)}');
  }
}
  // Sync local data with Firebase
  Future<void> syncWithFirebase(String userId) async {
    try {
      // Sync sessions
      final remoteSessions = await getChatSessions(userId);
      await StorageService.saveChatSessions(remoteSessions);

      // Sync messages for each session
      for (final session in remoteSessions) {
        final messages = await getSessionMessages(userId, session.id);
        await StorageService.saveChatMessages(messages);
      }
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  // Get statistics
  Future<Map<String, int>> getChatStatistics(String userId) async {
    try {
      final sessions = await getChatSessions(userId);
      int totalMessages = 0;
      int userMessages = 0;
      int aiMessages = 0;

      for (final session in sessions) {
        final messages = await getSessionMessages(userId, session.id);
        totalMessages += messages.length;
        userMessages += messages.where((m) => m.isUser).length;
        aiMessages += messages.where((m) => !m.isUser).length;
      }

      return {
        'totalSessions': sessions.length,
        'totalMessages': totalMessages,
        'userMessages': userMessages,
        'aiMessages': aiMessages,
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'totalMessages': 0,
        'userMessages': 0,
        'aiMessages': 0,
      };
    }
  }

  // ✅ NOUVEAU: Dispose resources
  void dispose() {
    _aiServiceManager.dispose();
  }
}