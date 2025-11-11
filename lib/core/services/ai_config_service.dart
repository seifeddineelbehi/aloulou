// File: core/services/ai_config_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service_interface.dart';
import 'ai_service_manager.dart';

class AIConfigService {
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyDeepSeekApiKey = 'deepseek_api_key';
  static const String _keyPreferredProvider = 'preferred_ai_provider';
  static const String _keyAutoSwitch = 'auto_switch_provider';
  static const String _keyUsageStats = 'ai_usage_stats';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // API Keys Management
  static Future<void> setGeminiApiKey(String apiKey) async {
    await init();
    await _prefs!.setString(_keyGeminiApiKey, apiKey);
  }

  static Future<void> setDeepSeekApiKey(String apiKey) async {
    await init();
    await _prefs!.setString(_keyDeepSeekApiKey, apiKey);
  }

  static Future<String?> getGeminiApiKey() async {
    await init();
    return _prefs!.getString(_keyGeminiApiKey);
  }

  static Future<String?> getDeepSeekApiKey() async {
    await init();
    return _prefs!.getString(_keyDeepSeekApiKey);
  }

  // Provider Preferences
  static Future<void> setPreferredProvider(AIProvider provider) async {
    await init();
    await _prefs!.setString(_keyPreferredProvider, provider.name);
  }

  static Future<AIProvider> getPreferredProvider() async {
    await init();
    final providerName = _prefs!.getString(_keyPreferredProvider);
    
    if (providerName != null) {
      try {
        return AIProvider.values.firstWhere(
          (p) => p.name == providerName,
        );
      } catch (e) {
        return AIProvider.gemini; // Default fallback
      }
    }
    
    return AIProvider.gemini; // Default
  }

  // Auto-switch setting
  static Future<void> setAutoSwitchEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_keyAutoSwitch, enabled);
  }

  static Future<bool> isAutoSwitchEnabled() async {
    await init();
    return _prefs!.getBool(_keyAutoSwitch) ?? true; // Default: enabled
  }

  // Usage Statistics
  static Future<void> incrementUsage(AIProvider provider) async {
    await init();
    final currentStats = await getUsageStats();
    final providerKey = provider.name;
    currentStats[providerKey] = (currentStats[providerKey] ?? 0) + 1;
    
    final statsString = currentStats.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    
    await _prefs!.setString(_keyUsageStats, statsString);
  }

  static Future<Map<String, int>> getUsageStats() async {
    await init();
    final statsString = _prefs!.getString(_keyUsageStats) ?? '';
    
    if (statsString.isEmpty) return {};
    
    final Map<String, int> stats = {};
    final pairs = statsString.split(',');
    
    for (final pair in pairs) {
      if (pair.contains(':')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0];
          final value = int.tryParse(parts[1]) ?? 0;
          stats[key] = value;
        }
      }
    }
    
    return stats;
  }

  // Clear all configuration
  static Future<void> clearAllConfig() async {
    await init();
    await _prefs!.remove(_keyGeminiApiKey);
    await _prefs!.remove(_keyDeepSeekApiKey);
    await _prefs!.remove(_keyPreferredProvider);
    await _prefs!.remove(_keyAutoSwitch);
    await _prefs!.remove(_keyUsageStats);
  }

  // Get configuration summary
  static Future<Map<String, dynamic>> getConfigSummary() async {
    final geminiKey = await getGeminiApiKey();
    final deepSeekKey = await getDeepSeekApiKey();
    final preferredProvider = await getPreferredProvider();
    final autoSwitch = await isAutoSwitchEnabled();
    final usage = await getUsageStats();

    return {
      'gemini_configured': geminiKey?.isNotEmpty == true,
      'deepseek_configured': deepSeekKey?.isNotEmpty == true,
      'preferred_provider': preferredProvider.name,
      'auto_switch_enabled': autoSwitch,
      'usage_stats': usage,
      'total_requests': usage.values.fold(0, (sum, count) => sum + count),
    };
  }
}

// File: core/config/api_keys.dart
class APIKeys {
  // ✅ Remplacez ces valeurs par vos vraies clés API
  
  // Clé Gemini (depuis Google AI Studio)
  static const String geminiApiKey = 'AIzaSyBEvmEc__JFUz9z1A9fYZ567l1gyHGrqVk'; // Votre clé actuelle
  
  // Clé DeepSeek (depuis https://platform.deepseek.com)
  // Format: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static const String deepSeekApiKey = 'sk-YOUR_DEEPSEEK_API_KEY_HERE'; // ⚠️ REMPLACEZ PAR VOTRE CLÉ
  
  // Validation des clés
  static bool get isGeminiConfigured => 
      geminiApiKey.isNotEmpty && geminiApiKey.startsWith('AIza');
  
  static bool get isDeepSeekConfigured => 
      deepSeekApiKey.isNotEmpty && 
      deepSeekApiKey.startsWith('sk-') && 
      deepSeekApiKey != 'sk-YOUR_DEEPSEEK_API_KEY_HERE';
  
  // Obtenir la clé appropriée
  static String getGeminiKey() => geminiApiKey;
  static String getDeepSeekKey() => deepSeekApiKey;
  
  // Informations de configuration
  static Map<String, dynamic> getConfigInfo() {
    return {
      'gemini_configured': isGeminiConfigured,
      'deepseek_configured': isDeepSeekConfigured,
      'gemini_key_preview': isGeminiConfigured 
          ? '${geminiApiKey.substring(0, 8)}...' 
          : 'Non configurée',
      'deepseek_key_preview': isDeepSeekConfigured 
          ? '${deepSeekApiKey.substring(0, 8)}...' 
          : 'Non configurée',
    };
  }
}
