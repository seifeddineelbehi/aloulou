import 'package:flutter/material.dart';

class LoginLink extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const LoginLink({
    super.key,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontFamily: 'Space Grotesk',
          ),
        ),
        TextButton(
          onPressed: onLoginPressed,
          child: const Text(
            'Se connecter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
