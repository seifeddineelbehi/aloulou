import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/models/chat_message.dart';
import 'ai_service_interface.dart';
import '../config/api_config.dart';

class OpenAIService implements AIService {
  static const String _model = 'gpt-3.5-turbo'; // Ou 'gpt-4' pour premium
  
  @override
  bool get isApiKeyConfigured => APIConfig.isOpenAIConfigured;
  
  @override
  bool get requiresSubscription => true;
  
  @override
  SubscriptionTier get requiredTier => SubscriptionTier.basic;

  final Map<String, List<Map<String, dynamic>>> _activeSessions = {};

  OpenAIService() {
    _initializeService();
  }

  void _initializeService() {
    print('🔍 Initializing OpenAI service');
    if (isApiKeyConfigured) {
      print('✅ OpenAI service initialized successfully');
    } else {
      print('❌ OpenAI API key not configured');
    }
  }

  @override
  Future<String> sendMessage({
    required String message,
    required String sessionId,
    List<ChatMessage>? chatHistory,
  }) async {
    try {
      print('🚀 Sending message to OpenAI: $message');
      
      final messages = _getChatSession(sessionId, history: chatHistory);
      
      // Add user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      final response = await _makeApiRequest(messages);
      
      if (response != null) {
        // Add assistant response
        messages.add({
          'role': 'assistant',
          'content': response,
        });
        
        print('✅ Received response from OpenAI');
        return response;
      } else {
        return 'Désolé, je n\'ai pas pu générer une réponse.';
      }
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      return _handleError(e);
    }
  }

  Future<String?> _makeApiRequest(List<Map<String, dynamic>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConfig.openAIBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${APIConfig.openAIApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 0.95,
          'frequency_penalty': 0,
          'presence_penalty': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          return message?['content'] as String?;
        }
      } else {
        print('❌ OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw HttpException('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      rethrow;
    }
    return null;
  }

  List<Map<String, dynamic>> _getChatSession(String sessionId, {List<ChatMessage>? history}) {
    if (_activeSessions.containsKey(sessionId)) {
      return _activeSessions[sessionId]!;
    }
    
    final chatHistory = _buildChatHistory(history ?? []);
    _activeSessions[sessionId] = [
      {
        'role': 'system',
        'content': _getSystemPrompt(),
      },
      ...chatHistory,
    ];
    
    return _activeSessions[sessionId]!;
  }

  List<Map<String, dynamic>> _buildChatHistory(List<ChatMessage> messages) {
    return messages.map((message) {
      return {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      };
    }).toList();
  }

  String _getSystemPrompt() {
    return '''Tu es Aloulou, un assistant IA avancé et intelligent qui utilise la technologie OpenAI.

Ta personnalité :
- Professionnel mais amical
- Très intelligent et analytique
- Capable de raisonnements complexes
- Compréhension nuancée du contexte

Spécialités :
- Analyse approfondie
- Résolution de problèmes complexes
- Créativité et innovation
- Support multilingue (arabe, français, anglais)

Tu offres des réponses de qualité supérieure grâce à la technologie GPT avancée.''';
  }

  @override
  Future<String> generateChatTitle(String firstMessage) async {
    try {
      final prompt = '''
Generate a short, descriptive title (maximum 6 words) for a chat that starts with: "$firstMessage"

Rules:
- Maximum 6 words
- Descriptive and engaging
- Same language as the message
- No quotes

Title:''';

      final messages = [
        {'role': 'system', 'content': 'You generate concise, engaging chat titles.'},
        {'role': 'user', 'content': prompt},
      ];

      final response = await _makeApiRequest(messages);
      final title = response?.trim() ?? 'Nouveau Chat';
      
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      final words = cleanTitle.split(' ');
      
      return words.length > 6 ? words.take(6).join(' ') : cleanTitle;
    } catch (e) {
      print('❌ Error generating title: $e');
      return 'Nouveau Chat';
    }
  }

  @override
  Future<String?> generateChatSummary(List<ChatMessage> messages) async {
    if (messages.length < 5) return null;

    try {
      final conversation = messages
          .take(10)
          .map((msg) => '${msg.isUser ? "User" : "AI"}: ${msg.text}')
          .join('\n');

      final prompt = '''Summarize this conversation in one sentence (max 20 words):

$conversation

Summary:''';

      final apiMessages = [
        {'role': 'system', 'content': 'You create concise conversation summaries.'},
        {'role': 'user', 'content': prompt},
      ];

      final response = await _makeApiRequest(apiMessages);
      return response?.trim();
    } catch (e) {
      print('❌ Error generating summary: $e');
      return null;
    }
  }

  @override
  void clearChatSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  @override
  void clearAllSessions() {
    _activeSessions.clear();
  }

  @override
  Future<bool> testApiConnection() async {
    try {
      final messages = [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': 'Say OK if you can read this.'},
      ];

      final response = await _makeApiRequest(messages);
      return response?.isNotEmpty == true;
    } catch (e) {
      print('OpenAI test API failed: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageInfo() async {
    // OpenAI ne fournit pas facilement les infos d'usage via l'API de chat
    return {
      'provider': 'OpenAI',
      'model': _model,
      'tier_required': requiredTier.name,
    };
  }

  @override
  Future<bool> hasQuotaRemaining() async {
    // Pour OpenAI, on peut tester avec une petite requête
    try {
      return await testApiConnection();
    } catch (e) {
      return false;
    }
  }

  String _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('api key') || errorString.contains('authorization')) {
      return 'Clé API OpenAI non configurée. Abonnement requis.';
    } else if (errorString.contains('quota') || errorString.contains('billing')) {
      return 'Quota OpenAI dépassé. Vérifiez votre facturation.';
    } else if (errorString.contains('401')) {
      return 'Clé API OpenAI invalide. Vérifiez votre abonnement.';
    } else if (errorString.contains('429')) {
      return 'Limite de taux OpenAI atteinte. Réessayez plus tard.';
    } else if (errorString.contains('500')) {
      return 'Erreur serveur OpenAI. Réessayez dans quelques minutes.';
    }
    
    return 'Erreur OpenAI. Vérifiez votre abonnement et réessayez.';
  }
}
