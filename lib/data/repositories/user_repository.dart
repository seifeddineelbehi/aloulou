// File: data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class UserRepository {
  // Create or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    try {
      // Save to Firebase
      await FirebaseService.userDoc(user.uid).set(user.toJson(), SetOptions(merge: true));
      
      // Update local preferences
      await StorageService.setUserPreferences({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isAnonymous': user.isAnonymous,
      });
    } catch (e) {
      throw Exception('Failed to save user profile: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Try Firebase first
      final doc = await FirebaseService.userDoc(uid).get();
      
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        
        // Update local preferences
        await StorageService.setUserPreferences({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'isAnonymous': user.isAnonymous,
        });
        
        return user;
      }
    } catch (e) {
      // Fallback to local preferences
      final prefs = StorageService.userPreferences;
      if (prefs.containsKey('uid') && prefs['uid'] == uid) {
        return UserModel(
          uid: prefs['uid'],
          email: prefs['email'] ?? '',
          displayName: prefs['displayName'],
          photoURL: prefs['photoURL'],
          isAnonymous: prefs['isAnonymous'] ?? false,
        );
      }
    }
    
    return null;
  }

  // Get user profile stream
  Stream<UserModel?> getUserProfileStream(String uid) {
    return FirebaseService.userDoc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user stats
  Future<void> updateUserStats(String uid, UserStats stats) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'stats': stats.toJson(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user stats: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Increment message count
  Future<void> incrementMessageCount(String uid, {int count = 1}) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'stats.totalMessages': FieldValue.increment(count),
        'stats.dailyMessageCount.${_getTodayKey()}': FieldValue.increment(count),
        'stats.lastChatAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for stats - not critical
      print('Failed to increment message count: $e');
    }
  }

  // Increment chat session count
  Future<void> incrementChatCount(String uid, {int count = 1}) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'stats.totalChats': FieldValue.increment(count),
        'stats.lastChatAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for stats - not critical
      print('Failed to increment chat count: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'preferences': preferences,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Update local preferences
      await StorageService.updateUserPreference('userPreferences', preferences);
    } catch (e) {
      // Still update locally if Firebase fails
      await StorageService.updateUserPreference('userPreferences', preferences);
      throw Exception('Failed to update preferences: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Update profile picture (URL only, no file upload for now)
  Future<void> updateProfilePicture(String uid, String photoURL) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'photoURL': photoURL,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Update local preferences
      await StorageService.updateUserPreference('photoURL', photoURL);
    } catch (e) {
      throw Exception('Failed to update profile picture: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'displayName': displayName,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Update local preferences
      await StorageService.updateUserPreference('displayName', displayName);
    } catch (e) {
      throw Exception('Failed to update display name: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Delete user data
  Future<void> deleteUserData(String uid) async {
    try {
      // Delete user document and all subcollections
      await _deleteUserDocument(uid);
      
      // Clear local data
      await StorageService.clearAllData();
    } catch (e) {
      throw Exception('Failed to delete user data: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String uid) async {
    try {
      final userDoc = await FirebaseService.userDoc(uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'profile': data,
          'stats': data['stats'] ?? {},
          'joinDate': data['createdAt'],
          'lastActive': data['lastActive'],
        };
      }
    } catch (e) {
      print('Failed to get user statistics: $e');
    }
    
    return {};
  }

  // Search users (for future features like sharing)
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    try {
      // Basic search by display name or email
      final querySnapshot = await FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await FirebaseService.userDoc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive(String uid) async {
    try {
      await FirebaseService.userDoc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - not critical
      print('Failed to update last active: $e');
    }
  }

  // Get user activity summary
  Future<Map<String, dynamic>> getUserActivity(String uid) async {
    try {
      final userDoc = await FirebaseService.userDoc(uid).get();
      final chatSessionsSnapshot = await FirebaseService.userChatSessions(uid)
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      final recentSessions = chatSessionsSnapshot.docs.length;

      return {
        'totalMessages': userData['stats']?['totalMessages'] ?? 0,
        'totalChats': userData['stats']?['totalChats'] ?? 0,
        'recentSessions': recentSessions,
        'lastChatAt': userData['stats']?['lastChatAt'],
        'todayMessages': userData['stats']?['dailyMessageCount']?[_getTodayKey()] ?? 0,
        'memberSince': userData['createdAt'],
      };
    } catch (e) {
      return {};
    }
  }

  // Sync user data
  Future<void> syncUserData(String uid) async {
    try {
      final user = await getUserProfile(uid);
      if (user != null) {
        await StorageService.setUserPreferences({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'isAnonymous': user.isAnonymous,
          'lastSync': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Failed to sync user data: $e');
    }
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData(String uid) async {
    try {
      final user = await getUserProfile(uid);
      final activity = await getUserActivity(uid);
      final statistics = await getUserStatistics(uid);

      return {
        'user': user?.toJson(),
        'activity': activity,
        'statistics': statistics,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to export user data: ${FirebaseService.getErrorMessage(e)}');
    }
  }

  // Private helper methods
  String _getTodayKey() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  Future<void> _deleteUserDocument(String uid) async {
    final batch = FirebaseService.batch();
    
    // Delete user document
    batch.delete(FirebaseService.userDoc(uid));
    
    // Delete chat sessions
    final sessionsSnapshot = await FirebaseService.userChatSessions(uid).get();
    for (final sessionDoc in sessionsSnapshot.docs) {
      batch.delete(sessionDoc.reference);
      
      // Delete messages in each session
      final messagesSnapshot = await FirebaseService
          .sessionMessages(uid, sessionDoc.id)
          .get();
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
    }
    
    await batch.commit();
  }
}