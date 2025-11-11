import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/chat_message.dart';
import 'ai_service_interface.dart';

class GeminiService implements AIService {
  static const String _apiKey = 'AIzaSyBEvmEc__JFUz9z1A9fYZ567l1gyHGrqVk';
  
  @override
  bool get isApiKeyConfigured => _apiKey.isNotEmpty && _apiKey.startsWith('AIza');

  @override
  bool get requiresSubscription => false;

  @override
  SubscriptionTier get requiredTier => SubscriptionTier.free;

  late final GenerativeModel _model;
  final Map<String, ChatSession> _activeSessions = {};

  GeminiService() {
    _initializeModel();
  }

  void _initializeModel() {
    print('🔍 Initializing Gemini with multimodal support...');
    try {
      // ✅ UN SEUL MODÈLE FLASH POUR TOUT (texte + multimodal)
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 4096, // Plus de tokens pour l'analyse
          stopSequences: [],
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      print('✅ Gemini Flash initialized with multimodal support');
    } catch (e) {
      print('❌ Failed to initialize Gemini service: $e');
    }
  }

  ChatSession startChatSession(String sessionId, {List<ChatMessage>? history}) {
    final chatHistory = _buildChatHistory(history ?? []);
    
    final chatSession = _model.startChat(
      history: [
        Content.text(_getSystemPrompt()),
        ...chatHistory,
      ],
    );

    _activeSessions[sessionId] = chatSession;
    return chatSession;
  }

  ChatSession _getChatSession(String sessionId, {List<ChatMessage>? history}) {
    if (_activeSessions.containsKey(sessionId)) {
      return _activeSessions[sessionId]!;
    }
    return startChatSession(sessionId, history: history);
  }

  @override
  Future<String> sendMessage({
    required String message,
    required String sessionId,
    List<ChatMessage>? chatHistory,
  }) async {
    try {
      print('🚀 Sending text message to Gemini: $message');
      final chatSession = _getChatSession(sessionId, history: chatHistory);
      final content = Content.text(message);
      final response = await chatSession.sendMessage(content);
      
      final responseText = response.text ?? 'Désolé, je n\'ai pas pu générer une réponse.';
      print('✅ Received response from Gemini: $responseText');
      return responseText;
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      return _handleError(e);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Analyser une image
  Future<String> analyzeImage({
    required String imagePath,
    String? message,
    String? sessionId,
  }) async {
    try {
      print('🖼️ Analyzing image with Gemini: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      final fileSize = imageBytes.length;
      
      // Vérifier la taille
      if (fileSize > 20 * 1024 * 1024) {
        return 'Image trop volumineuse (max 20MB). Veuillez compresser l\'image.';
      }

      final mimeType = _getImageMimeType(imagePath);
      if (mimeType == null) {
        return 'Format d\'image non supporté. Utilisez JPEG, PNG ou WebP.';
      }

      final prompt = message ?? 'Décris cette image en détail en français. Que vois-tu dans cette image ?';
      
      // ✅ Créer le contenu multimodal
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]);

      // ✅ Utiliser le modèle principal (Flash supporte multimodal)
      final response = await _model.generateContent([content]);
      final responseText = response.text ?? 'Impossible d\'analyser cette image.';
      
      print('✅ Image analysis completed: ${responseText.substring(0, 100)}...');
      return responseText;
      
    } catch (e) {
      print('❌ Error analyzing image: $e');
      return _handleError(e);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Transcrire un audio
  Future<String> transcribeAudio({
    required String audioPath,
    String? message,
    String? sessionId,
  }) async {
    try {
      print('🎤 Transcribing audio with Gemini: $audioPath');
      
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      final audioBytes = await audioFile.readAsBytes();
      final fileSize = audioBytes.length;
      
      // Vérifier la taille
      if (fileSize > 20 * 1024 * 1024) {
        return 'Fichier audio trop volumineux (max 20MB). Veuillez réduire la durée.';
      }

      final mimeType = _getAudioMimeType(audioPath);
      if (mimeType == null) {
        return 'Format audio non supporté. Utilisez MP3, WAV, M4A ou AAC.';
      }

      final prompt = message ?? 
        'Transcris cet audio en français et réponds intelligemment au contenu. Si c\'est une question, réponds-y. Si c\'est une salutation, salue en retour.';
      
      // ✅ Créer le contenu multimodal
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, audioBytes),
      ]);

      // ✅ Utiliser le modèle principal
      final response = await _model.generateContent([content]);
      final responseText = response.text ?? 'Impossible de transcrire cet audio.';
      
      print('✅ Audio transcription completed: ${responseText.substring(0, 100)}...');
      return responseText;
      
    } catch (e) {
      print('❌ Error transcribing audio: $e');
      return _handleError(e);
    }
  }

  // ✅ MÉTHODES UTILITAIRES
  String? _getImageMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return null;
    }
  }

  String? _getAudioMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'aiff':
        return 'audio/aiff';
      default:
        return null;
    }
  }

  bool isSupportedImage(String filePath) {
    return _getImageMimeType(filePath) != null;
  }

  bool isSupportedAudio(String filePath) {
    return _getAudioMimeType(filePath) != null;
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

      final response = await _model.generateContent([Content.text(prompt)]);
      final title = response.text?.trim() ?? 'Nouveau Chat';
      
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

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
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

  List<Content> _buildChatHistory(List<ChatMessage> messages) {
    return messages.map((message) {
      return Content.text(message.text);
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

✅ CAPACITÉS MULTIMODALES :
- Tu peux voir et analyser des images en détail
- Tu peux écouter et transcrire des messages vocaux
- Tu peux combiner texte, image et audio dans tes réponses

Directives :
- Si un utilisateur écrit en arabe/tunisien, n'hésite pas à répondre dans le même style
- Sois conversationnel et naturel
- Fournis des informations utiles et exactes
- Si tu n'es pas sûr de quelque chose, admets-le honnêtement
- Garde les réponses concises mais informatives
- Utilise des salutations et expressions culturelles appropriées quand c'est pertinent
- Quand tu analyses une image, sois descriptif et précis
- Quand tu transcris de l'audio, sois fidèle au contenu et réponds si c'est une question

N'oublie pas : Tu es là pour aider et rendre les conversations agréables !''';
  }

  String _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('api key') || errorString.contains('api_key')) {
      return 'Clé API non configurée. Veuillez configurer votre clé Gemini API.';
    } else if (errorString.contains('quota') || errorString.contains('limit')) {
      return 'Quota API dépassé. Veuillez réessayer plus tard.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
    } else if (errorString.contains('blocked') || errorString.contains('safety')) {
      return 'Message bloqué par les filtres de sécurité. Veuillez reformuler votre message.';
    } else if (errorString.contains('model') || errorString.contains('not found')) {
      return 'Modèle API non trouvé. Le service sera mis à jour bientôt.';
    } else if (errorString.contains('file') || errorString.contains('format')) {
      return 'Format de fichier non supporté ou fichier endommagé.';
    } else if (errorString.contains('size') || errorString.contains('large')) {
      return 'Fichier trop volumineux. Veuillez réduire la taille.';
    }
    
    print('🔍 ERREUR GEMINI DÉTAILLÉE: $error');
    return 'Désolé, j\'ai rencontré une erreur. Veuillez réessayer.';
  }

  @override
  Future<bool> testApiConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text('Réponds simplement "OK" si tu peux me lire.')
      ]);
      return response.text?.isNotEmpty == true;
    } catch (e) {
      print('Test API failed: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageInfo() async {
    return {
      'provider': 'Gemini',
      'model': 'gemini-1.5-flash',
      'tier_required': 'free',
      'configured': isApiKeyConfigured,
      'supports_images': true,
      'supports_audio': true,
      'max_file_size': '20MB',
      'supported_image_formats': ['JPEG', 'PNG', 'WebP', 'HEIC', 'HEIF'],
      'supported_audio_formats': ['MP3', 'WAV', 'M4A', 'AAC', 'OGG', 'FLAC', 'AIFF'],
    };
  }

  @override
  Future<bool> hasQuotaRemaining() async {
    try {
      return await testApiConnection();
    } catch (e) {
      return false;
    }
  }
}