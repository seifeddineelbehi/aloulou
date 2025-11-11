import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../data/models/chat_message.dart';
import '../../../../core/utils/file_utils.dart';

class FileContent extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onOpenFile;

  const FileContent({
    super.key,
    required this.message,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenFile?.call(message.filePath ?? '');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // Enhanced file icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (message.isUser ? Colors.white : AppColors.primary)
                        .withOpacity(0.2),
                    (message.isUser ? Colors.white : AppColors.primary)
                        .withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (message.isUser ? Colors.white : AppColors.primary)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                FileUtils.getFileIcon(message.mimeType),
                color: message.isUser 
                    ? Colors.white 
                    : AppColors.primary,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Enhanced file info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileDisplayName,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (message.isUser ? Colors.white : AppColors.primary)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${message.fileSizeDisplay} • ${FileUtils.getFileTypeDisplay(message.mimeType, message.fileName)}',
                      style: TextStyle(
                        color: message.isUser 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  if (message.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Enhanced open icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (message.isUser ? Colors.white : AppColors.primary)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                color: message.isUser 
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey[700],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
