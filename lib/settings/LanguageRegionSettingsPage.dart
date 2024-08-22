import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for localization support

class LanguageRegionSettingsPage extends StatefulWidget {
  @override
  _LanguageRegionSettingsPageState createState() => _LanguageRegionSettingsPageState();
}

class _LanguageRegionSettingsPageState extends State<LanguageRegionSettingsPage> {
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
  String _selectedRegion = 'United States';
  final List<String> _regions = ['United States', 'Canada', 'United Kingdom', 'Australia', 'India'];

  // This method changes the app's locale based on the selected language
  void _changeLanguage(String language) {
    // Add logic here to change the app language
    // For example, using the Flutter Localizations package
    // You could set up a state management solution to reflect this change
    // Example: Locale(locale: language == 'Spanish' ? 'es' : 'en');
  }

  // This method can be used to adjust region-specific settings
  void _changeRegion(String region) {
    // Add logic to adjust settings based on the selected region
    // For example, modify date formats, currency, etc.
    // Example: DateFormat.yMMMd(region == 'United States' ? 'en_US' : 'en_GB');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language & Region'),
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
              value: _selectedLanguage,
              items: _languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
                _changeLanguage(_selectedLanguage); // Change app language
              },
            ),
            SizedBox(height: 20),
            Text(
              'Select Your Region',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedRegion,
              items: _regions.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRegion = newValue!;
                });
                _changeRegion(_selectedRegion); // Change region-specific settings
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
    );
  }
}
