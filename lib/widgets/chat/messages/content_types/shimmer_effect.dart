import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShimmerEffect extends StatelessWidget {
  final Animation<double> animation;
  final BorderRadius borderRadius;

  const ShimmerEffect({
    super.key,
    required this.animation,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  math.max(0.0, animation.value - 0.3),
                  animation.value,
                  math.min(1.0, animation.value + 0.3),
                ],
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
