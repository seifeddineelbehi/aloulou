// File: app/app.dart (version mise à jour sans LoadingScreen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../widgets/common/app_theme.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/views/onboarding/onboarding_screen.dart';
import '../presentation/views/auth/welcome_screen.dart';
import '../presentation/views/auth/login_screen.dart';
import '../presentation/views/auth/signup_screen.dart';
import '../presentation/views/chat/chat_screen.dart';
import '../presentation/views/chat/chat_history_screen.dart';
import '../presentation/views/chat/chat_session_screen.dart';
import '../presentation/views/profile/profile_screen.dart';

class AloulouApp extends StatelessWidget {
  const AloulouApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building AloulouApp...');
    
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        print('🔄 AuthViewModel state - isInitialized: ${authViewModel.isInitialized}');
        
        // The loading screen is now handled in main.dart
        // This widget should only be called when authViewModel is initialized
        print('✅ AuthViewModel initialized, building main app');
        
        return MaterialApp.router(
          title: 'Aloulou - AI Assistant',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _createRouter(authViewModel),
        );
      },
    );
  }

  GoRouter _createRouter(AuthViewModel authViewModel) {
    print('🛣️ Creating router...');
    
    return GoRouter(
      initialLocation: _getInitialLocation(authViewModel),
      routes: [
        // Onboarding
        GoRoute(
          path: '/onboarding',
          builder: (context, state) {
            print('📱 Navigating to OnboardingScreen');
            return const OnboardingScreen();
          },
        ),
        
        // Authentication
        GoRoute(
          path: '/welcome',
          builder: (context, state) {
            print('📱 Navigating to WelcomeScreen');
            return const WelcomeScreen();
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            print('📱 Navigating to LoginScreen');
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) {
            print('📱 Navigating to SignupScreen');
            return const SignupScreen();
          },
        ),
        
        // Main App
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            print('📱 Navigating to ChatScreen');
            return const ChatScreen();
          },
          routes: [
            GoRoute(
              path: 'history',
              builder: (context, state) {
                print('📱 Navigating to ChatHistoryScreen');
                return const ChatHistoryScreen();
              },
            ),
            GoRoute(
              path: 'session/:sessionId',
              builder: (context, state) {
                final sessionId = state.pathParameters['sessionId']!;
                print('📱 Navigating to ChatSessionScreen with sessionId: $sessionId');
                return ChatSessionScreen(sessionId: sessionId);
              },
            ),
          ],
        ),
        
        // Profile
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            print('📱 Navigating to ProfileScreen');
            return const ProfileScreen();
          },
        ),
        
        // Subscription Management - Add this new route
        // GoRoute(
        //   path: '/subscription',
        //   builder: (context, state) {
        //     print('📱 Navigating to SubscriptionScreen');
        //     return const SubscriptionScreen();
        //   },
        // ),
        
        // Settings (if you want to separate it from profile)
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            print('📱 Navigating to SettingsScreen');
            // You can create a settings screen or redirect to profile
            return const ProfileScreen();
          },
          routes: [
            // GoRoute(
            //   path: 'subscription',
            //   builder: (context, state) {
            //     print('📱 Navigating to SubscriptionScreen from settings');
            //     return const SubscriptionScreen();
            //   },
            // ),
          ],
        ),
      ],
      redirect: (context, state) {
        return _handleRedirect(authViewModel, state);
      },
    );
  }

  String _getInitialLocation(AuthViewModel authViewModel) {
    if (authViewModel.shouldShowOnboarding) {
      print('🎯 Initial location: /onboarding');
      return '/onboarding';
    } else if (authViewModel.isAuthenticated) {
      print('🎯 Initial location: /chat');
      return '/chat';
    } else {
      print('🎯 Initial location: /welcome');
      return '/welcome';
    }
  }

  String? _handleRedirect(AuthViewModel authViewModel, GoRouterState state) {
    final isAuthenticated = authViewModel.isAuthenticated;
    final shouldShowOnboarding = authViewModel.shouldShowOnboarding;
    final currentPath = state.fullPath ?? '';
    
    print('🔀 Redirect check - path: $currentPath, auth: $isAuthenticated, onboarding: $shouldShowOnboarding');
    
    // Show onboarding if needed
    if (shouldShowOnboarding && currentPath != '/onboarding') {
      print('➡️ Redirecting to onboarding');
      return '/onboarding';
    }
    
    // Redirect to welcome if not authenticated and not on auth pages
    if (!isAuthenticated && 
        !currentPath.startsWith('/welcome') && 
        !currentPath.startsWith('/login') && 
        !currentPath.startsWith('/signup') &&
        !currentPath.startsWith('/onboarding')) {
      print('➡️ Redirecting to welcome (not authenticated)');
      return '/welcome';
    }
    
    // Redirect to chat if authenticated and on auth pages
    if (isAuthenticated && 
        (currentPath.startsWith('/welcome') || 
         currentPath.startsWith('/login') || 
         currentPath.startsWith('/signup'))) {
      print('➡️ Redirecting to chat (authenticated)');
      return '/chat';
    }
    
    // Protect subscription page - require authentication
    if (currentPath.startsWith('/subscription') && !isAuthenticated) {
      print('➡️ Redirecting to welcome (subscription requires auth)');
      return '/welcome';
    }
    
    print('✅ No redirect needed');
    return null;
  }
}