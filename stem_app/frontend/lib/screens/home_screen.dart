import 'dart:math' as math;
import 'dart:ui'; // Import dart:ui for ImageFilter
import 'package:flutter/material.dart';
// Assuming you have flutter_gen setup for localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter/rendering.dart'; // Not strictly needed for this code

// Convert to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Add SingleTickerProviderStateMixin for the animation
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Reduced duration slightly for a bit more dynamism
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(); // Make the animation loop

    // Use a CurvedAnimation for smoother, non-linear bubble movement
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose(); // IMPORTANT: Dispose controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access localization strings
    final l10n = AppLocalizations.of(context)!;
    // Access theme for styling
    final theme = Theme.of(context);
    // Get screen size for potentially responsive layouts
    // final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Use onPrimary color for AppBar title as it sits on primary background
            color: theme.colorScheme.onPrimary,
          ),
        ),
        // Use primary color for AppBar background for strong branding
        backgroundColor: theme.colorScheme.primary,
        // Keep elevation for a standard AppBar look, or set to 0 if preferred
        elevation: 4.0,
        // Center title can look good on home screens
        centerTitle: true,
      ),
      // Use a Stack to layer the gradient, content, and potentially other effects
      body: Stack(
        children: [
          // 1. Background Gradient Layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // Slightly adjusted opacities for a smoother blend
                  theme.colorScheme.primaryContainer.withOpacity(0.6),
                  theme.colorScheme.surface.withOpacity(0.1), // Less opaque middle
                  theme.colorScheme.secondaryContainer.withOpacity(0.6),
                ],
                begin: Alignment.topLeft, // Diagonal gradient can be nice
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Content Layer
          SafeArea( // Ensure content avoids notches/status bar
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(flex: 2), // More space at the top

                  // Animated Beaker
                  SizedBox(
                    height: 150, // Define area for animation
                    width: 150,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _BeakerPainter(
                            animationValue: _animation.value, // Pass animation value (0.0 to 1.0)
                            liquidColor: theme.colorScheme.primary.withOpacity(0.7),
                            beakerColor: theme.colorScheme.onSurface.withOpacity(0.8), // Slightly more opaque beaker
                            bubbleColor: theme.colorScheme.primaryContainer.withOpacity(0.9), // Brighter bubbles
                          ),
                          // Use size.infinite to allow the painter to fill the SizedBox
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30), // Increased spacing

                  // Welcome Message/Title
                  Text(
                    // Use a more engaging welcome if available
                    l10n.homeWelcomeMessage ?? "Explore STEM Concepts",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith( // Slightly larger headline
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600, // Bold weight
                      letterSpacing: 0.5, // Add slight spacing
                    ),
                  ),
                  const SizedBox(height: 40), // Increased spacing before buttons

                  // Card for Virtual Labs Button
                  _buildNavigationCard(
                    context: context,
                    l10n: l10n,
                    theme: theme,
                    icon: Icons.science_outlined, // Relevant icon
                    label: l10n.homeVirtualLabsButton,
                    tooltip: "Explore interactive virtual labs", // More descriptive tooltip
                    routeName: '/lab-selection',
                    // Use primary color elements for the main action
                    iconColor: theme.colorScheme.primary,
                    textColor: theme.colorScheme.onSurfaceVariant, // Readable text on blurred bg
                  ),
                  const SizedBox(height: 20), // Consistent spacing

                  // Card for Image Explanation Button
                  _buildNavigationCard(
                    context: context,
                    l10n: l10n,
                    theme: theme,
                    icon: Icons.image_search_outlined, // Use outlined icon for consistency
                    label: l10n.homeImageExplanationButton,
                    tooltip: "Get AI explanations for scientific images", // More descriptive
                    routeName: '/image-explanation',
                    // Use secondary color elements for the secondary action
                    iconColor: theme.colorScheme.secondary,
                    textColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(flex: 3), // More space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent glassmorphism navigation cards
  Widget _buildNavigationCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String tooltip,
    required String routeName,
    required Color iconColor, // Specific color for the icon
    required Color textColor, // Specific color for the text
  }) {
    // Define semi-transparent background for the card base
    final cardBackgroundColor = theme.colorScheme.surfaceVariant.withOpacity(0.2);
    // Define border color - subtle
    final borderColor = theme.colorScheme.outline.withOpacity(0.3);

    return ClipRRect( // Use ClipRRect for applying border radius to the BackdropFilter
      borderRadius: BorderRadius.circular(18.0), // Slightly larger radius
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Adjust blur intensity
        child: Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: borderColor, width: 1.5), // Add border
          ),
          child: Material( // Material for InkWell ripple effect
            color: Colors.transparent, // Make Material transparent
            child: InkWell(
              borderRadius: BorderRadius.circular(18.0), // Match border radius
              onTap: () {
                Navigator.pushNamed(context, routeName);
              },
              highlightColor: iconColor.withOpacity(0.1), // Subtle highlight
              splashColor: iconColor.withOpacity(0.15), // Ripple effect color
              child: Tooltip( // Tooltip for accessibility
                message: tooltip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center content
                    children: [
                      Icon(icon, size: 28, color: iconColor), // Use themed icon color
                      const SizedBox(width: 12), // Space between icon and text
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor, // Use themed text color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Custom Painter for Animated Beaker ---
// (Keeping the painter mostly the same, with minor color adjustments possible via theme)
class _BeakerPainter extends CustomPainter {
  final double animationValue; // Value from 0.0 to 1.0
  final Color liquidColor;
  final Color beakerColor;
  final Color bubbleColor;

  _BeakerPainter({
    required this.animationValue,
    required this.liquidColor,
    required this.beakerColor,
    required this.bubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBeaker = Paint()
      ..color = beakerColor
      ..strokeWidth = 3.0 // Slightly thicker beaker lines
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded line ends

    final paintLiquid = Paint()..color = liquidColor;
    final paintBubble = Paint()..color = bubbleColor;

    final double w = size.width;
    final double h = size.height;
    // Adjusted proportions slightly for a potentially better look
    final double beakerBottomWidth = w * 0.65;
    final double beakerTopWidth = w * 0.80;
    final double beakerHeight = h * 0.75;
    final double lipHeight = h * 0.1;
    // Make liquid level slightly dynamic/random for visual interest (optional)
    // final double liquidLevel = h * (0.55 + math.Random().nextDouble() * 0.1); // Example
    final double liquidLevel = h * 0.6; // Keep it fixed for now


    final double bottomY = h * 0.9; // Position beaker slightly higher
    final double topY = bottomY - beakerHeight;
    final double liquidY = bottomY - liquidLevel;

    // --- Draw Beaker ---
    Path beakerPath = Path();
    // Start slightly inset for rounded bottom corners effect
    double bottomInset = 5.0;
    beakerPath.moveTo(w * 0.5 - beakerBottomWidth * 0.5 + bottomInset, bottomY); // Bottom left start
    beakerPath.lineTo(w * 0.5 - beakerTopWidth * 0.5, topY + lipHeight); // Top left (below lip)
    // Lip - left (smoother curve)
    beakerPath.quadraticBezierTo(
        w * 0.5 - beakerTopWidth * 0.5 - 8, topY + lipHeight * 0.5, // Control point further out
        w * 0.5 - beakerTopWidth * 0.5, topY); // Top edge left
    beakerPath.lineTo(w * 0.5 + beakerTopWidth * 0.5, topY); // Top edge right
     // Lip - right (smoother curve)
    beakerPath.quadraticBezierTo(
        w * 0.5 + beakerTopWidth * 0.5 + 8, topY + lipHeight * 0.5, // Control point further out
        w * 0.5 + beakerTopWidth * 0.5, topY + lipHeight); // Top right (below lip)
    beakerPath.lineTo(w * 0.5 + beakerBottomWidth * 0.5 - bottomInset, bottomY); // Bottom right end
    // Bottom curve instead of line
    beakerPath.quadraticBezierTo(
        w * 0.5, bottomY + 5, // Control point below center
        w * 0.5 - beakerBottomWidth * 0.5 + bottomInset, bottomY); // Back to start

    canvas.drawPath(beakerPath, paintBeaker);
    // No separate bottom line needed if using curved bottom path

    // --- Draw Liquid ---
    // Clip the liquid drawing to the beaker path for accuracy
    canvas.save(); // Save canvas state
    canvas.clipPath(beakerPath); // Clip subsequent draws to the beaker outline

    // Calculate width at liquid level (linear interpolation)
    double t = (liquidLevel / beakerHeight); // Interpolation factor
    // Clamp t to avoid issues if liquidLevel exceeds beakerHeight visually
    t = t.clamp(0.0, 1.0);
    double liquidWidth = beakerBottomWidth + (beakerTopWidth - beakerBottomWidth) * t;

    Rect liquidRect = Rect.fromPoints(
      Offset(w * 0.5 - liquidWidth * 0.5, liquidY), // Use interpolated width
      Offset(w * 0.5 + liquidWidth * 0.5, bottomY + 1), // Extend slightly below bottomY to avoid gaps due to clipping/rounding
    );
    canvas.drawRect(liquidRect, paintLiquid);

    // Draw liquid top surface slightly curved
    Path liquidSurface = Path();
    liquidSurface.moveTo(w * 0.5 - liquidWidth * 0.5, liquidY);
    liquidSurface.quadraticBezierTo(
        w * 0.5, liquidY - 4, // Control point for curve (slightly more curve)
        w * 0.5 + liquidWidth * 0.5, liquidY);
    // Fill the surface curve area
    canvas.drawPath(liquidSurface, paintLiquid..style=PaintingStyle.fill);
    // Draw the surface line itself
    canvas.drawPath(liquidSurface, paintBeaker..style=PaintingStyle.stroke..strokeWidth=1.5);


    // --- Draw Bubbles ---
    int bubbleCount = 4; // Increased bubble count
    final random = math.Random(); // For slight variations

    for (int i = 0; i < bubbleCount; i++) {
      // Start bubbles at different horizontal positions and times
      // More randomness in horizontal position
      double horizontalOffset = (random.nextDouble() - 0.5) * (liquidWidth * 0.6);
      double timeOffset = i * (1.0 / bubbleCount) + random.nextDouble() * 0.1; // Add jitter to start time
      // Looping animation value for each bubble
      double bubbleProgress = (animationValue + timeOffset) % 1.0;

      double bubbleX = w * 0.5 + horizontalOffset;
      // Move bubble up from bottom to top of liquid
      double bubbleY = bottomY - (bubbleProgress * liquidLevel);
      // Make bubbles smaller near the bottom, larger near the top, with variation
      double bubbleRadius = 1.5 + bubbleProgress * (3.0 + random.nextDouble() * 2.0);
      // Fade bubbles out near the top and clamp the value between 0.0 and 1.0
      double bubbleOpacity = (1.0 - bubbleProgress * 1.1).clamp(0.0, 1.0).toDouble(); // Convert num to double

      // Only draw if within liquid bounds (approx) and visible
      if(bubbleY > liquidY && bubbleY < bottomY && bubbleOpacity > 0.05) {
        canvas.drawCircle(
            Offset(bubbleX, bubbleY),
            bubbleRadius,
            paintBubble..color = bubbleColor.withOpacity(bubbleOpacity));
      }
    }

    canvas.restore(); // Restore canvas state (remove clipping)
  }

  @override
  bool shouldRepaint(covariant _BeakerPainter oldDelegate) {
    // Repaint whenever animation value or colors change
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.liquidColor != liquidColor ||
           oldDelegate.beakerColor != beakerColor ||
           oldDelegate.bubbleColor != bubbleColor;
  }
}
