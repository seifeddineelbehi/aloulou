import 'package:flutter/material.dart';
import '../../../../widgets/common/search_bar.dart';

class SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchSection({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: CustomSearchBar(
        controller: controller,
        hintText: 'Rechercher dans les conversations...',
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}
