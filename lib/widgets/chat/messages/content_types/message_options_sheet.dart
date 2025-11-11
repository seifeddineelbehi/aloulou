// widgets/message_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/chat_message.dart';

class MessageOptionsSheet {
  static void show({
    required BuildContext context,
    required ChatMessage message,
    required bool isPlaying,
    Function(String)? onPlayAudio,
    Function(String)? onStopAudio,
    Function(String)? onOpenFile,
    Function(String)? onOpenImage,
    VoidCallback? onRetry,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MessageOptionsContent(
        message: message,
        isPlaying: isPlaying,
        onPlayAudio: onPlayAudio,
        onStopAudio: onStopAudio,
        onOpenFile: onOpenFile,
        onOpenImage: onOpenImage,
        onRetry: onRetry,
        onDelete: onDelete,
      ),
    );
  }
}

class _MessageOptionsContent extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final Function(String)? onPlayAudio;
  final Function(String)? onStopAudio;
  final Function(String)? onOpenFile;
  final Function(String)? onOpenImage;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const _MessageOptionsContent({
    required this.message,
    required this.isPlaying,
    this.onPlayAudio,
    this.onStopAudio,
    this.onOpenFile,
    this.onOpenImage,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Options du message',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Options
          ..._buildOptions(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    final options = <Widget>[];

    // Copy text option
    if (message.text.isNotEmpty) {
      options.add(
        MessageOptionTile(
          icon: Icons.copy_rounded,
          title: 'Copier le texte',
          subtitle: 'Copier dans le presse-papier',
          color: Colors.blue,
          onTap: () => _copyText(context),
        ),
      );
    }

    // Voice options
    if (message.isVoice) {
      options.add(
        MessageOptionTile(
          icon: isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          title: isPlaying ? 'Arrêter' : 'Écouter',
          subtitle: isPlaying ? 'Arrêter la lecture' : 'Lire le message vocal',
          color: Colors.purple,
          onTap: () => _handleVoiceAction(context),
        ),
      );
    }

    // File options
    if (message.hasMedia && !message.isVoice) {
      options.add(
        MessageOptionTile(
          icon: Icons.open_in_new_rounded,
          title: 'Ouvrir le fichier',
          subtitle: 'Ouvrir dans une autre app',
          color: Colors.orange,
          onTap: () => _openFile(context),
        ),
      );
    }

    // Retry option
    if (message.status == MessageStatus.failed && onRetry != null) {
      options.add(
        MessageOptionTile(
          icon: Icons.refresh_rounded,
          title: 'Réessayer',
          subtitle: 'Renvoyer le message',
          color: AppColors.primary,
          onTap: () => _retry(context),
        ),
      );
    }

    // Delete option
    if (onDelete != null) {
      options.add(
        MessageOptionTile(
          icon: Icons.delete_rounded,
          title: 'Supprimer',
          subtitle: 'Supprimer définitivement',
          color: Colors.red,
          onTap: () => _delete(context),
        ),
      );
    }

    return options;
  }

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    Navigator.pop(context);
    _showSuccessSnackBar(context, 'Texte copié');
  }

  void _handleVoiceAction(BuildContext context) {
    Navigator.pop(context);
    if (isPlaying) {
      onStopAudio?.call(message.id);
    } else {
      onPlayAudio?.call(message.id);
    }
  }

  void _openFile(BuildContext context) {
    Navigator.pop(context);
    if (message.isImage) {
      onOpenImage?.call(message.filePath ?? '');
    } else {
      onOpenFile?.call(message.filePath ?? '');
    }
  }

  void _retry(BuildContext context) {
    Navigator.pop(context);
    onRetry?.call();
  }

  void _delete(BuildContext context) {
    Navigator.pop(context);
    onDelete?.call();
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class MessageOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const MessageOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}