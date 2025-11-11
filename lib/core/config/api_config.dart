// File: core/config/api_config.dart (remplace complètement l'ancien fichier)
class APIConfig {
  // Configuration des clés API (en dur pour l'instant)
  static const String _geminiApiKey = 'AIzaSyBEvmEc__JFUz9z1A9fYZ567l1gyHGrqVk';
  static const String _deepSeekApiKey = 'sk-ec4c527510cc41fd91ebf0bab1796171';
  static const String _openAIApiKey = ''; // À configurer plus tard

  // URLs des APIs
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1';
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  
  // Configuration Stripe (initialisée pour éviter les erreurs)
  static const String stripePublishableKey = ''; // Sera configuré plus tard
  static const String stripeSecretKey = ''; // Sera configuré plus tard
  
  // Configuration réseau
  static const int apiTimeout = 30000;
  static const int maxRetries = 3;
  static const int retryDelay = 2000;

  // Configuration de l'environnement
  static const bool isDebugMode = true; // Changer en false pour la production
  static const bool enableLogging = true;
  static const String appEnvironment = 'development';
  static const bool enablePayments = false; // Désactivé pour l'instant

  // Méthode d'initialisation (simplifiée)
  static Future<void> init() async {
    print('⚙️ APIConfig: Configuration loaded successfully');
  }

  // Getters pour les clés API
  static String get geminiApiKey => _geminiApiKey;
  static String get deepSeekApiKey => _deepSeekApiKey;
  static String get openAIApiKey => _openAIApiKey;

  // Validation des clés
  static bool get isGeminiConfigured => 
      _geminiApiKey.isNotEmpty && _geminiApiKey.startsWith('AIza');
  
  static bool get isDeepSeekConfigured => 
      _deepSeekApiKey.isNotEmpty && _deepSeekApiKey.startsWith('sk-');
  
  static bool get isOpenAIConfigured => 
      _openAIApiKey.isNotEmpty && _openAIApiKey.startsWith('sk-');
  
  // Validation Stripe
  static bool get isStripeConfigured => 
      stripePublishableKey.isNotEmpty && stripeSecretKey.isNotEmpty;
  
  // Status des APIs
  static Map<String, bool> get apiStatus => {
    'gemini': isGeminiConfigured,
    'deepseek': isDeepSeekConfigured,
    'openai': isOpenAIConfigured,
    'stripe': isStripeConfigured,
  };
  
  // Configuration pour les tests
  static bool get isProduction => appEnvironment == 'production';
  static bool get isDevelopment => appEnvironment == 'development';
  
  // Méthode de logging
  static void logConfig() {
    if (enableLogging) {
      print('🔧 API Configuration:');
      print('  - Environment: $appEnvironment');
      print('  - Debug Mode: $isDebugMode');
      print('  - Payments Enabled: $enablePayments');
      print('  - Gemini Configured: $isGeminiConfigured');
      print('  - DeepSeek Configured: $isDeepSeekConfigured');
      print('  - OpenAI Configured: $isOpenAIConfigured');
      print('  - Stripe Configured: $isStripeConfigured');
      print('  - API Timeout: ${apiTimeout}ms');
      print('  - Max Retries: $maxRetries');
    }
  }
  
  // Obtenir les informations de configuration sans exposer les clés
  static Map<String, dynamic> getConfigInfo() {
    return {
      'environment': appEnvironment,
      'debug_mode': isDebugMode,
      'payments_enabled': enablePayments,
      'gemini_configured': isGeminiConfigured,
      'deepseek_configured': isDeepSeekConfigured,
      'openai_configured': isOpenAIConfigured,
      'stripe_configured': isStripeConfigured,
      'gemini_key_preview': isGeminiConfigured 
          ? '${_geminiApiKey.substring(0, 8)}...' 
          : 'Non configurée',
      'deepseek_key_preview': isDeepSeekConfigured 
          ? '${_deepSeekApiKey.substring(0, 8)}...' 
          : 'Non configurée',
      'openai_key_preview': isOpenAIConfigured 
          ? '${_openAIApiKey.substring(0, 8)}...' 
          : 'Non configurée',
      'api_timeout': apiTimeout,
      'max_retries': maxRetries,
    };
  }

  // Méthodes utilitaires pour la configuration future
  static bool canUseStripe() => isStripeConfigured && enablePayments;
  static bool canUseOpenAI() => isOpenAIConfigured;
  static bool canUseGemini() => isGeminiConfigured;
  static bool canUseDeepSeek() => isDeepSeekConfigured;
}