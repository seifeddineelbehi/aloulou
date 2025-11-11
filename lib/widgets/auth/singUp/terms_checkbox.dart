// File: views/auth/widgets/terms_checkbox.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsCheckbox extends StatelessWidget {
  final bool acceptTerms;
  final ValueChanged<bool> onTermsToggle;

  const TermsCheckbox({
    super.key,
    required this.acceptTerms,
    required this.onTermsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: acceptTerms,
            onChanged: (value) => onTermsToggle(value ?? false),
            activeColor: Colors.white,
            checkColor: AppColors.primary,
            side: BorderSide(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontFamily: 'Space Grotesk',
              ),
              children: [
                const TextSpan(text: 'J\'accepte les '),
                TextSpan(
                  text: 'conditions d\'utilisation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' et la '),
                TextSpan(
                  text: 'politique de confidentialité',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
