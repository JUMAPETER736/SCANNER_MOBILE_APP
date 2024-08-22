import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart'; // Import for localization support
import 'package:provider/provider.dart';

// Language and region provider
class LanguageRegionProvider with ChangeNotifier {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'United States';

  String get selectedLanguage => _selectedLanguage;
  String get selectedRegion => _selectedRegion;

  void changeLanguage(String newLanguage) {
    _selectedLanguage = newLanguage;
    notifyListeners();
  }

  void changeRegion(String newRegion) {
    _selectedRegion = newRegion;
    notifyListeners();
  }
}

// Main application
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageRegionProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language & Region Settings',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [
        const Locale('en', ''), // English
        const Locale('es', ''), // Spanish
        const Locale('fr', ''), // French
        const Locale('de', ''), // German
        const Locale('zh', ''), // Chinese
        // Add more locales as needed
      ],
      home: LanguageRegionSettingsPage(),
    );
  }
}

class LanguageRegionSettingsPage extends StatefulWidget {
  @override
  _LanguageRegionSettingsPageState createState() =>
      _LanguageRegionSettingsPageState();
}

class _LanguageRegionSettingsPageState
    extends State<LanguageRegionSettingsPage> {
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Chichewa'
  ];
  final List<String> _regions = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'India',
    'Malawi'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageRegionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Language & Region'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Preferred Language',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: provider.selectedLanguage,
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    provider.changeLanguage(newValue); // Change app language
                    // Add logic to change app's locale based on newValue
                    // This can be more complex, depending on how you want to implement it.
                  }
                },
              ),
              SizedBox(height: 20),
              Text(
                'Select Your Region',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: provider.selectedRegion,
                items: _regions.map((String region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    provider.changeRegion(newValue); // Change region-specific settings
                  }
                },
              ),
              SizedBox(height: 20),
              Text(
                'Tips for Language & Region Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '• Choose a language you are comfortable with.\n'
                    '• Select a region that suits your location for better localization.\n'
                    '• Check language support for specific features or content.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
