import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../quiz_screen.dart'; // Import QuizScreen

class ConvexLensLabScreen extends StatefulWidget {
  const ConvexLensLabScreen({super.key});

  @override
  State<ConvexLensLabScreen> createState() => _ConvexLensLabScreenState();
}

class _ConvexLensLabScreenState extends State<ConvexLensLabScreen> {
  // --- Fixed Lens Parameter ---
  final double _focalLength = 15.0; // Fixed focal length in cm

  // --- State Variables ---
  late double _objectDistance; // Initialized in initState
  double _imageDistance = 0.0;  // Calculated image distance in cm
  late double _minObjectDistance;
  late double _maxObjectDistance;

  @override
  void initState() {
    super.initState();
    // Set slider limits based on focal length
    _minObjectDistance = _focalLength * 1.1; // Slightly beyond F
    _maxObjectDistance = _focalLength * 5.0;
    // Set initial object distance (e.g., at 2F)
    _objectDistance = _focalLength * 2.0;
    _calculateImageDistance(); // Calculate initial image distance
  }

  void _calculateImageDistance() {
    // Lens formula: 1/v = 1/f - 1/u
    // Ensure objectDistance is not exactly focalLength to avoid division by zero
    if ((_objectDistance - _focalLength).abs() < 0.001) {
        // Handle case where object is at F (image at infinity) - display differently?
        _imageDistance = double.infinity;
    } else {
        _imageDistance = (_focalLength * _objectDistance) / (_objectDistance - _focalLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final String cmUnit = l10n.cmUnit ?? "cm";

    // Semantic label for slider
    final String objectDistanceSemanticValue = "${_objectDistance.toStringAsFixed(1)} $cmUnit";

    // Semantic label for the diagram
    final String diagramSemantics = l10n.rayDiagramSemanticsLabel(
        _objectDistance.toStringAsFixed(1),
        _imageDistance.isFinite ? _imageDistance.toStringAsFixed(1) : "infinity",
        _focalLength.toStringAsFixed(1)
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labConvexLensTitle ?? "Convex Lens Lab"),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Explanation ---
            Text(l10n.convexLensExplanation ?? "Use the slider to change the object distance (u). The ray diagram shows how a real, inverted image is formed by a convex lens when u > f. The image distance (v) is calculated using the lens formula: 1/f = 1/v + 1/(-u) (using real is positive convention).", style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),

            // --- Fixed Focal Length Display ---
             Center(
              child: Text(
                '${l10n.focalLengthLabel ?? "Lens Focal Length (f)"}: ${_focalLength.toStringAsFixed(1)} $cmUnit',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),

            // --- Object Distance Slider ---
            Text('${l10n.objectDistanceLabel ?? "Object Distance (u)"}: ${_objectDistance.toStringAsFixed(1)} $cmUnit', style: theme.textTheme.titleMedium),
            Slider(
              value: _objectDistance,
              min: _minObjectDistance,
              max: _maxObjectDistance,
              divisions: 100, // Adjust for desired granularity
              label: _objectDistance.toStringAsFixed(1),
              semanticFormatterCallback: (double value) => objectDistanceSemanticValue,
              onChanged: (value) {
                setState(() {
                  _objectDistance = value;
                  _calculateImageDistance();
                });
              },
            ),
            const SizedBox(height: 10),

            // --- Display Calculated Image Distance ---
            Center(
              child: Text(
                 _imageDistance.isFinite
                   ? '${l10n.imageDistanceLabel ?? "Image Distance (v)"}: ${_imageDistance.toStringAsFixed(1)} $cmUnit'
                   : '${l10n.imageDistanceLabel ?? "Image Distance (v)"}: Infinity (Object at F)',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 20),

             // --- Ray Diagram --- //
            Center(
                child: Text(l10n.rayDiagramLabel ?? "Ray Diagram",
                    style: theme.textTheme.titleMedium)),
            const SizedBox(height: 8),
            Container(
              height: 300, // Allocate good height for the diagram
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3)
              ),
              child: Semantics(
                label: diagramSemantics,
                child: ClipRect( // Prevent drawing outside bounds
                  child: CustomPaint(
                    painter: _LensRayDiagramPainter(
                      focalLength: _focalLength,
                      objectDistance: _objectDistance,
                      imageDistance: _imageDistance,
                      objectHeight: 20.0, // Example object height for drawing
                      axisColor: theme.colorScheme.onSurfaceVariant,
                      lensColor: theme.colorScheme.secondary,
                      rayColor: theme.colorScheme.primary,
                      imageColor: theme.colorScheme.tertiary,
                    ),
                    size: const Size(double.infinity, 300),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Quiz Button ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: theme.textTheme.titleLarge,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const QuizScreen(labId: 'convex_lens')),
                );
              },
              child: Text(l10n.labQuizButton ?? "Take Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for Ray Diagram ---
class _LensRayDiagramPainter extends CustomPainter {
  final double focalLength;
  final double objectDistance; // u (always positive input)
  final double imageDistance;  // v (can be positive/negative/infinity)
  final double objectHeight;   // h_o
  final Color axisColor;
  final Color lensColor;
  final Color rayColor;
  final Color imageColor;

  _LensRayDiagramPainter({
    required this.focalLength,
    required this.objectDistance,
    required this.imageDistance,
    required this.objectHeight,
    required this.axisColor,
    required this.lensColor,
    required this.rayColor,
    required this.imageColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()
      ..color = axisColor
      ..strokeWidth = 1.0;
    final paintLens = Paint()
      ..color = lensColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintRay = Paint()
      ..color = rayColor
      ..strokeWidth = 1.5;
    final paintImage = Paint()
      ..color = imageColor
      ..strokeWidth = 2.0;
    final paintObject = Paint()
      ..color = rayColor // Use ray color for object
      ..strokeWidth = 2.0;

    final double w = size.width;
    final double h = size.height;
    final double opticalCentreX = w / 2;
    final double axisY = h / 2;

    // Scaling: Determine a suitable scale factor to fit the diagram
    // Fit the maximum extent (object or image furthest away) within the canvas width
    // Consider max object distance and potentially large image distance
    double maxExtent = math.max(objectDistance, imageDistance.isFinite ? imageDistance.abs() : objectDistance) * 1.2; // Add buffer
    maxExtent = math.max(maxExtent, focalLength * 2.5); // Ensure F points are visible
    double scale = (w * 0.9) / (2 * maxExtent); // Scale based on fitting max extent in 90% of width

    // Function to convert world X coordinate to canvas X
    double toCanvasX(double worldX) => opticalCentreX + worldX * scale;
    // Function to convert world Y coordinate to canvas Y (Y is inverted in canvas)
    double toCanvasY(double worldY) => axisY - worldY * scale; // Use same scale for simplicity

    // --- Draw Principal Axis ---
    canvas.drawLine(Offset(0, axisY), Offset(w, axisY), paintAxis);

    // --- Draw Convex Lens ---
    double lensHeight = h * 0.6;
    canvas.drawLine(Offset(opticalCentreX, axisY - lensHeight / 2), Offset(opticalCentreX, axisY + lensHeight / 2), paintLens);
    // Arrow heads (simple triangles)
    Path lensArrows = Path();
    lensArrows.moveTo(opticalCentreX, axisY - lensHeight / 2); // Top arrow
    lensArrows.lineTo(opticalCentreX - 5, axisY - lensHeight / 2 + 8);
    lensArrows.moveTo(opticalCentreX, axisY - lensHeight / 2);
    lensArrows.lineTo(opticalCentreX + 5, axisY - lensHeight / 2 + 8);
    lensArrows.moveTo(opticalCentreX, axisY + lensHeight / 2); // Bottom arrow
    lensArrows.lineTo(opticalCentreX - 5, axisY + lensHeight / 2 - 8);
    lensArrows.moveTo(opticalCentreX, axisY + lensHeight / 2);
    lensArrows.lineTo(opticalCentreX + 5, axisY + lensHeight / 2 - 8);
    canvas.drawPath(lensArrows, paintLens..style = PaintingStyle.stroke);

    // --- Mark Optical Centre (O) and Focal Points (F) ---
    TextPainter(text: TextSpan(text: 'O', style: TextStyle(color: axisColor)), textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(opticalCentreX - 4, axisY + 4));
    double f1X = toCanvasX(-focalLength);
    double f2X = toCanvasX(focalLength);
    canvas.drawCircle(Offset(f1X, axisY), 3, paintAxis..style = PaintingStyle.fill);
    TextPainter(text: TextSpan(text: 'F', style: TextStyle(color: axisColor)), textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(f1X - 4, axisY + 4));
    canvas.drawCircle(Offset(f2X, axisY), 3, paintAxis..style = PaintingStyle.fill);
    TextPainter(text: TextSpan(text: 'F', style: TextStyle(color: axisColor)), textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(f2X - 4, axisY + 4));

    // --- Draw Object ---
    double objCanvasX = toCanvasX(-objectDistance);
    double objTopCanvasY = toCanvasY(objectHeight);
    // Draw as an arrow
    canvas.drawLine(Offset(objCanvasX, axisY), Offset(objCanvasX, objTopCanvasY), paintObject);
    Path objArrow = Path();
    objArrow.moveTo(objCanvasX, objTopCanvasY);
    objArrow.lineTo(objCanvasX - 4, objTopCanvasY + 6);
    objArrow.moveTo(objCanvasX, objTopCanvasY);
    objArrow.lineTo(objCanvasX + 4, objTopCanvasY + 6);
    canvas.drawPath(objArrow, paintObject);

    // --- Draw Rays --- //
    // Ray 1: Parallel to axis, then through F2
    canvas.drawLine(Offset(objCanvasX, objTopCanvasY), Offset(opticalCentreX, objTopCanvasY), paintRay);
    if (imageDistance.isFinite) {
        canvas.drawLine(Offset(opticalCentreX, objTopCanvasY), Offset(toCanvasX(imageDistance), toCanvasY(0)), paintRay); // Approximate path towards image top - simplified
    }
    // Actual refracted ray path for drawing: from lens point to image top
    double imgCanvasX = toCanvasX(imageDistance);
    double imgHeight = imageDistance.isFinite ? -objectHeight * (imageDistance / objectDistance) : 0; // Magnification M = v/u = hi/ho => hi = ho*(v/u)
    double imgTopCanvasY = toCanvasY(imgHeight);

    if (imageDistance.isFinite) {
         // Correct Ray 1 refraction:
         canvas.drawLine(Offset(opticalCentreX, objTopCanvasY), Offset(imgCanvasX, imgTopCanvasY), paintRay);

        // Ray 2: Through Optical Centre O (undeviated)
        canvas.drawLine(Offset(objCanvasX, objTopCanvasY), Offset(imgCanvasX, imgTopCanvasY), paintRay);
    }

    // --- Draw Image (if real) ---
    if (imageDistance.isFinite && imageDistance > 0) { // Only draw real images
      // Draw as inverted arrow
      canvas.drawLine(Offset(imgCanvasX, axisY), Offset(imgCanvasX, imgTopCanvasY), paintImage);
      Path imgArrow = Path();
      imgArrow.moveTo(imgCanvasX, imgTopCanvasY);
      imgArrow.lineTo(imgCanvasX - 4, imgTopCanvasY - 6);
      imgArrow.moveTo(imgCanvasX, imgTopCanvasY);
      imgArrow.lineTo(imgCanvasX + 4, imgTopCanvasY - 6);
      canvas.drawPath(imgArrow, paintImage);
    }

  }

  @override
  bool shouldRepaint(covariant _LensRayDiagramPainter oldDelegate) {
    // Repaint if any relevant parameter changes
    return oldDelegate.focalLength != focalLength ||
           oldDelegate.objectDistance != objectDistance ||
           oldDelegate.imageDistance != imageDistance ||
           oldDelegate.objectHeight != objectHeight ||
           oldDelegate.axisColor != axisColor ||
           oldDelegate.lensColor != lensColor ||
           oldDelegate.rayColor != rayColor ||
           oldDelegate.imageColor != imageColor;
  }
} 