// File: presentation/viewmodels/chat_history_viewmodel.dart
import 'package:flutter/material.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';

class ChatHistoryViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  UserRepository? _userRepository;

  ChatHistoryViewModel({
    required ChatRepository chatRepository,
    UserRepository? userRepository,
  }) : _chatRepository = chatRepository,
       _userRepository = userRepository;

  // State - InitialisÃ©s avec des valeurs par dÃ©faut
  List<ChatSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String _searchQuery = '';
  List<ChatSession> _filteredSessions = [];
  final Map<String, List<ChatMessage>> _sessionMessages = {};

  // Getters
  List<ChatSession> get sessions => _searchQuery.isEmpty ? _sessions : _filteredSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSessions => _sessions.isNotEmpty;
  String get searchQuery => _searchQuery;
  int get totalSessions => _sessions.length;

  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _userRepository ??= UserRepository();
    loadSessions();
  }

  // Load chat sessions
  Future<void> loadSessions() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      _sessions = await _chatRepository.getChatSessions(_currentUserId!);
      _applySearchFilter();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get sessions stream for real-time updates
  Stream<List<ChatSession>> getSessionsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _chatRepository.getChatSessionsStream(_currentUserId!)
        .map((sessions) {
      _sessions = sessions;
      _applySearchFilter();
      return sessions;
    });
  }

  // Create new session
  Future<ChatSession?> createNewSession() async {
    if (_currentUserId == null) return null;

    _setLoading(true);
    try {
      final session = await _chatRepository.createChatSession(_currentUserId!);
      
      // Add to local list
      _sessions.insert(0, session);
      _applySearchFilter();
      
      // Update user stats
      await _updateUserStats();
      
      _clearError();
      return session;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      await _chatRepository.deleteChatSession(_currentUserId!, sessionId);
      
      // Remove from local list
      _sessions.removeWhere((session) => session.id == sessionId);
      _sessionMessages.remove(sessionId);
      _applySearchFilter();
      
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update session title
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    if (_currentUserId == null) return;

    try {
      final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        final updatedSession = _sessions[sessionIndex].copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );
        
        await _chatRepository.updateChatSession(updatedSession);
        
        // Update local list
        _sessions[sessionIndex] = updatedSession;
        _applySearchFilter();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get session by ID
  ChatSession? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  // Get messages for session
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    if (_currentUserId == null) return [];

    // Return cached messages if available
    if (_sessionMessages.containsKey(sessionId)) {
      return _sessionMessages[sessionId]!;
    }

    try {
      final messages = await _chatRepository.getSessionMessages(_currentUserId!, sessionId);
      _sessionMessages[sessionId] = messages;
      return messages;
    } catch (e) {
      return [];
    }
  }

  // Search sessions
  void searchSessions(String query) {
    _searchQuery = query.toLowerCase();
    _applySearchFilter();
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  // Apply search filter
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSessions = List.from(_sessions);
    } else {
      _filteredSessions = _sessions.where((session) {
        return session.title.toLowerCase().contains(_searchQuery) ||
               session.summary?.toLowerCase().contains(_searchQuery) == true;
      }).toList();
    }
  }

  // Sort sessions
  void sortSessions(SessionSortType sortType) {
    switch (sortType) {
      case SessionSortType.newest:
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SessionSortType.oldest:
        _sessions.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SessionSortType.alphabetical:
        _sessions.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SessionSortType.mostMessages:
        _sessions.sort((a, b) => b.messageCount.compareTo(a.messageCount));
        break;
    }
    _applySearchFilter();
    notifyListeners();
  }

  // Get sessions by date range
  List<ChatSession> getSessionsByDateRange(DateTime start, DateTime end) {
    return _sessions.where((session) {
      return session.createdAt.isAfter(start) && session.createdAt.isBefore(end);
    }).toList();
  }

  // Get today's sessions
  List<ChatSession> get todaySessions {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getSessionsByDateRange(startOfDay, endOfDay);
  }

  // Get this week's sessions
  List<ChatSession> get thisWeekSessions {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return getSessionsByDateRange(startOfWeekDay, now);
  }

  // Get this month's sessions
  List<ChatSession> get thisMonthSessions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return getSessionsByDateRange(startOfMonth, now);
  }

  // Generate summary for session
  Future<void> generateSessionSummary(String sessionId) async {
    if (_currentUserId == null) return;

    try {
      final summary = await _chatRepository.generateChatSummary(_currentUserId!, sessionId);
      
      if (summary != null) {
        final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
        if (sessionIndex != -1) {
          final updatedSession = _sessions[sessionIndex].copyWith(
            summary: summary,
            updatedAt: DateTime.now(),
          );
          
          await _chatRepository.updateChatSession(updatedSession);
          _sessions[sessionIndex] = updatedSession;
          _applySearchFilter();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error generating summary: $e');
    }
  }

  // Export session data
  Future<Map<String, dynamic>> exportSessionData(String sessionId) async {
    if (_currentUserId == null) return {};

    try {
      final session = getSessionById(sessionId);
      final messages = await getSessionMessages(sessionId);

      if (session == null) return {};

      return {
        'session': session.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  // Get session statistics
  Map<String, dynamic> getSessionStatistics() {
    if (_sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageMessagesPerSession': 0.0,
        'mostActiveDay': null,
        'oldestSession': null,
        'newestSession': null,
      };
    }

    final totalMessages = _sessions.fold<int>(0, (sum, session) => sum + session.messageCount);
    final averageMessages = totalMessages / _sessions.length;

    // Group sessions by day
    final sessionsByDay = <String, int>{};
    for (final session in _sessions) {
      final day = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
      final dayKey = day.toIso8601String().split('T')[0];
      sessionsByDay[dayKey] = (sessionsByDay[dayKey] ?? 0) + 1;
    }

    String? mostActiveDay;
    int maxSessions = 0;
    sessionsByDay.forEach((day, count) {
      if (count > maxSessions) {
        maxSessions = count;
        mostActiveDay = day;
      }
    });

    final sortedByDate = List<ChatSession>.from(_sessions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return {
      'totalSessions': _sessions.length,
      'totalMessages': totalMessages,
      'averageMessagesPerSession': averageMessages,
      'mostActiveDay': mostActiveDay,
      'mostActiveDayCount': maxSessions,
      'oldestSession': sortedByDate.first.toJson(),
      'newestSession': sortedByDate.last.toJson(),
    };
  }

  // Refresh sessions
  Future<void> refreshSessions() async {
    await loadSessions();
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (_currentUserId == null || _userRepository == null) return;

    try {
      await _userRepository!.incrementChatCount(_currentUserId!);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Clear all cached messages
  void clearMessageCache() {
    _sessionMessages.clear();
    notifyListeners();
  }

  // Preload messages for recent sessions
  Future<void> preloadRecentMessages({int count = 5}) async {
    if (_currentUserId == null) return;

    final recentSessions = _sessions.take(count).toList();
    
    for (final session in recentSessions) {
      if (!_sessionMessages.containsKey(session.id)) {
        try {
          final messages = await _chatRepository.getSessionMessages(_currentUserId!, session.id);
          _sessionMessages[session.id] = messages;
        } catch (e) {
          print('Error preloading messages for session ${session.id}: $e');
        }
      }
    }
  }

  // Get sessions grouped by date
  Map<String, List<ChatSession>> getSessionsGroupedByDate() {
    final grouped = <String, List<ChatSession>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);

    for (final session in _sessions) {
      final sessionDate = DateTime(
        session.createdAt.year,
        session.createdAt.month,
        session.createdAt.day,
      );

      String groupKey;
      if (sessionDate == today) {
        groupKey = 'Today';
      } else if (sessionDate == yesterday) {
        groupKey = 'Yesterday';
      } else if (sessionDate.isAfter(thisWeek)) {
        groupKey = 'This Week';
      } else if (sessionDate.isAfter(thisMonth)) {
        groupKey = 'This Month';
      } else {
        groupKey = 'Older';
      }

      grouped[groupKey] ??= [];
      grouped[groupKey]!.add(session);
    }

    // Sort sessions within each group
    grouped.forEach((key, sessions) {
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });

    return grouped;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Dispose
  @override
  void dispose() {
    _sessionMessages.clear();
    super.dispose();
  }
}

// Enum for session sorting
enum SessionSortType {
  newest,
  oldest,
  alphabetical,
  mostMessages,
}