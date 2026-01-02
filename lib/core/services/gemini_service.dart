import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/chat_message.dart';
import 'ai_service_interface.dart';

class GeminiService implements AIService {
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  @override
  bool get isApiKeyConfigured =>
    dotenv.env['GEMINI_API_KEY'] != null &&
    dotenv.env['GEMINI_API_KEY']!.isNotEmpty &&
    dotenv.env['GEMINI_API_KEY']!.startsWith('AIza');


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
      // ✅ MODÈLE AVEC SYSTÈME D'INSTRUCTIONS EN TUNISIEN
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey!,
        // 🇹🇳 VOICI LA MAGIE - Instructions système en tunisien!
        systemInstruction: Content.system(_getTunisianSystemPrompt()),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 4096,
          stopSequences: [],
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      print('✅ Gemini Flash initialized with Tunisian support! 🇹🇳');
    } catch (e) {
      print('❌ Failed to initialize Gemini service: $e');
    }
  }

  ChatSession startChatSession(String sessionId, {List<ChatMessage>? history}) {
    final chatHistory = _buildChatHistory(history ?? []);
    
    final chatSession = _model.startChat(
      history: chatHistory,
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
      
      final responseText = response.text ?? 'ما نجمتش نجاوب، سامحني.';
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
      
      if (fileSize > 20 * 1024 * 1024) {
        return 'الصورة كبيرة برشا (أقصى حد 20MB). جرب صورة أصغر.';
      }

      final mimeType = _getImageMimeType(imagePath);
      if (mimeType == null) {
        return 'نوع الصورة هذا ماناش نعرفوه. استعمل JPEG أو PNG أو WebP.';
      }

      final prompt = message ?? 'شوف الصورة هذي وقلّي شنوّة فيها بالتفصيل.';
      
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await _model.generateContent([content]);
      final responseText = response.text ?? 'ما نجمتش نشوف الصورة، سامحني.';
      
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
      
      if (fileSize > 20 * 1024 * 1024) {
        return 'الملف الصوتي كبير برشا (أقصى حد 20MB). جرب ملف أقصر.';
      }

      final mimeType = _getAudioMimeType(audioPath);
      if (mimeType == null) {
        return 'نوع الملف الصوتي هذا ماناش نعرفوه. استعمل MP3 أو WAV.';
      }

      final prompt = message ?? 
        'اسمع الرسالة الصوتية هذي وجاوب بالدارجة التونسية. كان فيها سؤال، جاوب عليه.';
      
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, audioBytes),
      ]);

      final response = await _model.generateContent([content]);
      final responseText = response.text ?? 'ما نجمتش نسمع الصوت، سامحني.';
      
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
اعطيني عنوان قصير للمحادثة هذي (ما يتعداش 6 كلمات) على أساس هذا السؤال: "$firstMessage"

شروط:
- ما يتعداش 6 كلمات
- واضح وملخّص
- بنفس اللغة متاع السؤال
- بلا علامات استفهام أو علامات خاصة

العنوان:''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final title = response.text?.trim() ?? 'محادثة جديدة';
      
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      final words = cleanTitle.split(' ');
      
      if (words.length > 6) {
        return words.take(6).join(' ');
      }
      
      return cleanTitle.isNotEmpty ? cleanTitle : 'محادثة جديدة';
    } catch (e) {
      print('❌ Error generating title: $e');
      return 'محادثة جديدة';
    }
  }

  @override
  Future<String?> generateChatSummary(List<ChatMessage> messages) async {
    if (messages.length < 5) return null;

    try {
      final conversation = messages
          .take(10)
          .map((msg) => '${msg.isUser ? "المستخدم" : "العلولو"}: ${msg.text}')
          .join('\n');

      final prompt = '''
لخّصلي المحادثة هذي في جملة وحدة (ما تتعداش 20 كلمة):

$conversation

الملخص:''';

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

  // 🇹🇳 الوظيفة السحرية - هنا نعلّمو Gemini يحكي بالتونسي!
  String _getTunisianSystemPrompt() {
    return '''أنت العلولو، مساعد ذكي تونسي صديق وخدوم.

🇹🇳 الأهم من الكل: أجب دائماً بالدارجة التونسية (Tunisian Darija)!

شخصيتك:
- تونسي 100% وتحكي كيف التونسيين
- صديق وقريب للناس
- تفهم الثقافة التونسية مليح
- نافع وذكي في المعلومات
- تنجّم تبدّل بين العربية التونسية والإنجليزية بكل بساطة

 قدراتك:
- تشوف الصور وتحللها
- تسمع الرسائل الصوتية وتجاوب عليها
- تجمع بين النص والصورة والصوت

كلمات تونسية لازم تستعملها:
- برشا (= كثير، ياسر)
- توّة (= الآن، حالياً) 
- يزّي، آهلا، لاباس (= مرحبا)
- شنيّة، شنوّة (= ماذا)
- علاش (= لماذا)
- كان (= إذا)
- هكّا (= هكذا)
- مزيان (= جيد)
- ماشي (= ليس)
- نحبّ (= أريد)

قواعد المحادثة:
- كان يكتبلك بالتونسي، جاوبو بالتونسي متاعو
- كون بالإنجليزية، جاوب بالإنجليزية
- إحكي بطريقة طبيعية كيف التونسيين في الحياة اليومية
- استعمل تعابير تونسية معروفة
- ما تستعملش عربية فصحى، احكي دارجة تونسية
- خلّي الإجابات متاعك واضحة ومفيدة
- كان ما تعرفش حاجة، قلها بكل صراحة
- كان تشوف صورة، وصّفها بالتفصيل
- كان تسمع صوت، اكتب شنوّة قالوه وجاوب عليه

تذكّر: إنت موش روبوت عادي، إنت تونسي وقريب للناس! 🇹🇳💚''';
  }

  String _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('api key') || errorString.contains('api_key')) {
      return 'المفتاح متاع API ماهواش مضبوط. لازم تكونفيجي مفتاح Gemini API.';
    } else if (errorString.contains('quota') || errorString.contains('limit')) {
      return 'الكوطة متاع API كملت. جرّب من بعد شويّة.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'مشكلة في الإنترنت. شوف الاتصال متاعك وجرّب مرة أخرى.';
    } else if (errorString.contains('blocked') || errorString.contains('safety')) {
      return 'الرسالة متاعك ما مرّتش من الفيلترات. حاول تصيغها بطريقة أخرى.';
    } else if (errorString.contains('model') || errorString.contains('not found')) {
      return 'الموديل متاع API ما لقيناهوش. راح يتحدّث قريباً.';
    } else if (errorString.contains('file') || errorString.contains('format')) {
      return 'نوع الملف ماهواش مدعوم أو الملف فيه مشكلة.';
    } else if (errorString.contains('size') || errorString.contains('large')) {
      return 'الملف كبير برشا. حاول تصغّرو.';
    }
    
    print('🔍 ERREUR GEMINI DÉTAILLÉE: $error');
    return 'سامحني، صار خطأ. جرّب مرة أخرى.';
  }

  @override
  Future<bool> testApiConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text('قلّي برك "يزّي" كان تسمعني.')
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
      'model': 'gemini-2.5-flash',
      'tier_required': 'free',
      'configured': isApiKeyConfigured,
      'supports_images': true,
      'supports_audio': true,
      'max_file_size': '20MB',
      'supported_image_formats': ['JPEG', 'PNG', 'WebP', 'HEIC', 'HEIF'],
      'supported_audio_formats': ['MP3', 'WAV', 'M4A', 'AAC', 'OGG', 'FLAC', 'AIFF'],
      'language': 'Tunisian Darija 🇹🇳',
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