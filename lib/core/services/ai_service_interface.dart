import '../../data/models/chat_message.dart';

enum AIProvider {
  gemini,
  deepSeek,
  openAI, // Nouveau provider
}

enum SubscriptionTier {
  free,
  basic,
  premium,
}

abstract class AIService {
  bool get isApiKeyConfigured;
  bool get requiresSubscription;
  SubscriptionTier get requiredTier;

  Future<String> sendMessage({
    required String message,
    required String sessionId,
    List<ChatMessage>? chatHistory,
  });

  Future<String> generateChatTitle(String firstMessage);
  Future<String?> generateChatSummary(List<ChatMessage> messages);
  void clearChatSession(String sessionId);
  void clearAllSessions();
  Future<bool> testApiConnection();
  
  // Nouvelles méthodes pour la gestion des quotas
  Future<Map<String, dynamic>> getUsageInfo();
  Future<bool> hasQuotaRemaining();
}