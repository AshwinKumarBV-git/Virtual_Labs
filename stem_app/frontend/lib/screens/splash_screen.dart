import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Add SingleTickerProviderStateMixin for AnimationController
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Slower rotation for subtlety
      vsync: this,
    )..repeat(); // Loop the animation

    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_controller);

    // Start fade-in animation for text/indicator
    Timer(const Duration(milliseconds: 500), () { // Slight delay for fade-in
      if (mounted) {
          setState(() {
            _opacity = 1.0;
          });
      }
    });

    // Navigate after a fixed duration
    Timer(const Duration(milliseconds: 3000), () { // Total splash duration
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[800], // Dark teal background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Atom
            AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                    return CustomPaint(
                        size: const Size(150, 150), // Size of the atom drawing area
                        painter: _AtomPainter(animationValue: _animation.value),
                    );
                },
            ),
            const SizedBox(height: 30),
            // App Title (Fading In)
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              child: Text(
                "RuralSTEM Labs",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins( // Use Poppins font
                  fontSize: 36,
                  fontWeight: FontWeight.w600, // Slightly less bold
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 25),
            // Loading Indicator (Fading In)
            AnimatedOpacity(
               opacity: _opacity,
               duration: const Duration(seconds: 2),
               curve: Curves.easeIn,
               child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent[100]!),
                  ),
               ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Animated Atom
class _AtomPainter extends CustomPainter {
  final double animationValue; // Current angle from animation (0 to 2*pi)

  _AtomPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8; // Overall radius based on size
    final nucleusRadius = radius * 0.15;
    final electronRadius = radius * 0.08;
    final orbitStrokeWidth = 2.0;

    final nucleusPaint = Paint()..color = Colors.white;
    final electronPaint = Paint()..color = Colors.yellowAccent;
    final orbitPaint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.5)
      ..strokeWidth = orbitStrokeWidth
      ..style = PaintingStyle.stroke;

    // Draw nucleus
    canvas.drawCircle(center, nucleusRadius, nucleusPaint);

    // Draw 3 elliptical orbits and electrons
    int numberOfOrbits = 3;
    for (int i = 0; i < numberOfOrbits; i++) {
      double angleOffset = (2 * math.pi / numberOfOrbits) * i;
      double currentAngle = animationValue + angleOffset;

      // Make orbits elliptical and rotate them
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi / 4 * i); // Rotate each orbit differently
      Rect orbitRect = Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.8 * 2);
      canvas.drawOval(orbitRect, orbitPaint);

      // Calculate electron position on the rotated ellipse
      double electronX = orbitRect.width / 2 * math.cos(currentAngle);
      double electronY = orbitRect.height / 2 * math.sin(currentAngle);

      // Draw electron
      canvas.drawCircle(Offset(electronX, electronY), electronRadius, electronPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AtomPainter oldDelegate) {
    // Repaint whenever the animation value changes
    return oldDelegate.animationValue != animationValue;
  }
} 