import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Import the lab screens
import 'labs/density_lab.dart';
import 'labs/soil_ph_lab.dart';
import 'labs/osmosis_lab.dart';
import 'labs/ohms_law_lab.dart';
import 'labs/convex_lens_lab.dart';

class LabSelectionScreen extends StatelessWidget {
  const LabSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Define lab data locally for now
    final List<Map<String, dynamic>> labs = [
      {
        'title': l10n.labDensityTitle,
        'screen': const DensityLabScreen(),
      },
      {
        'title': l10n.labSoilPhTitle,
        'screen': const SoilPhLabScreen(),
      },
      {
        'title': l10n.labOsmosisTitle,
        'screen': const OsmosisLabScreen(),
      },
      {
        'title': l10n.labOhmsLawTitle ?? "Ohm's Law Lab",
        'screen': const OhmsLawLabScreen(),
      },
      {
        'title': l10n.labConvexLensTitle ?? "Convex Lens Lab",
        'screen': const ConvexLensLabScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labSelectionTitle), // Use localized title
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: labs.length,
        separatorBuilder: (context, index) => const Divider(), // Add dividers
        itemBuilder: (context, index) {
          final lab = labs[index];
          final labTitle = lab['title'] as String;
          final labScreen = lab['screen'] as Widget;

          return Semantics(
            button: true,
            label: "Navigate to ${labTitle} lab",
            child: ListTile(
              title: Text(
                labTitle,
                style: theme.textTheme.titleLarge, // Larger font for list items
              ),
              trailing: const Icon(Icons.chevron_right), // Indicate navigation
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => labScreen),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 