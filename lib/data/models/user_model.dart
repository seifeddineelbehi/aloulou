// File: data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences;
  final UserStats stats;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.preferences,
    UserStats? stats,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastLoginAt = lastLoginAt ?? DateTime.now(),
       stats = stats ?? UserStats();

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  // Get display name or email
  String get displayNameOrEmail => displayName ?? email.split('@')[0];

  // Get initials for avatar
  String get initials {
    final name = displayNameOrEmail;
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toFirestoreJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences,
      'stats': stats.toFirestoreJson(),
    };
  }

  // Convert to JSON for local storage (Hive)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'preferences': preferences,
      'stats': stats.toJson(),
    };
  }

  // Convert from JSON (used for both Firestore and local storage)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: json['uid'],
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: parseTimestamp(json['createdAt']),
      lastLoginAt: parseTimestamp(json['lastLoginAt']),
      preferences: json['preferences'],
      stats: json['stats'] != null 
          ? UserStats.fromJson(json['stats'])
          : UserStats(),
    );
  }

  // Convert from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, displayName: $displayName}';
  }
}

class UserStats {
  final int totalChats;
  final int totalMessages;
  final DateTime? lastChatAt;
  final Map<String, int> dailyMessageCount;

  UserStats({
    this.totalChats = 0,
    this.totalMessages = 0,
    this.lastChatAt,
    Map<String, int>? dailyMessageCount,
  }) : dailyMessageCount = dailyMessageCount ?? {};

  // Copy with method
  UserStats copyWith({
    int? totalChats,
    int? totalMessages,
    DateTime? lastChatAt,
    Map<String, int>? dailyMessageCount,
  }) {
    return UserStats(
      totalChats: totalChats ?? this.totalChats,
      totalMessages: totalMessages ?? this.totalMessages,
      lastChatAt: lastChatAt ?? this.lastChatAt,
      dailyMessageCount: dailyMessageCount ?? this.dailyMessageCount,
    );
  }

  // Increment message count
  UserStats incrementMessages({int count = 1}) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final updatedDailyCount = Map<String, int>.from(dailyMessageCount);
    updatedDailyCount[today] = (updatedDailyCount[today] ?? 0) + count;

    return copyWith(
      totalMessages: totalMessages + count,
      lastChatAt: DateTime.now(),
      dailyMessageCount: updatedDailyCount,
    );
  }

  // Increment chat count
  UserStats incrementChats({int count = 1}) {
    return copyWith(
      totalChats: totalChats + count,
      lastChatAt: DateTime.now(),
    );
  }

  // Get today's message count
  int get todayMessageCount {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return dailyMessageCount[today] ?? 0;
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toFirestoreJson() {
    return {
      'totalChats': totalChats,
      'totalMessages': totalMessages,
      'lastChatAt': lastChatAt != null ? Timestamp.fromDate(lastChatAt!) : null,
      'dailyMessageCount': dailyMessageCount,
    };
  }

  // Convert to JSON for local storage (Hive)
  Map<String, dynamic> toJson() {
    return {
      'totalChats': totalChats,
      'totalMessages': totalMessages,
      'lastChatAt': lastChatAt?.millisecondsSinceEpoch,
      'dailyMessageCount': dailyMessageCount,
    };
  }

  // Convert from JSON (used for both Firestore and local storage)
  factory UserStats.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return null;
    }

    return UserStats(
      totalChats: json['totalChats'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      lastChatAt: parseTimestamp(json['lastChatAt']),
      dailyMessageCount: Map<String, int>.from(json['dailyMessageCount'] ?? {}),
    );
  }
}