import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Generated file

import 'screens/splash_screen.dart'; // <-- Import Splash Screen
import 'screens/home_screen.dart';
import 'screens/lab_selection.dart'; // Placeholder screen
import 'screens/image_explanation.dart'; // Placeholder screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STEM App', // This title isn't usually visible once localization is set
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // Changed seed color
        useMaterial3: true,
        // Apply the custom font globally
        fontFamily: 'NotoSansDevanagari', 
        // Consider adding text theme for larger default fonts if needed
        // textTheme: TextTheme(...)
      ),
      // --- Localization Setup --- //
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('hi', ''), // Hindi, no country code
        Locale('kn', ''), // Kannada, no country code
      ],
      // Optionally, set initial locale based on device or saved preference
      // locale: Locale('hi', ''),

      // --- Navigation Setup --- //
      // Set SplashScreen as the initial route or home
      home: const SplashScreen(), // Use home for the very first screen
      routes: {
        // Define other routes if needed for named navigation from splash/home
        '/home': (context) => const HomeScreen(),
        '/lab-selection': (context) => const LabSelectionScreen(),
        '/image-explanation': (context) => const ImageExplanationScreen(),
      },
      // Use onGenerateTitle for localized app title in task switcher etc.
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
      // initialRoute: '/', // initialRoute is overridden by home
      // '/': (context) => const HomeScreen(), // Remove this if using home: SplashScreen()
    );
  }
}
