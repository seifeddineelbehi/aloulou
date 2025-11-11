// File: presentation/viewmodels/onboarding_viewmodel.dart
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  // State
  int _currentPage = 0;
  bool _isCompleted = false;
  bool _isLoading = true; // âœ… AjoutÃ© pour l'Ã©tat de chargement

  // Page controller
  final PageController pageController = PageController();

  // Getters
  int get currentPage => _currentPage;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading; // âœ… AjoutÃ©
  bool get isLastPage => _currentPage == 2;
  bool get isFirstPage => _currentPage == 0;

  // Total pages
  static const int totalPages = 3;

  // âœ… Constructor avec initialisation
  OnboardingViewModel() {
    _initializeOnboarding();
  }

  // âœ… MÃ©thode d'initialisation
  Future<void> _initializeOnboarding() async {
    try {
      // VÃ©rifier si l'onboarding a dÃ©jÃ  Ã©tÃ© complÃ©tÃ©
      _isCompleted = StorageService.hasCompletedOnboarding;
      _isLoading = false;
      notifyListeners();
      
      print('ðŸŽ¯ Onboarding initialized - completed: $_isCompleted');
    } catch (e) {
      print('âŒ Error initializing onboarding: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Navigation methods
  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage = page;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void skipToEnd() {
    _currentPage = totalPages - 1;
    pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  // Handle page changed (for PageView)
  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      print('âœ… Completing onboarding...');
      _isCompleted = true;
      await StorageService.setOnboardingCompleted(true);
      notifyListeners();
      print('âœ… Onboarding completed successfully');
    } catch (e) {
      print('âŒ Error completing onboarding: $e');
    }
  }

  // âœ… Skip onboarding (raccourci pour aller directement Ã  la fin)
  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }

  // Reset onboarding (for testing purposes)
  Future<void> resetOnboarding() async {
    try {
      print('ðŸ”„ Resetting onboarding...');
      _currentPage = 0;
      _isCompleted = false;
      await StorageService.setOnboardingCompleted(false);
      
      // Reset page controller position
      if (pageController.hasClients) {
        pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      
      notifyListeners();
      print('âœ… Onboarding reset successfully');
    } catch (e) {
      print('âŒ Error resetting onboarding: $e');
    }
  }

  // Get progress percentage
  double get progress => (_currentPage + 1) / totalPages;

  // Check if onboarding should be shown
  static bool shouldShowOnboarding() {
    return !StorageService.hasCompletedOnboarding;
  }

  // âœ… MÃ©thode utilitaire pour forcer la mise Ã  jour de l'Ã©tat
  void refreshOnboardingStatus() {
    _isCompleted = StorageService.hasCompletedOnboarding;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}