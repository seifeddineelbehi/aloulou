// File: presentation/views/onboarding/onboarding_screen_2.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/onboarding/onboarding_button.dart';

class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingScreen2({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // Orange bottom section
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: screenWidth,
              height: screenHeight * 0.48,
              decoration: const ShapeDecoration(
                color: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ),

          // Main illustration - Person with robot brainstorming
          Positioned(
            left: screenWidth * 0.1,
            top: screenHeight * 0.28,
            child: Container(
              width: screenWidth * 0.8,
              height: screenHeight * 0.38,
              child: Image.asset(
                'assets/images/onboarding/onboarding_2.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            left: screenWidth * 0.25,
            bottom: 80,
            child: Row(
              children: [
                OnboardingButton(
                  text: AppStrings.skip,
                  isOutlined: true,
                  onTap: onSkip,
                ),
                const SizedBox(width: 16),
                OnboardingButton(
                  text: AppStrings.next,
                  isOutlined: false,
                  onTap: onNext,
                ),
              ],
            ),
          ),

          // Title and description
          Positioned(
            left: screenWidth * 0.05,
            top: screenHeight * 0.08,
            child: SizedBox(
              width: screenWidth * 0.9,
              child: Column(
                children: [
                  const Text(
                    AppStrings.onboarding2Title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.onboarding2Subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}