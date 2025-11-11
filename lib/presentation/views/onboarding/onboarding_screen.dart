// File: presentation/views/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/onboarding_viewmodel.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, child) {
          return PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            children: [
              OnboardingScreen1(
                onNext: viewModel.nextPage,
                onSkip: viewModel.skipToEnd,
              ),
              OnboardingScreen2(
                onNext: viewModel.nextPage,
                onSkip: viewModel.skipToEnd,
              ),
              OnboardingScreen3(
                onStartNow: () async {
                  await viewModel.completeOnboarding();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}