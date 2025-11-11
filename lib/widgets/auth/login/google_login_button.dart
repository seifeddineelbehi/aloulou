import 'package:flutter/material.dart';
import '../../../presentation/viewmodels/auth_viewmodel.dart';

class GoogleLoginButton extends StatelessWidget {
  final AuthViewModel authViewModel;
  final String? customText;

  const GoogleLoginButton({
    super.key,
    required this.authViewModel,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: authViewModel.isGoogleLoading 
            ? null 
            : () => authViewModel.signInWithGoogle(),
        icon: authViewModel.isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _buildGoogleIcon(),
        label: Text(
          authViewModel.isGoogleLoading
              ? 'Connexion...'
              : (customText ?? 'Continuer avec Google'),
          style: const TextStyle(
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

  Widget _buildGoogleIcon() {
    // Option 1: Si vous avez une image Google (recommandé)
    // Décommentez cette section et ajoutez google_logo.png dans assets/icons/
    /*
    return Image.asset(
      'assets/icons/google_logo.png',
      height: 20,
      width: 20,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vers l'icône personnalisée si l'image n'existe pas
        return _buildCustomGoogleIcon();
      },
    );
    */
    
    // Option 2: Icône Google personnalisée (utilisée par défaut)
    return _buildCustomGoogleIcon();
  }

  Widget _buildCustomGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}

// Painter pour créer l'icône Google
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.3;
    
    // Fond blanc (optionnel, déjà défini par le container)
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Partie bleue du G (droite)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path();
    bluePath.moveTo(centerX, centerY - radius * 0.5);
    bluePath.lineTo(centerX + radius * 0.8, centerY - radius * 0.5);
    bluePath.lineTo(centerX + radius * 0.8, centerY + radius * 0.2);
    bluePath.lineTo(centerX + radius * 0.2, centerY + radius * 0.2);
    bluePath.lineTo(centerX + radius * 0.2, centerY - radius * 0.1);
    bluePath.lineTo(centerX + radius * 0.5, centerY - radius * 0.1);
    bluePath.close();
    canvas.drawPath(bluePath, paint);
    
    // Partie rouge du G (haut gauche)
    paint.color = const Color(0xFFEA4335);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = radius * 0.3;
    paint.strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -2.4, // Position de départ
      1.6,  // Angle
      false,
      paint,
    );
    
    // Partie jaune du G (bas gauche)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      0.6, // Position de départ
      1.0, // Angle
      false,
      paint,
    );
    
    // Partie verte du G (bas)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      1.6, // Position de départ
      0.8, // Angle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}