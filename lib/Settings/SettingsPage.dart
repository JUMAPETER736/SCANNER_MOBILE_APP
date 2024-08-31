import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/UserDetailsPage.dart';
import 'package:scanna/Settings/ThemeDisplaySettingsPage.dart';
import 'package:scanna/Settings/BackupSyncPage.dart';
import 'package:scanna/Settings/AppInfoPage.dart';
import 'package:scanna/Settings/GradeSettingsPage.dart';
import 'package:scanna/Settings/LanguageRegionSettingsPage.dart';
import 'package:scanna/Settings/NotificationSettingsPage.dart';
import 'package:scanna/Settings/QRCodeSettingsPage.dart';
import 'package:scanna/Settings/SecuritySettingsPage.dart';

class SettingsPage extends StatefulWidget {
  final User? user;

  SettingsPage({required this.user}); // Constructor requires a User object

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa']; // Supported languages
  String defaultLanguage = 'English'; // Set a default language

  // Method to handle language change
  void _onLanguageChanged(String? newLanguage) {
    setState(() {
      defaultLanguage = newLanguage ?? defaultLanguage; // Update the selected language
    });
  }

  // Placeholder method for region change
  void _onRegionChanged(String? newRegion) {
    // Handle region-specific settings here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'), 
        automaticallyImplyLeading: false, 
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Padding around the list
        children: [

          Divider(),
          // User Details
          ListTile(
            title: Text('User Details'), // Title of the list item
            leading: Icon(Icons.person), // Icon on the left
            subtitle: Text('Profile, Email, and more'), // Subtitle
            onTap: () {
              // Navigate to UserDetailsPage when tapped
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetailsPage(user: widget.user), // Pass user object to UserDetailsPage
                ),
              );
            },
          ),
          Divider(), // Divider between list items

          // QR Code Settings
          ListTile(
            title: Text('QR Code Settings'),
            subtitle: Text('Scan mode, camera settings, and more'),
            leading: Icon(Icons.qr_code),
            onTap: () {
              // Navigate to QRCodeSettingsPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QRCodeSettingsPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),

          // Grade Settings
          ListTile(
            title: Text('Grade Settings'),
            subtitle: Text('Customize grading scale and display'),
            leading: Icon(Icons.grade),
            onTap: () {
              // Navigate to GradeSettingsPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GradeSettingsPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),

          // Language & Region Settings
          ListTile(
            title: Text('Language & Region'),
            subtitle: Text('Language selection and Regional settings'),
            leading: Icon(Icons.language),
            onTap: () {
              // Navigate to LanguageRegionSettingsPage with required parameters
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LanguageRegionSettingsPage(
                    languages: languages, // Pass the languages list here
                    selectedLanguage: defaultLanguage, // Pass the selected language
                    onLanguageChanged: _onLanguageChanged, // Pass the callback for language changes
                    selectedRegion: 'United States', // Pass the selected region
                    regions: ['United States', 'Canada', 'United Kingdom', 'Australia', 'India', 'Malawi'], // Pass the regions list
                    onRegionChanged: _onRegionChanged, // Pass the callback for region changes
                  ),
                ),
              );
            },
          ),
          Divider(),

          // Backup & Sync
          ListTile(
            title: Text('Backup & Sync'),
            subtitle: Text('Cloud Backup and Data Synchronization'),
            leading: Icon(Icons.backup),
            onTap: () {
              // Navigate to BackupSyncPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BackupSyncPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),

          // Theme & Display Settings
          ListTile(
            title: Text('Theme & Display'),
            subtitle: Text('App Theme, font size, and layout'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              // Navigate to ThemeDisplaySettingsPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ThemeDisplaySettingsPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),



          // Notification Settings
          ListTile(
            title: Text('Notification Settings'),
            subtitle: Text('Manage Notifications preferences'),
            leading: Icon(Icons.notifications),
            onTap: () {
              // Navigate to NotificationSettingsPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),

          // Security Settings
          ListTile(
            title: Text('Security Settings'),
            subtitle: Text('Manage Security options'),
            leading: Icon(Icons.security),
            onTap: () {
              // Navigate to SecuritySettingsPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SecuritySettingsPage(), // Ensure this page exists
                ),
              );
            },
          ),
          Divider(),

          ListTile(
            title: Text('App Information'),
            subtitle: Text('Version, licenses, and support'),
            leading: Icon(Icons.info),
            onTap: () {
              // Navigate to AppInfoPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppInfoPage(), // Ensure this page exists
                ),
              );
            },
          ),

          Divider(),
        ],
      ),
    );
  }
}
