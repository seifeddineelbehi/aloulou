// File: lib/widgets/onboarding/onboarding_button.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OnboardingButton extends StatefulWidget {
  final String text;
  final bool isOutlined;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool isLoading;

  const OnboardingButton({
    super.key,
    required this.text,
    required this.isOutlined,
    required this.onTap,
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.fullWidth ? 32 : 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: widget.isOutlined ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: widget.isOutlined
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: widget.isOutlined
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isOutlined ? Colors.white : AppColors.primary,
                        ),
                      ),
                    )
                  : Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isOutlined ? Colors.white : AppColors.primary,
                        fontSize: 16,
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          );
        },
      ),
    );
  }
}