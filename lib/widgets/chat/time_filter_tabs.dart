import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TimeFilterTabs extends StatelessWidget {
  final TabController tabController;

  const TimeFilterTabs({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Toutes'),
          Tab(text: 'Aujourd\'hui'),
          Tab(text: 'Cette semaine'),
          Tab(text: 'Ce mois'),
        ],
      ),
    );
  }
}

