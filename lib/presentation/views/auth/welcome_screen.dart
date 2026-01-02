// File: presentation/views/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Container(
                width: screenWidth,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF5F5F5), // Gris très clair en haut
                      Color(0xFFFFE5E5), // Rose très clair
                      Color(0xFFFF725E), // Orange corail en bas
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Logo Aloulou
                      const Text(
                        'Aloulou',
                        style: TextStyle(
                          color: Color(0xFFFF725E),
                          fontSize: 24,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // Main title
                      const Text(
                        'Ahla bik !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 36,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      const Text(
                        'Get started now with Aloulou\nyour local ai assistant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Buttons section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            // Login button (outlined)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.go('/login');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFF725E),
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFFFF725E),
                                    fontSize: 18,
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Sign UP button (filled) - CORRIGÉ
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Rediriger vers la page d'inscription
                                  context.go('/signup');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF725E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Sign up', // Changé de "Sign in" vers "Sign up"
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Bouton "Try without account" pour connexion anonyme
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: authViewModel.isLoading 
                                    ? null 
                                    : () async {
                                        try {
                                          final success = await authViewModel.signInAnonymously();
                                          if (success && context.mounted) {
                                            context.go('/chat');
                                          }
                                        } catch (e) {
                                          print('Anonymous login error: $e');
                                          // Afficher un message d'erreur si nécessaire
                                        }
                                      },
                                child: authViewModel.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF725E)),
                                        ),
                                      )
                                    : const Text(
                                        'Try without account',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // "or sign in with" text
                            const Text(
                              'or sign in with',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Social login buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Google button
                                SocialLoginButton(
                                  onTap: authViewModel.isGoogleLoading 
                                      ? null 
                                      : () async {
                                          try {
                                            final success = await authViewModel.signInWithGoogle();
                                            if (success && context.mounted) {
                                              context.go('/chat');
                                            }
                                          } catch (e) {
                                            print('Google login error: $e');
                                            // Afficher un message d'erreur
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Erreur Google Sign-In: ${authViewModel.errorMessage ?? e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              authViewModel.clearError();
                                            }
                                          }
                                        },
                                  isLoading: authViewModel.isGoogleLoading,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Facebook button (placeholder)
                                SocialLoginButton(
                                  onTap: () async {
                                    // TODO: Implémenter la connexion Facebook
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Facebook Sign-In à venir'),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.facebook,
                                    color: Color(0xFF1877F2),
                                    size: 28,
                                  ),
                                ),
                                
                                // Apple button (placeholder)
                                SocialLoginButton(
                                  onTap: () async {
                                    // TODO: Implémenter la connexion Apple
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Apple Sign-In à venir'),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.apple,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Robot illustration
                      Container(
                        height: 100,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF725E).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_outlined,
                                size: 30,
                                color: Color(0xFFFF725E),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF725E).withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF725E).withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF725E).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget pour les boutons de connexion sociale - AMÉLIORÉ
class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.onTap,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : child,
        ),
      ),
    );
  }
}