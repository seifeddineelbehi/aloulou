// File: core/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';

class StorageService {
  static late Box _appBox;
  static late Box<Map> _messagesBox; // Changé pour éviter les adaptateurs complexes
  static late Box<Map> _sessionsBox; // Changé pour éviter les adaptateurs complexes
  
  // Box names
  static const String _appBoxName = 'app_data';
  static const String _messagesBoxName = 'messages';
  static const String _sessionsBoxName = 'sessions';
  
  // Keys
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _lastSyncKey = 'last_sync';

  static Future<void> init() async {
    // Open boxes sans adaptateurs personnalisés
    _appBox = await Hive.openBox(_appBoxName);
    _messagesBox = await Hive.openBox<Map>(_messagesBoxName);
    _sessionsBox = await Hive.openBox<Map>(_sessionsBoxName);
  }

  // Onboarding
  static bool get hasCompletedOnboarding => 
      _appBox.get(_onboardingCompletedKey, defaultValue: false);

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _appBox.put(_onboardingCompletedKey, completed);
  }

  // User Preferences
  static Map<String, dynamic> get userPreferences => 
      Map<String, dynamic>.from(_appBox.get(_userPreferencesKey, defaultValue: {}));

  static Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    await _appBox.put(_userPreferencesKey, preferences);
  }

  static Future<void> updateUserPreference(String key, dynamic value) async {
    final prefs = userPreferences;
    prefs[key] = value;
    await setUserPreferences(prefs);
  }

  // Theme
  static String get themeMode => _appBox.get(_themeKey, defaultValue: 'system');
  
  static Future<void> setThemeMode(String mode) async {
    await _appBox.put(_themeKey, mode);
  }

  // Language
  static String get language => _appBox.get(_languageKey, defaultValue: 'auto');
  
  static Future<void> setLanguage(String language) async {
    await _appBox.put(_languageKey, language);
  }

  // Last sync
  static DateTime? get lastSync {
    final timestamp = _appBox.get(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  static Future<void> setLastSync(DateTime dateTime) async {
    await _appBox.put(_lastSyncKey, dateTime.millisecondsSinceEpoch);
  }

  // Chat Messages
  static Future<void> saveChatMessage(ChatMessage message) async {
    await _messagesBox.put(message.id, message.toJson());
  }

  static Future<void> saveChatMessages(List<ChatMessage> messages) async {
    final messagesMap = {for (var msg in messages) msg.id: msg.toJson()};
    await _messagesBox.putAll(messagesMap);
  }

  static ChatMessage? getChatMessage(String id) {
    final data = _messagesBox.get(id);
    return data != null ? ChatMessage.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  static List<ChatMessage> getChatMessages() {
    return _messagesBox.values
        .map((data) => ChatMessage.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  static List<ChatMessage> getSessionMessages(String sessionId) {
    return _messagesBox.values
        .map((data) => ChatMessage.fromJson(Map<String, dynamic>.from(data)))
        .where((message) => message.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<void> deleteChatMessage(String id) async {
    await _messagesBox.delete(id);
  }

  static Future<void> deleteSessionMessages(String sessionId) async {
    final keysToDelete = <String>[];
    for (var entry in _messagesBox.toMap().entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data['sessionId'] == sessionId) {
        keysToDelete.add(entry.key.toString());
      }
    }
    await _messagesBox.deleteAll(keysToDelete);
  }

  static Future<void> clearAllMessages() async {
    await _messagesBox.clear();
  }

  // Chat Sessions
  static Future<void> saveChatSession(ChatSession session) async {
    await _sessionsBox.put(session.id, session.toJson());
  }

  static Future<void> saveChatSessions(List<ChatSession> sessions) async {
    final sessionsMap = {for (var session in sessions) session.id: session.toJson()};
    await _sessionsBox.putAll(sessionsMap);
  }

  static ChatSession? getChatSession(String id) {
    final data = _sessionsBox.get(id);
    return data != null ? ChatSession.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  static List<ChatSession> getChatSessions() {
    return _sessionsBox.values
        .map((data) => ChatSession.fromJson(Map<String, dynamic>.from(data)))
        .where((session) => session.isActive)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> deleteChatSession(String id) async {
    await _sessionsBox.delete(id);
    await deleteSessionMessages(id);
  }

  static Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
    await clearAllMessages();
  }

  // Generic storage methods
  static Future<void> put(String key, dynamic value) async {
    await _appBox.put(key, value);
  }

  static T? get<T>(String key, {T? defaultValue}) {
    return _appBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> delete(String key) async {
    await _appBox.delete(key);
  }

  static bool containsKey(String key) {
    return _appBox.containsKey(key);
  }

  // Cache management
  static Future<void> clearCache() async {
    await _appBox.clear();
    // Don't clear messages and sessions as they're user data
  }

  static Future<void> clearAllData() async {
    await _appBox.clear();
    await _messagesBox.clear();
    await _sessionsBox.clear();
  }

  // Statistics
  static int get totalMessages => _messagesBox.length;
  static int get totalSessions => _sessionsBox.length;
  static int get activeSessions => 
      _sessionsBox.values
          .map((data) => Map<String, dynamic>.from(data))
          .where((data) => data['isActive'] == true)
          .length;

  // Cleanup old data
  static Future<void> cleanupOldData({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;
    
    // Remove old messages
    final oldMessageKeys = <String>[];
    for (var entry in _messagesBox.toMap().entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data['timestamp'] != null && data['timestamp'] < cutoffTimestamp) {
        oldMessageKeys.add(entry.key.toString());
      }
    }
    await _messagesBox.deleteAll(oldMessageKeys);
    
    // Remove old sessions
    final oldSessionKeys = <String>[];
    for (var entry in _sessionsBox.toMap().entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data['updatedAt'] != null && data['updatedAt'] < cutoffTimestamp) {
        oldSessionKeys.add(entry.key.toString());
      }
    }
    await _sessionsBox.deleteAll(oldSessionKeys);
  }
}