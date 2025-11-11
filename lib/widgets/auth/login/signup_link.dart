import 'package:flutter/material.dart';

class SignupLink extends StatelessWidget {
  final VoidCallback onSignupPressed;

  const SignupLink({
    super.key,
    required this.onSignupPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontFamily: 'Space Grotesk',
          ),
        ),
        TextButton(
          onPressed: onSignupPressed,
          child: const Text(
            'S\'inscrire',
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

