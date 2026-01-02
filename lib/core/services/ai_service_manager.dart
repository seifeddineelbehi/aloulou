import 'package:flutter/foundation.dart';
import 'ai_service_interface.dart';
import 'gemini_service.dart';
import 'deepseek_service.dart';
import '../../data/models/chat_message.dart';

class AIServiceManager extends ChangeNotifier implements AIService {
  AIProvider _currentProvider = AIProvider.gemini;
  late final GeminiService _geminiService;
  late final DeepSeekService _deepSeekService;

  AIServiceManager() {
    _geminiService = GeminiService();
    _deepSeekService = DeepSeekService();
  }

  @override
  bool get isApiKeyConfigured => _currentService.isApiKeyConfigured;

  @override
  bool get requiresSubscription => _currentService.requiresSubscription;

  @override
  SubscriptionTier get requiredTier => _currentService.requiredTier;

  AIProvider get currentProvider => _currentProvider;
  
  String get currentProviderName {
    switch (_currentProvider) {
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.deepSeek:
        return 'DeepSeek';
      case AIProvider.openAI:
        return 'OpenAI'; // Pour l'avenir
    }
  }

  AIService get _currentService {
    switch (_currentProvider) {
      case AIProvider.gemini:
        return _geminiService;
      case AIProvider.deepSeek:
        return _deepSeekService;
      case AIProvider.openAI:
        // Pour l'instant, retourner Gemini par défaut
        return _geminiService;
    }
  }

  void switchProvider(AIProvider provider) {
    if (_currentProvider != provider) {
      _currentProvider = provider;
      notifyListeners();
      print('🔄 Switched to $currentProviderName provider');
    } 
  }

  Future<Map<AIProvider, bool>> getAvailableProviders() async {
    final results = <AIProvider, bool>{};
    
    // Test Gemini
    if (_geminiService.isApiKeyConfigured) {
      results[AIProvider.gemini] = await _geminiService.testApiConnection();
    } else {
      results[AIProvider.gemini] = false;
    }
    
    // Test DeepSeek
    if (_deepSeekService.isApiKeyConfigured) {
      results[AIProvider.deepSeek] = await _deepSeekService.testApiConnection();
    } else {
      results[AIProvider.deepSeek] = false;
    }
    
    return results;
  }

  Future<void> autoSelectProvider() async {
    final available = await getAvailableProviders();
    
    // Préférence : DeepSeek (gratuit) puis Gemini
    if (available[AIProvider.deepSeek] == true) {
      switchProvider(AIProvider.deepSeek);
    } else if (available[AIProvider.gemini] == true) {
      switchProvider(AIProvider.gemini);
    } else {
      print('⚠️ No AI providers available');
    }
  }
  
  @override
  Future<String> sendMessage({
    required String message,
    required String sessionId,
    List<ChatMessage>? chatHistory,
  }) async {
    try {
      return await _currentService.sendMessage(
        message: message,
        sessionId: sessionId,
        chatHistory: chatHistory,
      );
    } catch (e) {
      print('❌$currentProviderName failed, trying fallback...');
      return await _tryFallback(message, sessionId, chatHistory);
    }
  }

  Future<String> _tryFallback(
    String message,
    String sessionId,
    List<ChatMessage>? chatHistory,
  ) async {
    final available = await getAvailableProviders();
    
    for (final provider in AIProvider.values) {
      if (provider != _currentProvider && available[provider] == true) {
        try {
          final service = provider == AIProvider.gemini 
              ? _geminiService 
              : _deepSeekService;
          
          final response = await service.sendMessage(
            message: message,
            sessionId: sessionId,
            chatHistory: chatHistory,
          );
          
          print('✅ Fallback to ${provider.name} successful');
          return response;
        } catch (e) {
          print('❌ Fallback ${provider.name} also failed: $e');
          continue;
        }
      }
    }
    
    return 'Désolé, tous les services IA sont temporairement indisponibles. Veuillez réessayer plus tard.';
  }

  @override
  Future<String> generateChatTitle(String firstMessage) async {
    return await _currentService.generateChatTitle(firstMessage);
  }

  @override
  Future<String?> generateChatSummary(List<ChatMessage> messages) async {
    return await _currentService.generateChatSummary(messages);
  }

  @override
  void clearChatSession(String sessionId) {
    _geminiService.clearChatSession(sessionId);
    _deepSeekService.clearChatSession(sessionId);
  }

  @override
  void clearAllSessions() {
    _geminiService.clearAllSessions();
    _deepSeekService.clearAllSessions();
  }

  @override
  Future<bool> testApiConnection() async {
    return await _currentService.testApiConnection();
  }

  @override
  Future<Map<String, dynamic>> getUsageInfo() async {
    return await _currentService.getUsageInfo();
  }

  @override
  Future<bool> hasQuotaRemaining() async {
    return await _currentService.hasQuotaRemaining();
  }

  Future<Map<String, dynamic>> getProviderStatus() async {
    final available = await getAvailableProviders();
    
    return {
      'current': currentProviderName,
      'available': available.map((k, v) => MapEntry(k.name, v)),
      'gemini_configured': _geminiService.isApiKeyConfigured,
      'deepseek_configured': _deepSeekService.isApiKeyConfigured,
    };
  }

  @override
  void dispose() {
    _geminiService.clearAllSessions();
    _deepSeekService.clearAllSessions();
    super.dispose();
  }

  void setUserId(String userId) {}
}
