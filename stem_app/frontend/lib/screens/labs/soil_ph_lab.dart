import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../quiz_screen.dart';

// Define keys for soil types to avoid magic strings
enum SoilType { acidic, neutral, basic }

class SoilPhLabScreen extends StatefulWidget {
  const SoilPhLabScreen({super.key});

  @override
  State<SoilPhLabScreen> createState() => _SoilPhLabScreenState();
}

class _SoilPhLabScreenState extends State<SoilPhLabScreen> {
  SoilType? _selectedSoilType; // Start with null
  Color _indicatorColor = Colors.grey.shade300; // Initial neutral color
  String _explanationText = "";

  void _updateIndicator(SoilType? soilType, AppLocalizations l10n) {
    setState(() {
      _selectedSoilType = soilType;
      switch (_selectedSoilType) {
        case SoilType.acidic:
          _indicatorColor = Colors.yellow.shade600;
          _explanationText = l10n.soilPhExplanationAcidic;
          break;
        case SoilType.neutral:
          _indicatorColor = Colors.yellow.shade600; // Similar to acidic for turmeric
          _explanationText = l10n.soilPhExplanationNeutral;
          break;
        case SoilType.basic:
          _indicatorColor = Colors.red.shade700;
          _explanationText = l10n.soilPhExplanationBasic;
          break;
        default:
          _indicatorColor = Colors.grey.shade300; // Default/unselected color
          _explanationText = ""; // Clear explanation
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Map enum values to localized strings for dropdown
    final Map<SoilType, String> soilTypeLabels = {
      SoilType.acidic: l10n.soilTypeAcidic,
      SoilType.neutral: l10n.soilTypeNeutral,
      SoilType.basic: l10n.soilTypeBasic,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labSoilPhTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Soil Type Selection --- //
            Semantics(
              label: l10n.soilPhSelectHint,
              child: DropdownButtonFormField<SoilType>(
                value: _selectedSoilType,
                hint: Text(l10n.soilPhSelectHint),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: SoilType.values.map((SoilType type) {
                  return DropdownMenuItem<SoilType>(
                    value: type,
                    child: Text(soilTypeLabels[type]!),
                  );
                }).toList(),
                onChanged: (SoilType? newValue) {
                  _updateIndicator(newValue, l10n);
                },
              ),
            ),
            const SizedBox(height: 30),

            // --- Indicator Animation --- //
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: _indicatorColor,
                  border: Border.all(color: Colors.grey.shade500, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 30),

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
              // Enable button only if a soil type is selected
              onPressed: _selectedSoilType != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(labId: 'Soil_pH'),
                        ),
                      );
                    }
                  : null, // Disable button if no selection
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