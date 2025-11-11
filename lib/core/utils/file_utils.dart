// utils/file_utils.dart
import 'package:flutter/material.dart';

class FileUtils {
  static IconData getFileIcon(String? mimeType) {
    final mime = mimeType?.toLowerCase() ?? '';
    
    if (mime.startsWith('image/')) {
      return Icons.image_rounded;
    } else if (mime.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (mime.contains('word') || mime.contains('document')) {
      return Icons.description_rounded;
    } else if (mime.contains('excel') || mime.contains('spreadsheet')) {
      return Icons.table_chart_rounded;
    } else if (mime.contains('powerpoint') || mime.contains('presentation')) {
      return Icons.slideshow_rounded;
    } else if (mime.startsWith('audio/')) {
      return Icons.audiotrack_rounded;
    } else if (mime.startsWith('video/')) {
      return Icons.videocam_rounded;
    } else if (mime.contains('zip') || mime.contains('rar')) {
      return Icons.archive_rounded;
    } else if (mime.contains('text/')) {
      return Icons.text_snippet_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  static String getFileTypeDisplay(String? mimeType, String? fileName) {
    final mime = mimeType?.toLowerCase() ?? '';
    
    if (mime.contains('pdf')) return 'PDF';
    if (mime.contains('word')) return 'Word';
    if (mime.contains('excel')) return 'Excel';
    if (mime.contains('powerpoint')) return 'PowerPoint';
    if (mime.startsWith('image/')) return 'Image';
    if (mime.startsWith('audio/')) return 'Audio';
    if (mime.startsWith('video/')) return 'Vidéo';
    if (mime.contains('text/')) return 'Texte';
    
    final extension = fileName?.split('.').last.toUpperCase();
    return extension ?? 'Fichier';
  }
}

// utils/time_utils.dart
class TimeUtils {
  static String formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}