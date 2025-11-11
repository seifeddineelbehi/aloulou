import 'package:flutter/material.dart';

class GoogleSignupButton extends StatelessWidget {
  final bool isGoogleLoading;
  final VoidCallback onSignUpWithGoogle;

  const GoogleSignupButton({
    super.key,
    required this.isGoogleLoading,
    required this.onSignUpWithGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isGoogleLoading ? null : onSignUpWithGoogle,
        icon: isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.login, color: Colors.white),
        label: const Text(
          'Continuer avec Google',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

