// File: core/services/firebase_service.dart (version améliorée)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String chatSessionsCollection = 'chat_sessions';
  static const String messagesCollection = 'messages';

  // Initialize Firebase service
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await firestore.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
        await auth.setPersistence(Persistence.LOCAL);
      } else {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Amélioration du cache
        );
      }
    } catch (e) {
      debugPrint('Firebase configuration error: $e');
    }
  }

  // Get current user ID
  static String? get currentUserId => auth.currentUser?.uid;

  // Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;

  // User collection reference
  static DocumentReference userDoc(String userId) =>
      firestore.collection(usersCollection).doc(userId);

  // Chat sessions collection reference for user
  static CollectionReference userChatSessions(String userId) =>
      firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(chatSessionsCollection);

  // Messages collection reference for session
  static CollectionReference sessionMessages(String userId, String sessionId) =>
      firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(chatSessionsCollection)
          .doc(sessionId)
          .collection(messagesCollection);

  // Get user's chat sessions query with pagination
  static Query getUserChatSessionsQuery(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = userChatSessions(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query;
  }

  // Get session messages query with pagination
  static Query getSessionMessagesQuery(
    String userId, 
    String sessionId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    Query query = sessionMessages(userId, sessionId)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query;
  }

  // Search sessions by title
  static Query searchUserSessions(String userId, String searchTerm) {
    final endTerm = searchTerm.substring(0, searchTerm.length - 1) +
        String.fromCharCode(searchTerm.codeUnitAt(searchTerm.length - 1) + 1);
    
    return userChatSessions(userId)
        .where('isActive', isEqualTo: true)
        .where('title', isGreaterThanOrEqualTo: searchTerm)
        .where('title', isLessThan: endTerm)
        .orderBy('title')
        .orderBy('updatedAt', descending: true);
  }

  // Get recent sessions (last 7 days)
  static Query getRecentSessions(String userId) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return userChatSessions(userId)
        .where('isActive', isEqualTo: true)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .orderBy('updatedAt', descending: true);
  }

  // Batch operations
  static WriteBatch batch() => firestore.batch();

  // Transaction operations
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) => firestore.runTransaction(updateFunction);

  // Stream helpers with error handling
  static Stream<DocumentSnapshot> documentStream(DocumentReference ref) =>
      ref.snapshots().handleError((error) {
        debugPrint('Document stream error: ${getErrorMessage(error)}');
      });

  static Stream<QuerySnapshot> collectionStream(Query query) =>
      query.snapshots().handleError((error) {
        debugPrint('Collection stream error: ${getErrorMessage(error)}');
      });

  // Utility methods for common operations
  static Future<bool> documentExists(DocumentReference ref) async {
    try {
      final doc = await ref.get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking document existence: ${getErrorMessage(e)}');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getDocumentData(DocumentReference ref) async {
    try {
      final doc = await ref.get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      debugPrint('Error getting document data: ${getErrorMessage(e)}');
      return null;
    }
  }

  // Bulk operations
  static Future<void> bulkWrite(List<Map<String, dynamic>> operations) async {
    const batchSize = 500; // Firestore batch limit
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize < operations.length) ? i + batchSize : operations.length;
      
      for (int j = i; j < end; j++) {
        final operation = operations[j];
        final ref = operation['ref'] as DocumentReference;
        final data = operation['data'] as Map<String, dynamic>;
        final operationType = operation['type'] as String;
        
        switch (operationType) {
          case 'set':
            batch.set(ref, data);
            break;
          case 'update':
            batch.update(ref, data);
            break;
          case 'delete':
            batch.delete(ref);
            break;
        }
      }
      
      await batch.commit();
    }
  }

  // Analytics and statistics
  static Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final sessionsSnapshot = await userChatSessions(userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      int totalMessages = 0;
      for (final session in sessionsSnapshot.docs) {
        final messagesSnapshot = await sessionMessages(userId, session.id).get();
        totalMessages += messagesSnapshot.size;
      }
      
      return {
        'totalSessions': sessionsSnapshot.size,
        'totalMessages': totalMessages,
      };
    } catch (e) {
      debugPrint('Error getting user stats: ${getErrorMessage(e)}');
      return {'totalSessions': 0, 'totalMessages': 0};
    }
  }

  // Cleanup operations
  static Future<void> cleanupInactiveSessions(String userId, {int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    try {
      final oldSessions = await userChatSessions(userId)
          .where('isActive', isEqualTo: false)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = firestore.batch();
      for (final doc in oldSessions.docs) {
        // Delete session
        batch.delete(doc.reference);
        
        // Delete associated messages
        final messages = await sessionMessages(userId, doc.id).get();
        for (final message in messages.docs) {
          batch.delete(message.reference);
        }
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up sessions: ${getErrorMessage(e)}');
    }
  }

  // Error handling (enhanced)
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission refusée. Vérifiez vos droits d\'accès.';
        case 'unavailable':
          return 'Service temporairement indisponible. Réessayez plus tard.';
        case 'cancelled':
          return 'Opération annulée.';
        case 'deadline-exceeded':
          return 'Opération expirée. Réessayez.';
        case 'not-found':
          return 'Données demandées introuvables.';
        case 'already-exists':
          return 'Les données existent déjà.';
        case 'resource-exhausted':
          return 'Quota dépassé. Réessayez plus tard.';
        case 'failed-precondition':
          return 'Échec de l\'opération due à une précondition.';
        case 'aborted':
          return 'Opération interrompue due à un conflit.';
        case 'out-of-range':
          return 'Opération hors de la plage valide.';
        case 'unimplemented':
          return 'Opération non implémentée.';
        case 'internal':
          return 'Erreur interne survenue.';
        case 'data-loss':
          return 'Perte de données irrécupérable.';
        case 'unauthenticated':
          return 'Requête non authentifiée.';
        default:
          return error.message ?? 'Une erreur est survenue.';
      }
    }
    return error.toString();
  }

  // Connectivity and health checks
  static Future<bool> checkConnectivity() async {
    try {
      await firestore.enableNetwork();
      await firestore.doc('health/check').get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> enableOfflineMode() async {
    try {
      await firestore.disableNetwork();
    } catch (e) {
      debugPrint('Error enabling offline mode: ${getErrorMessage(e)}');
    }
  }

  static Future<void> enableOnlineMode() async {
    try {
      await firestore.enableNetwork();
    } catch (e) {
      debugPrint('Error enabling online mode: ${getErrorMessage(e)}');
    }
  }

  // Retry mechanism for failed operations
  static Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) {
          debugPrint('Operation failed after $maxRetries attempts: ${getErrorMessage(e)}');
          rethrow;
        }
        await Future.delayed(delay * (attempt + 1));
      }
    }
    return null;
  }
}