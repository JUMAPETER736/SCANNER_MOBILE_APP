import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en', 'US'); // Default locale
  String _selectedRegion = 'United States';
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa'];
  final List<String> _regions = ['United States', 'Canada', 'United Kingdom', 'Australia', 'India', 'Malawi'];

  // This method changes the app's locale based on the selected language
  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _locale = Locale(
        language == 'Spanish' ? 'es' :
        language == 'French' ? 'fr' :
        language == 'German' ? 'de' :
        language == 'Chinese' ? 'zh' :
        language == 'Chichewa' ? 'ny' : 'en', // Default to English
        '',
      );
    });
  }

  // This method can be used to adjust region-specific settings
  void _changeRegion(String region) {
    setState(() {
      _selectedRegion = region;
      // For demonstration purposes; modify as needed
      String localeString = region == 'United States' ? 'en_US' :
      region == 'United Kingdom' ? 'en_GB' :
      region == 'Canada' ? 'en_CA' :
      region == 'Australia' ? 'en_AU' :
      region == 'India' ? 'en_IN' : 'ny_MW'; // Default to Chichewa for Malawi

      // Example of adjusting date formats, currency, etc.
      DateFormat dateFormat = DateFormat.yMMMd(localeString);
      // Use dateFormat where needed
      print("Selected Date Format: ${dateFormat.format(DateTime.now())}"); // Example usage
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
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('de', ''),
        Locale('zh', ''),
        Locale('ny', ''),
      ],
      home: LanguageRegionSettingsPage(
        selectedLanguage: _selectedLanguage,
        languages: _languages,
        onLanguageChanged: (String? language) {
          if (language != null) {
            _changeLanguage(language); // Call the change language method
          }
        },
        selectedRegion: _selectedRegion,
        regions: _regions,
        onRegionChanged: (String? region) {
          if (region != null) {
            _changeRegion(region); // Call the change region method
          }
        },
      ),
    );
  }
}

class LanguageRegionSettingsPage extends StatelessWidget {
  final String selectedLanguage;
  final List<String> languages;
  final ValueChanged<String?> onLanguageChanged; // Change to String?
  final String selectedRegion;
  final List<String> regions;
  final ValueChanged<String?> onRegionChanged; // Change to String?

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
    );
  }
}
