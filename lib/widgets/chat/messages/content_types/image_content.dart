import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../data/models/chat_message.dart';
import 'file_error_widget.dart';

class ImageContent extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onOpenImage;

  const ImageContent({
    super.key,
    required this.message,
    this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final fileExists = message.filePath != null && 
        File(message.filePath!).existsSync();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileExists) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenImage?.call(message.filePath!);
            },
            child: Hero(
              tag: message.id,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(24),
                  bottom: message.text.isEmpty 
                      ? const Radius.circular(24) 
                      : Radius.zero,
                ),
                child: Stack(
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 320,
                        minHeight: 180,
                      ),
                      child: Image.file(
                        File(message.filePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const FileErrorWidget(message: 'Image non disponible');
                        },
                      ),
                    ),
                    
                    // Gradient overlay for better text readability
                    if (message.text.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Zoom indicator
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        Icons.zoom_out_map_rounded,
                        color: Colors.white,
                        size: 20,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          const FileErrorWidget(message: 'Image non disponible'),
        ],
          
        if (message.text.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

