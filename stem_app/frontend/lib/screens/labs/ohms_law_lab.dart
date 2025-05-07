import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../quiz_screen.dart'; // Import QuizScreen

class OhmsLawLabScreen extends StatefulWidget {
  const OhmsLawLabScreen({super.key});

  @override
  State<OhmsLawLabScreen> createState() => _OhmsLawLabScreenState();
}

class _OhmsLawLabScreenState extends State<OhmsLawLabScreen> {
  double _voltage = 6.0; // Initial voltage
  double _resistance = 100.0; // Initial resistance (start > 0)
  double _current = 0.0; // Calculated current

  // Chart details
  final double _maxVoltage = 12.0;
  final double _minResistance = 10.0;
  final double _maxResistance = 500.0;
  // Calculate max possible current for chart axis scaling
  final double _maxPossibleCurrent = 12.0 / 10.0; // V_max / R_min

  @override
  void initState() {
    super.initState();
    _calculateCurrent(); // Calculate initial current
  }

  void _calculateCurrent() {
    // Avoid division by zero, although slider min should prevent it
    if (_resistance <= 0) {
      _current = double.infinity; // Or handle as error
    } else {
      _current = _voltage / _resistance;
    }
  }

  // --- Chart Data Generation ---
  LineChartData _createChartData(AppLocalizations l10n, ThemeData theme) {
    // Calculate max current for the *current* resistance to draw the line V=IR
    double currentResistanceMaxCurrent = _resistance <= 0 ? 0 : _maxVoltage / _resistance;

    List<FlSpot> spots = [
      const FlSpot(0, 0), // Start at origin
      FlSpot(currentResistanceMaxCurrent, _maxVoltage), // Line defined by V=IR
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 2, // Grid lines every 2V
        verticalInterval: 0.2, // Grid lines every 0.2A
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 0.5, // Labels every 0.5A
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8.0,
              child: Text(value.toStringAsFixed(1)),
            ),
          ),
          axisNameWidget: Text(l10n.xAxisLabelCurrent ?? "Current (A)"),
          axisNameSize: 22,
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 2, // Labels every 2V
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8.0,
              child: Text(value.toStringAsFixed(0)),
            ),
          ),
          axisNameWidget: Text(l10n.yAxisLabelVoltage ?? "Voltage (V)"),
          axisNameSize: 22,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      minX: 0,
      maxX: _maxPossibleCurrent + 0.1, // Max possible current + buffer
      minY: 0,
      maxY: _maxVoltage, // Max voltage from slider
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false, // Straight line V=IR
          color: theme.colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false), // Hide dots on the line
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData( // Optional: Tooltips
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => theme.colorScheme.secondaryContainer,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              return LineTooltipItem(
                '${flSpot.x.toStringAsFixed(2)} A\n${flSpot.y.toStringAsFixed(1)} V',
                 TextStyle(color: theme.colorScheme.onSecondaryContainer),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Calculate semantic values for sliders
    final String voltageSemanticValue = "${_voltage.toStringAsFixed(1)} ${l10n.voltageUnit}";
    final String resistanceSemanticValue = "${_resistance.toStringAsFixed(0)} ${l10n.resistanceUnit}";

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labOhmsLawTitle ?? "Ohm's Law Lab"),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Explanation ---
            Text(l10n.ohmsLawExplanation ?? "Ohm's Law (V=IR) describes the relationship between voltage (V), current (I), and resistance (R).", style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),

            // --- Sliders ---
            Text('${l10n.voltageLabel ?? "Voltage"}: ${_voltage.toStringAsFixed(1)} ${l10n.voltageUnit ?? "V"}', style: theme.textTheme.titleMedium),
            Slider(
              value: _voltage,
              min: 0.0,
              max: _maxVoltage,
              divisions: 120, // 0.1V steps
              label: _voltage.toStringAsFixed(1),
              semanticFormatterCallback: (double value) => voltageSemanticValue,
              onChanged: (value) {
                setState(() {
                  _voltage = value;
                  _calculateCurrent();
                });
              },
            ),
            const SizedBox(height: 10),
            Text('${l10n.resistanceLabel ?? "Resistance"}: ${_resistance.toStringAsFixed(0)} ${l10n.resistanceUnit ?? "Ω"}', style: theme.textTheme.titleMedium),
            Slider(
              value: _resistance,
              min: _minResistance,
              max: _maxResistance,
              divisions: 490, // 1 Ohm steps
              label: _resistance.toStringAsFixed(0),
              semanticFormatterCallback: (double value) => resistanceSemanticValue,
              onChanged: (value) {
                setState(() {
                  _resistance = value;
                  _calculateCurrent();
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Display Calculated Current ---
            Center(
              child: Text(
                '${l10n.currentLabel ?? "Current"}: ${_current.toStringAsFixed(3)} ${l10n.currentUnit ?? "A"}',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // --- Circuit Diagram ---
            Center(
                child: Text(l10n.circuitDiagramLabel ?? "Circuit Diagram",
                    style: theme.textTheme.titleMedium)),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Semantics(
                label: l10n.circuitDiagramLabel ?? "Simple circuit diagram",
                child: CustomPaint(
                  painter: _CircuitPainter(color: theme.colorScheme.primary),
                  size: const Size(double.infinity, 100),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- V vs I Graph ---
            Center(
                child: Text(l10n.graphTitleVvsI ?? "Voltage vs. Current Graph",
                    style: theme.textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 300, // Give the chart adequate height
              child: Semantics(
                label: l10n.graphSemanticsLabel ?? "Line chart showing Voltage versus Current for the selected resistance.",
                child: LineChart(
                  _createChartData(l10n, theme),
                  key: const Key('ohms_law_chart'),
                  // duration: const Duration(milliseconds: 150), // Optional animation
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
                          const QuizScreen(labId: 'ohms_law')), // Use constant constructor
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

// --- Custom Painter for Circuit Diagram ---
class _CircuitPainter extends CustomPainter {
  final Color color;
  _CircuitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;
    final double margin = 20.0;
    final double batteryWidth = 20.0;
    final double batteryHeight = 40.0;
    final double resistorWidth = 40.0;
    final double resistorHeight = 20.0;

    // Battery position (left side)
    final double batteryX = margin;
    final double batteryY = h / 2 - batteryHeight / 2;

    // Resistor position (right side)
    final double resistorX = w - margin - resistorWidth;
    final double resistorY = h / 2 - resistorHeight / 2;

    // Draw battery symbol (+) and (-) lines
    canvas.drawLine(Offset(batteryX, batteryY), Offset(batteryX, batteryY + batteryHeight), paint); // Long line (+)
    canvas.drawLine(Offset(batteryX + batteryWidth, batteryY + batteryHeight * 0.2), Offset(batteryX + batteryWidth, batteryY + batteryHeight * 0.8), paint..strokeWidth = 4); // Short line (-)

    // Draw resistor symbol (zigzag)
    Path resistorPath = Path();
    resistorPath.moveTo(resistorX, resistorY + resistorHeight / 2);
    resistorPath.lineTo(resistorX + resistorWidth * 0.15, resistorY);
    resistorPath.lineTo(resistorX + resistorWidth * 0.35, resistorY + resistorHeight);
    resistorPath.lineTo(resistorX + resistorWidth * 0.55, resistorY);
    resistorPath.lineTo(resistorX + resistorWidth * 0.75, resistorY + resistorHeight);
    resistorPath.lineTo(resistorX + resistorWidth * 0.9, resistorY);
    resistorPath.lineTo(resistorX + resistorWidth, resistorY + resistorHeight / 2);
    canvas.drawPath(resistorPath, paint..strokeWidth = 2);


    // Draw connecting wires
    // Top wire
    canvas.drawLine(Offset(batteryX + batteryWidth, batteryY + batteryHeight * 0.2), Offset(resistorX, batteryY + batteryHeight * 0.2), paint);
    // Bottom wire
    canvas.drawLine(Offset(batteryX + batteryWidth, batteryY + batteryHeight * 0.8), Offset(resistorX, batteryY + batteryHeight * 0.8), paint);

     // Connection points to battery/resistor (adjust based on line positions)
    canvas.drawLine(Offset(resistorX, batteryY + batteryHeight * 0.2), Offset(resistorX, resistorY + 0), paint); // Top connect to resistor
    canvas.drawLine(Offset(resistorX, batteryY + batteryHeight * 0.8), Offset(resistorX, resistorY + resistorHeight), paint); // Bottom connect to resistor

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Static diagram doesn't need repaint unless color changes
  }
} 