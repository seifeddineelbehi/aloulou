// File: views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/auth/login/google_login_button.dart';
import '../../../widgets/auth/login/forgot_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // Écouter les changements d'état
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authViewModel.state == AuthState.authenticated) {
              context.go('/chat');
            } else if (authViewModel.state == AuthState.error && authViewModel.errorMessage != null) {
              _showErrorSnackBar(context, authViewModel.errorMessage!);
              authViewModel.clearError();
            }
          });

          return Scaffold(
            body: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFFF725E),
                  ],
                  stops: [0.33, 1.0],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Header avec bouton retour
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Logo
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFFF725E), width: 2),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFFFF725E),
                              size: 30,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Titre
                          const Text(
                            'Login to your account',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w400,
                              letterSpacing: -1.92,
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Formulaire
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email field
                                Container(
                                  width: double.infinity,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(64),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'Email or phone number',
                                      hintStyle: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.84,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Password field
                                Container(
                                  width: double.infinity,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(64),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.84,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.black54,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre mot de passe';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Forgot password
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () => _showForgotPasswordDialog(context, authViewModel),
                                    child: const Text(
                                      'forget password?',
                                      style: TextStyle(
                                        color: Color(0xFFA2A2A2),
                                        fontSize: 12,
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Sign in button
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6F61),
                                    borderRadius: BorderRadius.circular(64),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x26000000),
                                        blurRadius: 16,
                                        offset: Offset(2, 2),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: authViewModel.state == AuthState.loading 
                                        ? null 
                                        : () => _signInWithEmail(authViewModel),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6F61),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(64),
                                      ),
                                    ),
                                    child: authViewModel.state == AuthState.loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign in',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontFamily: 'Space Grotesk',
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: -1.08,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Divider
                          _buildDivider(),
                          
                          const SizedBox(height: 24),
                          
                          // Bouton Google
                          GoogleLoginButton(authViewModel: authViewModel),
                          
                          const SizedBox(height: 32),
                          
                          // Lien vers l'inscription
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.84,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.84,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or sign in with',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w400,
              letterSpacing: -1.08,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  void _signInWithEmail(AuthViewModel authViewModel) {
    if (_formKey.currentState!.validate()) {
      authViewModel.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ForgotPasswordDialog(
        authViewModel: authViewModel,
        onSuccess: (message) => _showErrorSnackBar(context, message),
      ),
    );
  }
}