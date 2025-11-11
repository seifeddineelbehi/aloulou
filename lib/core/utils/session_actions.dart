// File: core/utils/session_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import 'snackbar_utils.dart';

class SessionActions {
  SessionActions._();

  /// Show dialog to edit session title
  static Future<void> showEditTitleDialog({
    required BuildContext context,
    required dynamic session,
    required Function(String) onSave,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: session.title ?? 'Nouvelle conversation',
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Modifier le titre',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la conversation',
                    hintText: 'Entrez un nouveau titre...',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.of(dialogContext).pop();
                      onSave(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Créée le ${_formatDate(session.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  onSave(newTitle);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog for session deletion
  static Future<void> showDeleteConfirmDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Supprimer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette conversation ? '
            'Cette action est irréversible.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// Handle session sharing
  static Future<void> shareSession(
    BuildContext context,
    dynamic session,
  ) async {
    try {
      // Show options dialog
      final action = await _showShareOptionsDialog(context);
      
      if (action != null) {
        switch (action) {
          case ShareAction.copyLink:
            await _copySessionLink(context, session);
            break;
          case ShareAction.exportText:
            await _exportSessionAsText(context, session);
            break;
          case ShareAction.shareExternal:
            await _shareSessionExternal(context, session);
            break;
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(
          context,
          'Erreur lors du partage: $e',
        );
      }
    }
  }

  static Future<ShareAction?> _showShareOptionsDialog(
    BuildContext context,
  ) async {
    return showDialog<ShareAction>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Partager la conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShareOption(
                icon: Icons.link,
                title: 'Copier le lien',
                subtitle: 'Copier le lien de partage',
                onTap: () => Navigator.of(dialogContext).pop(ShareAction.copyLink),
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.text_snippet,
                title: 'Exporter en texte',
                subtitle: 'Télécharger la conversation',
                onTap: () => Navigator.of(dialogContext).pop(ShareAction.exportText),
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.share,
                title: 'Partager',
                subtitle: 'Partager via d\'autres apps',
                onTap: () => Navigator.of(dialogContext).pop(ShareAction.shareExternal),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _copySessionLink(
    BuildContext context,
    dynamic session,
  ) async {
    // Generate a shareable link
    final link = 'https://aloulou-ai.com/shared/${session.id}';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (context.mounted) {
      SnackbarUtils.showSuccess(
        context,
        'Lien copié dans le presse-papiers',
      );
    }
  }

  static Future<void> _exportSessionAsText(
    BuildContext context,
    dynamic session,
  ) async {
    // This would export the session as a text file
    // Implementation depends on your session data structure
    SnackbarUtils.showInfo(
      context,
      'Fonctionnalité d\'export en cours de développement',
    );
  }

  static Future<void> _shareSessionExternal(
    BuildContext context,
    dynamic session,
  ) async {
    final shareText = 'Découvrez cette conversation Aloulou: '
        'https://aloulou-ai.com/shared/${session.id}';
    
    await Share.share(
      shareText,
      subject: 'Conversation Aloulou - ${session.title ?? 'Sans titre'}',
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

enum ShareAction {
  copyLink,
  exportText,
  shareExternal,
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
                      fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }
}