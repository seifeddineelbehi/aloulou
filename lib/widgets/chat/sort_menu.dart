import 'package:flutter/material.dart';
import '../../../presentation/viewmodels/chat_history_viewmodel.dart';

class SortMenu extends StatelessWidget {
  final Function(SessionSortType) onSortSelected;

  const SortMenu({
    super.key,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) {
        switch (value) {
          case 'newest':
            onSortSelected(SessionSortType.newest);
            break;
          case 'oldest':
            onSortSelected(SessionSortType.oldest);
            break;
          case 'alphabetical':
            onSortSelected(SessionSortType.alphabetical);
            break;
          case 'most_messages':
            onSortSelected(SessionSortType.mostMessages);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'newest',
          child: SortMenuItem(
            icon: Icons.schedule,
            text: 'Plus récent',
          ),
        ),
        const PopupMenuItem(
          value: 'oldest',
          child: SortMenuItem(
            icon: Icons.history,
            text: 'Plus ancien',
          ),
        ),
        const PopupMenuItem(
          value: 'alphabetical',
          child: SortMenuItem(
            icon: Icons.sort_by_alpha,
            text: 'Alphabétique',
          ),
        ),
        const PopupMenuItem(
          value: 'most_messages',
          child: SortMenuItem(
            icon: Icons.chat,
            text: 'Plus de messages',
          ),
        ),
      ],
    );
  }
}

class SortMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const SortMenuItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
