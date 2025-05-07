import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math; // For simple animation height calculation
import '../quiz_screen.dart'; // Import quiz screen

class DensityLabScreen extends StatefulWidget {
  const DensityLabScreen({super.key});

  @override
  State<DensityLabScreen> createState() => _DensityLabScreenState();
}

class _DensityLabScreenState extends State<DensityLabScreen> {
  double _mass = 50.0; // Initial mass in grams
  double _volume = 50.0; // Initial volume in cm³
  double _density = 1.0;

  final double _minMass = 10.0;
  final double _maxMass = 200.0;
  final double _minVolume = 10.0;
  final double _maxVolume = 200.0;

  @override
  void initState() {
    super.initState();
    _calculateDensity(); // Calculate initial density
  }

  void _calculateDensity() {
    if (_volume > 0) {
      setState(() {
        _density = _mass / _volume;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Simple animation parameters
    const double beakerHeight = 150.0;
    const double beakerWidth = 100.0;
    // Calculate fill height based on volume percentage
    final double fillHeight = beakerHeight * (_volume / _maxVolume);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labDensityTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Beaker Animation --- //
            Center(
              child: Container(
                width: beakerWidth,
                height: beakerHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: math.max(0, fillHeight), // Ensure height isn't negative
                  color: Colors.brown.withOpacity(0.6), // Grain color simulation
                  // TODO: Add CustomPaint here for better grain visuals if desired
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Mass Slider --- //
            Text('Mass: ${_mass.toStringAsFixed(1)} g', style: theme.textTheme.titleMedium),
            Semantics(
              label: "Adjust Mass",
              value: "${_mass.toStringAsFixed(1)} grams",
              child: Slider(
                value: _mass,
                min: _minMass,
                max: _maxMass,
                divisions: (_maxMass - _minMass).toInt(), // Granularity
                label: _mass.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _mass = value;
                  });
                  _calculateDensity();
                },
              ),
            ),
            const SizedBox(height: 20),

            // --- Volume Slider --- //
            Text('Volume: ${_volume.toStringAsFixed(1)} cm³', style: theme.textTheme.titleMedium),
            Semantics(
              label: "Adjust Volume",
              value: "${_volume.toStringAsFixed(1)} cubic centimeters",
              child: Slider(
                value: _volume,
                min: _minVolume,
                max: _maxVolume,
                divisions: (_maxVolume - _minVolume).toInt(),
                label: _volume.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                  _calculateDensity();
                },
              ),
            ),
            const SizedBox(height: 30),

            // --- Density Display --- //
            Center(
              child: Text(
                'Density: ${_density.toStringAsFixed(2)} g/cm³',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // --- Quiz Button --- //
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: theme.textTheme.titleLarge,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizScreen(labId: 'Density'), // Pass lab ID
                  ),
                );
              },
              child: Semantics(
                  button: true,
                  label: l10n.labQuizButton,
                  child: Text(l10n.labQuizButton)
              ),
            ),
          ],
        ),
      ),
    );
  }
} 