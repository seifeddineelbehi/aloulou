// File: data/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum MessageType {
  text,
  voice,
  image,
  file,
  document,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String sessionId;
  final MessageStatus status;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  
  // Nouveaux champs pour les médias
  final String? filePath;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final Duration? audioDuration;
  final String? thumbnailPath;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    required this.sessionId,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    this.metadata,
    this.filePath,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.audioDuration,
    this.thumbnailPath,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  // Getters utilitaires
  bool get isVoice => type == MessageType.voice;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file || type == MessageType.document;
  bool get hasMedia => type != MessageType.text;
  bool get hasAudio => type == MessageType.voice && filePath != null;
  bool get hasFile => (type == MessageType.file || type == MessageType.document) && fileName != null;
  
  String get displayText {
    switch (type) {
      case MessageType.voice:
        return text.isEmpty ? '🎵 Message vocal' : text;
      case MessageType.image:
        return text.isEmpty ? '📷 Image' : text;
      case MessageType.file:
      case MessageType.document:
        return text.isEmpty ? '📎 ${fileName ?? 'Fichier'}' : text;
      case MessageType.text:
      default:
        return text;
    }
  }

  String get fileDisplayName {
    if (fileName != null) {
      return fileName!;
    }
    switch (type) {
      case MessageType.voice:
        return 'Message vocal';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
      case MessageType.document:
        return 'Fichier';
      default:
        return 'Contenu';
    }
  }

  String get fileSizeDisplay {
    if (fileSize == null) return '';
    
    if (fileSize! < 1024) {
      return '${fileSize!} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get audioDurationDisplay {
    if (audioDuration == null) return '';
    
    final minutes = audioDuration!.inMinutes;
    final seconds = audioDuration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Copy with method
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? sessionId,
    MessageStatus? status,
    MessageType? type,
    Map<String, dynamic>? metadata,
    String? filePath,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    Duration? audioDuration,
    String? thumbnailPath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      audioDuration: audioDuration ?? this.audioDuration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'sessionId': sessionId,
      'status': status.name,
      'type': type.name,
      'metadata': metadata,
      'filePath': filePath,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'audioDuration': audioDuration?.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to JSON for local storage (Hive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sessionId': sessionId,
      'status': status.name,
      'type': type.name,
      'metadata': metadata,
      'filePath': filePath,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'audioDuration': audioDuration?.inMilliseconds,
      'thumbnailPath': thumbnailPath,
    };
  }

  // Convert from JSON (used for both Firestore and local storage)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    
    if (json['timestamp'] is Timestamp) {
      // From Firestore
      parsedTimestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is int) {
      // From local storage
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else if (json['timestamp'] is String) {
      // Fallback for string timestamps
      parsedTimestamp = DateTime.parse(json['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    Duration? audioDuration;
    if (json['audioDuration'] is int) {
      audioDuration = Duration(milliseconds: json['audioDuration']);
    }

    return ChatMessage(
      id: json['id'],
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: parsedTimestamp,
      sessionId: json['sessionId'],
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      audioDuration: audioDuration,
      thumbnailPath: json['thumbnailPath'],
    );
  }

  // Convert from Firestore DocumentSnapshot
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage.fromJson(data);
  }

  // Factory pour créer un message vocal
  factory ChatMessage.voice({
    required String sessionId,
    required bool isUser,
    required String filePath,
    required Duration audioDuration,
    String? text,
    int? fileSize,
  }) {
    return ChatMessage(
      text: text ?? '',
      isUser: isUser,
      sessionId: sessionId,
      type: MessageType.voice,
      filePath: filePath,
      audioDuration: audioDuration,
      fileSize: fileSize,
      mimeType: 'audio/mp4', // ou 'audio/wav' selon le format
      fileName: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }

  // Factory pour créer un message avec fichier
  factory ChatMessage.file({
    required String sessionId,
    required bool isUser,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    String? text,
    String? thumbnailPath,
  }) {
    MessageType messageType;
    if (mimeType.startsWith('image/')) {
      messageType = MessageType.image;
    } else if (mimeType.contains('pdf') || 
               mimeType.contains('document') || 
               mimeType.contains('text')) {
      messageType = MessageType.document;
    } else {
      messageType = MessageType.file;
    }

    return ChatMessage(
      text: text ?? '',
      isUser: isUser,
      sessionId: sessionId,
      type: messageType,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      thumbnailPath: thumbnailPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage{id: $id, text: $text, isUser: $isUser, type: $type, timestamp: $timestamp}';
  }
}