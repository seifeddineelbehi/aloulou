import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'empty_state.dart';

class SearchResults<T> extends StatelessWidget {
  final List<T> results;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String? query;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Widget? emptyAction;

  const SearchResults({
    super.key,
    required this.results,
    required this.itemBuilder,
    this.query,
    this.isLoading = false,
    this.emptyTitle = 'Aucun résultat',
    this.emptySubtitle = 'Essayez de modifier votre recherche',
    this.emptyIcon = Icons.search_off,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (results.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: query?.isEmpty == true ? 'Commencez votre recherche' : emptyTitle,
        subtitle: query?.isEmpty == true 
            ? 'Tapez quelque chose dans la barre de recherche'
            : '$emptySubtitle${query != null ? ' pour "$query"' : ''}',
        action: emptyAction,
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return itemBuilder(context, results[index], index);
      },
    );
  }
}
