// File: core/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;

class MediaService {
  static MediaService? _instance;
  static MediaService get instance => _instance ??= MediaService._();
  MediaService._();

  // Audio recording avec 'record' package
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _audioPlayer;
  bool _isRecording = false;
  String? _currentRecordingPath;

  // Initialize the service
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      print('✅ MediaService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize MediaService: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _audioRecorder.dispose();
      await _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (e) {
      print('Error disposing MediaService: $e');
    }
  }

  // === PERMISSIONS ===
  
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      print('🎤 Microphone permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        print('💾 Storage permission status: $status');
        return status == PermissionStatus.granted;
      }
      return true;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      print('📷 Camera permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  // === AUDIO RECORDING ===
  
  Future<bool> startRecording() async {
    try {
      print('🎤 Attempting to start recording...');
      
      if (!await requestMicrophonePermission()) {
        throw Exception('Microphone permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = path.join(directory.path, 'audio', fileName);
      
      // Create directory if it doesn't exist
      final audioDir = Directory(path.dirname(filePath));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
        print('📁 Created audio directory: ${audioDir.path}');
      }

      // Check if recording is supported
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Recording permission not granted');
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;

      print('🎤 Recording started: $filePath');
      return true;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  Future<RecordingResult?> stopRecording() async {
    try {
      print('⏹️ Stopping recording...');
      
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      final filePath = await _audioRecorder.stop();
      _isRecording = false;
      
      if (filePath == null) {
        throw Exception('No recording file path');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file does not exist');
      }

      final fileSize = await file.length();
      final duration = await getAudioDuration(filePath);

      print('🎵 Recording completed: $filePath (${fileSize} bytes, ${duration?.inSeconds}s)');

      return RecordingResult(
        filePath: filePath,
        fileSize: fileSize,
        duration: duration ?? Duration.zero,
      );
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  Future<bool> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
        
        // Delete the cancelled recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Deleted cancelled recording: $_currentRecordingPath');
          }
        }
        _currentRecordingPath = null;
      }
      return true;
    } catch (e) {
      print('Error canceling recording: $e');
      return false;
    }
  }

  bool get isRecording => _isRecording;

  // === AUDIO PLAYBACK ===
  
  Future<bool> playAudio(String filePath) async {
    try {
      print('🔊 Playing audio: $filePath');
      
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
      }

      await _audioPlayer!.setFilePath(filePath);
      await _audioPlayer!.play();

      print('🔊 Audio playback started');
      return true;
    } catch (e) {
      print('❌ Failed to play audio: $e');
      return false;
    }
  }

  Future<bool> stopAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        print('⏹️ Audio playback stopped');
      }
      return true;
    } catch (e) {
      print('Error stopping audio: $e');
      return false;
    }
  }

  Future<bool> pauseAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
        print('⏸️ Audio playback paused');
      }
      return true;
    } catch (e) {
      print('Error pausing audio: $e');
      return false;
    }
  }

  Future<bool> resumeAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play();
        print('▶️ Audio playback resumed');
      }
      return true;
    } catch (e) {
      print('Error resuming audio: $e');
      return false;
    }
  }

  bool get isPlaying => _audioPlayer?.playing ?? false;
  Stream<Duration>? get audioPositionStream => _audioPlayer?.positionStream;
  Stream<Duration?>? get audioDurationStream => _audioPlayer?.durationStream;
  Stream<PlayerState>? get audioPlayerStream => _audioPlayer?.playerStateStream;

  // === FILE OPERATIONS ===
  
  Future<FilePickResult?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool allowMultiple = false,
  }) async {
    try {
      print('📎 Picking file...');
      
      // Demander la permission de stockage sur Android
      if (Platform.isAndroid && !await requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false, // Changé à false pour éviter les problèmes de mémoire
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        print('📎 File picked: ${file.name} (${file.size} bytes)');
        
        // Copier le fichier vers le répertoire de l'app
        final savedFile = await _saveFileToAppDirectory(file);
        
        return FilePickResult(
          fileName: file.name,
          filePath: savedFile?.path ?? file.path!,
          fileSize: file.size,
          mimeType: _getMimeType(file.name),
          fileBytes: null, // Pas besoin des bytes
        );
      }
      
      print('📎 No file selected');
      return null;
    } catch (e) {
      print('❌ Failed to pick file: $e');
      return null;
    }
  }

  Future<FilePickResult?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      print('📷 Picking image from ${source.name}...');
      
      if (source == ImageSource.camera && !await requestCameraPermission()) {
        throw Exception('Camera permission denied');
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        print('📷 Image picked: ${path.basename(image.path)} (${fileSize} bytes)');
        
        // Copy to app directory
        final savedFile = await _copyFileToAppDirectory(file, 'images');
        
        return FilePickResult(
          fileName: path.basename(image.path),
          filePath: savedFile?.path ?? image.path,
          fileSize: fileSize,
          mimeType: 'image/${path.extension(image.path).substring(1)}',
        );
      }
      
      print('📷 No image selected');
      return null;
    } catch (e) {
      print('❌ Failed to pick image: $e');
      return null;
    }
  }

  // === UTILITY FUNCTIONS ===
  
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setFilePath(filePath);
      final duration = tempPlayer.duration;
      await tempPlayer.dispose();
      return duration;
    } catch (e) {
      print('Error getting audio duration: $e');
      // Estimation basée sur la taille du fichier
      try {
        final file = File(filePath);
        final fileSize = await file.length();
        final estimatedSeconds = (fileSize * 8) / (128 * 1000); // 128 kbps
        return Duration(seconds: estimatedSeconds.round());
      } catch (e2) {
        return Duration(seconds: 1); // Fallback
      }
    }
  }

  Future<File?> _saveFileToAppDirectory(PlatformFile platformFile) async {
    try {
      if (platformFile.path == null) {
        print('❌ Platform file path is null');
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
      final filePath = path.join(directory.path, 'files', fileName);
      
      // Create directory if it doesn't exist
      final fileDir = Directory(path.dirname(filePath));
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
        print('📁 Created files directory: ${fileDir.path}');
      }

      // Copy the original file
      final originalFile = File(platformFile.path!);
      final newFile = await originalFile.copy(filePath);
      
      print('💾 File saved to: $filePath');
      return newFile;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  Future<File?> _copyFileToAppDirectory(File originalFile, String subdirectory) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalFile.path)}';
      final filePath = path.join(directory.path, subdirectory, fileName);
      
      // Create directory if it doesn't exist
      final fileDir = Directory(path.dirname(filePath));
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
        print('📁 Created $subdirectory directory: ${fileDir.path}');
      }

      final newFile = await originalFile.copy(filePath);
      print('💾 File copied to: $filePath');
      return newFile;
    } catch (e) {
      print('Error copying file: $e');
      return null;
    }
  }

  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp3':
        return 'audio/mpeg';
      case '.mp4':
        return 'video/mp4';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  // Clean up old files
  Future<void> cleanupOldFiles({int daysToKeep = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final subdirs = ['audio', 'images', 'files'];
      
      for (final subdir in subdirs) {
        final dir = Directory(path.join(directory.path, subdir));
        if (await dir.exists()) {
          await for (final file in dir.list()) {
            if (file is File) {
              final stat = await file.stat();
              if (stat.modified.isBefore(cutoffDate)) {
                await file.delete();
                print('🗑️ Deleted old file: ${file.path}');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }

  // Get app directory usage
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      int totalSize = 0;
      int fileCount = 0;
      
      final subdirs = ['audio', 'images', 'files'];
      final directorySizes = <String, int>{};
      
      for (final subdir in subdirs) {
        final dir = Directory(path.join(directory.path, subdir));
        int dirSize = 0;
        int dirFileCount = 0;
        
        if (await dir.exists()) {
          await for (final file in dir.list()) {
            if (file is File) {
              final size = await file.length();
              dirSize += size;
              totalSize += size;
              dirFileCount++;
              fileCount++;
            }
          }
        }
        
        directorySizes[subdir] = dirSize;
      }
      
      return {
        'totalSize': totalSize,
        'totalFiles': fileCount,
        'directorySizes': directorySizes,
        'formattedSize': _formatFileSize(totalSize),
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {
        'totalSize': 0,
        'totalFiles': 0,
        'directorySizes': {},
        'formattedSize': '0 B',
      };
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

// Result classes
class RecordingResult {
  final String filePath;
  final int fileSize;
  final Duration duration;

  RecordingResult({
    required this.filePath,
    required this.fileSize,
    required this.duration,
  });
}

class FilePickResult {
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final Uint8List? fileBytes;

  FilePickResult({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.fileBytes,
  });
}