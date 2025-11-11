import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class NewChatFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isExpanded;
  final String? customLabel;

  const NewChatFAB({
    super.key,
    required this.onPressed,
    this.isExpanded = true,
    this.customLabel,
  });

  @override
  State<NewChatFAB> createState() => _NewChatFABState();
}

class _NewChatFABState extends State<NewChatFAB>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntryAnimation();
  }

  void _setupAnimations() {
    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Rotation animation for icon
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Shimmer animation for premium feel
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  void _startEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _rotationController.forward();
        // Start subtle pulse animation
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTap() {
    // Add rotation animation on tap
    _rotationController.reset();
    _rotationController.forward();
    
    // Shimmer effect
    _shimmerController.forward().then((_) {
      _shimmerController.reset();
    });
    
    // Strong haptic feedback
    HapticFeedback.mediumImpact();
    
    widget.onPressed();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => _onTapDown(),
              onTapUp: (_) => _onTapUp(),
              onTapCancel: () => _onTapUp(),
              onTap: _onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.isExpanded ? 28 : 28),
                  boxShadow: _buildShadows(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.isExpanded ? 28 : 28),
                  child: Stack(
                    children: [
                      // Main FAB
                      _buildMainFAB(),
                      
                      // Shimmer overlay
                      _buildShimmerOverlay(),
                      
                      // Ripple effect overlay
                      if (_isPressed) _buildRippleOverlay(),
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

  Widget _buildMainFAB() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isExpanded ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(widget.isExpanded ? 28 : 28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          
          // Text with smooth transition
          if (widget.isExpanded) ...[
            const SizedBox(width: 12),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.customLabel ?? 'Nouvelle conversation',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.isExpanded ? 28 : 28),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRippleOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(widget.isExpanded ? 28 : 28),
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows() {
    return [
      // Main shadow
      BoxShadow(
        color: AppColors.primary.withOpacity(_isHovered ? 0.4 : 0.3),
        blurRadius: _isHovered ? 20 : 12,
        offset: const Offset(0, 6),
        spreadRadius: _isHovered ? 2 : 0,
      ),
      // Glow effect
      if (_isHovered)
        BoxShadow(
          color: AppColors.primary.withOpacity(0.2),
          blurRadius: 40,
          offset: const Offset(0, 12),
          spreadRadius: 4,
        ),
      // Inner highlight
      BoxShadow(
        color: Colors.white.withOpacity(0.1),
        blurRadius: 6,
        offset: const Offset(0, -2),
        spreadRadius: -2,
      ),
    ];
  }
}

// Usage example with adaptive behavior
class AdaptiveNewChatFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final ScrollController? scrollController;

  const AdaptiveNewChatFAB({
    super.key,
    required this.onPressed,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController ?? Listenable.merge([]),
      builder: (context, child) {
        // Collapse FAB when scrolling down
        final isExpanded = scrollController?.hasClients == true
            ? scrollController!.offset < 100
            : true;

        return NewChatFAB(
          onPressed: onPressed,
          isExpanded: isExpanded,
        );
      },
    );
  }
}