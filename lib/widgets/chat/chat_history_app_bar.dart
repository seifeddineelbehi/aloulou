import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/viewmodels/chat_history_viewmodel.dart';
import 'sort_menu.dart';

class ChatHistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const ChatHistoryAppBar({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Historique des conversations',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        SortMenu(
          onSortSelected: (sortType) {
            context.read<ChatHistoryViewModel>().sortSessions(sortType);
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

