import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../quiz_screen.dart';

enum SolutionType { water, saltwater }

class OsmosisLabScreen extends StatefulWidget {
  const OsmosisLabScreen({super.key});

  @override
  State<OsmosisLabScreen> createState() => _OsmosisLabScreenState();
}

class _OsmosisLabScreenState extends State<OsmosisLabScreen> {
  SolutionType? _selectedSolution;
  String _explanationText = "";
  // Animation properties
  double _potatoWidth = 100.0;
  double _potatoHeight = 60.0;
  final double _baseWidth = 100.0;
  final double _baseHeight = 60.0;

  void _updateSimulation(SolutionType? solutionType, AppLocalizations l10n) {
    setState(() {
      _selectedSolution = solutionType;
      switch (_selectedSolution) {
        case SolutionType.water:
          _explanationText = l10n.osmosisExplanationWater;
          _potatoWidth = _baseWidth * 1.1; // Swell slightly
          _potatoHeight = _baseHeight * 1.1;
          break;
        case SolutionType.saltwater:
          _explanationText = l10n.osmosisExplanationSaltwater;
          _potatoWidth = _baseWidth * 0.9; // Shrink slightly
          _potatoHeight = _baseHeight * 0.9;
          break;
        default:
          _explanationText = "";
          _potatoWidth = _baseWidth; // Reset to base size
          _potatoHeight = _baseHeight;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final Map<SolutionType, String> solutionLabels = {
      SolutionType.water: l10n.solutionWater,
      SolutionType.saltwater: l10n.solutionSaltwater,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labOsmosisTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Solution Selection --- //
            Semantics(
              label: l10n.osmosisSelectHint,
              child: DropdownButtonFormField<SolutionType>(
                value: _selectedSolution,
                hint: Text(l10n.osmosisSelectHint),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: SolutionType.values.map((SolutionType type) {
                  return DropdownMenuItem<SolutionType>(
                    value: type,
                    child: Text(solutionLabels[type]!),
                  );
                }).toList(),
                onChanged: (SolutionType? newValue) {
                  _updateSimulation(newValue, l10n);
                },
              ),
            ),
            const SizedBox(height: 40),

            // --- Potato Animation --- //
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: _potatoWidth,
                height: _potatoHeight,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100, // Potato color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade300, width: 1),
                ),
                curve: Curves.elasticOut, // Bouncy effect
                // Optional: Add an Image widget inside if you have assets
                // child: Image.asset('assets/images/potato_slice.png'),
              ),
            ),
            const SizedBox(height: 40),

            // --- Explanation Text --- //
            if (_explanationText.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _explanationText,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 40),

            // --- Quiz Button --- //
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: theme.textTheme.titleLarge,
              ),
              onPressed: _selectedSolution != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(labId: 'Osmosis'),
                        ),
                      );
                    }
                  : null,
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