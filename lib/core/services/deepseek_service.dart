import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/models/chat_message.dart';
import 'ai_service_interface.dart';

class DeepSeekService implements AIService {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  final _baseUrl = dotenv.env['BASEDE_URL'] ;

    
  @override
   bool get isApiKeyConfigured =>
    dotenv.env['GEMINI_API_KEY'] != null &&
    dotenv.env['GEMINI_API_KEY']!.isNotEmpty &&
    dotenv.env['GEMINI_API_KEY']!.startsWith('sk-');

  @override
  bool get requiresSubscription => false; // DeepSeek est gratuit

  @override
  SubscriptionTier get requiredTier => SubscriptionTier.free;

  final Map<String, List<Map<String, dynamic>>> _activeSessions = {};

  DeepSeekService() {
    _initializeService();
  }

  void _initializeService() {
    print('🔍 Initializing DeepSeek service');
    if (isApiKeyConfigured) {
      print('✅ DeepSeek service initialized successfully');
    } else {
      print('❌ DeepSeek API key not configured');
    }
  }

  void startChatSession(String sessionId, {List<ChatMessage>? history}) {
    final chatHistory = _buildChatHistory(history ?? []);
    _activeSessions[sessionId] = [
      {
        'role': 'system',
        'content': _getSystemPrompt(),
      },
      ...chatHistory,
    ];
  }

  List<Map<String, dynamic>> _getChatSession(String sessionId, {List<ChatMessage>? history}) {
    if (_activeSessions.containsKey(sessionId)) {
      return _activeSessions[sessionId]!;
    }
    startChatSession(sessionId, history: history);
    return _activeSessions[sessionId]!;
  }

  @override
  Future<String> sendMessage({
    required String message,
    required String sessionId,
    List<ChatMessage>? chatHistory,
  }) async {
    try {
      print('🚀 Sending message to DeepSeek: $message');
      
      final messages = _getChatSession(sessionId, history: chatHistory);
      
      messages.add({
        'role': 'user',
        'content': message,
      });

      final response = await _makeApiRequest(messages);
      
      if (response != null) {
        messages.add({
          'role': 'assistant',
          'content': response,
        });
        
        print('✅ Received response from DeepSeek');
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
      print('deeeeeeeeeeeeeeeeeeeeepseeeeekkkkk');
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 0.95,
          'frequency_penalty': 0,
          'presence_penalty': 0,
          'stream': false,
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
        print('❌ DeepSeek API Error: ${response.statusCode} - ${response.body}');
        throw HttpException('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<String> generateChatTitle(String firstMessage) async {
    try {
      final prompt = '''
Generate a short, descriptive title (maximum 6 words) for a chat conversation that starts with this message: "$firstMessage"

Rules:
- Maximum 6 words
- Descriptive but concise
- In the same language as the message (Arabic or English)
- No quotes or special characters

Title:''';

      final messages = [
        {
          'role': 'system',
          'content': 'You are a helpful assistant that generates concise chat titles.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ];

      final response = await _makeApiRequest(messages);
      final title = response?.trim() ?? 'Nouveau Chat';
      
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      final words = cleanTitle.split(' ');
      
      if (words.length > 6) {
        return words.take(6).join(' ');
      }
      
      return cleanTitle.isNotEmpty ? cleanTitle : 'Nouveau Chat';
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

      final prompt = '''
Summarize this conversation in one sentence (maximum 20 words):

$conversation

Summary:''';

      final apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful assistant that creates concise summaries.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
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

  List<Map<String, dynamic>> _buildChatHistory(List<ChatMessage> messages) {
    return messages.map((message) {
      return {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      };
    }).toList();
  }

  String _getSystemPrompt() {
    return '''Tu es Aloulou, un assistant IA amical et serviable qui se spécialise dans l'aide aux utilisateurs en arabe (en particulier le dialecte tunisien) et en anglais.

Ta personnalité :
- Amical et accessible
- Conscient de la culture tunisienne et arabe
- Utile et informatif
- Peut basculer entre l'arabe et l'anglais naturellement
- Compréhension du dialecte tunisien ("Derja")

Directives :
- Si un utilisateur écrit en arabe/tunisien, n'hésite pas à répondre dans le même style
- Sois conversationnel et naturel
- Fournis des informations utiles et exactes
- Si tu n'es pas sûr de quelque chose, admets-le honnêtement
- Garde les réponses concises mais informatives
- Utilise des salutations et expressions culturelles appropriées quand c'est pertinent

N'oublie pas : Tu es là pour aider et rendre les conversations agréables !''';
  }

  String _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('api key') || errorString.contains('authorization')) {
      return 'Clé API DeepSeek non configurée. Veuillez configurer votre clé API.';
    } else if (errorString.contains('quota') || errorString.contains('limit') || errorString.contains('429')) {
      return 'Quota API dépassé. Veuillez réessayer plus tard.';
    } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('socket')) {
      return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
    } else if (errorString.contains('401')) {
      return 'Clé API invalide. Vérifiez votre clé DeepSeek.';
    } else if (errorString.contains('400')) {
      return 'Requête invalide. Veuillez reformuler votre message.';
    } else if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Erreur serveur DeepSeek. Réessayez dans quelques minutes.';
    }
    
    print('🔍 ERREUR DEEPSEEK DÉTAILLÉE: $error');
    return 'Désolé, j\'ai rencontré une erreur avec DeepSeek. Veuillez réessayer.';
  }

  @override
  Future<bool> testApiConnection() async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'You are a helpful assistant.',
        },
        {
          'role': 'user',
          'content': 'Réponds simplement "OK" si tu peux me lire.',
        },
      ];

      final response = await _makeApiRequest(messages);
      return response?.isNotEmpty == true;
    } catch (e) {
      print('Test API failed: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageInfo() async {
    // DeepSeek API ne fournit pas d'endpoint pour les infos d'usage
    return {
      'provider': 'DeepSeek',
      'model': 'deepseek-chat',
      'tier_required': 'free',
      'configured': isApiKeyConfigured,
    };
  }

  @override
  Future<bool> hasQuotaRemaining() async {
    // Pour les services gratuits, on teste la connectivité
    try {
      return await testApiConnection();
    } catch (e) {
      return false;
    }
  }
}
