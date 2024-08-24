import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en', 'US'); // Default locale

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('zh', 'CN'),
        Locale('ny', 'MW'),
      ],
      home: LanguageRegionSettingsPage(
        selectedLanguage: 'English',
        languages: ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa'],
        onLanguageChanged: (String? language) {
          if (language != null) {
            Locale newLocale = Locale(
              language == 'Spanish' ? 'es' :
              language == 'French' ? 'fr' :
              language == 'German' ? 'de' :
              language == 'Chinese' ? 'zh' :
              language == 'Chichewa' ? 'ny' : 'en',
              '',
            );
            MyApp.setLocale(context, newLocale); // Change app language
          }
        },
        selectedRegion: 'United States',
        regions: ['United States', 'Canada', 'United Kingdom', 'Australia', 'India', 'Malawi'],
        onRegionChanged: (String? region) {
          // Handle region-specific settings here if needed
        },
      ),
    );
  }
}

class LanguageRegionSettingsPage extends StatelessWidget {
  final String selectedLanguage;
  final List<String> languages;
  final ValueChanged<String?> onLanguageChanged; // Callback for language change
  final String selectedRegion;
  final List<String> regions;
  final ValueChanged<String?> onRegionChanged; // Callback for region change

  LanguageRegionSettingsPage({
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
    required this.selectedRegion,
    required this.regions,
    required this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language & Region Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Preferred Language',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedLanguage,
              items: languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: onLanguageChanged, // Change app language
            ),
            SizedBox(height: 20),
            Text(
              'Select Your Region',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedRegion,
              items: regions.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: onRegionChanged, // Change region-specific settings
            ),
          ],
        ),
      ),
    );
  }
}
