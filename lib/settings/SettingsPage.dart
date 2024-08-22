import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/settings/AppInfoPage.dart';
import 'package:scanna/settings/BackupSyncPage.dart';
  
class SettingsPage extends StatelessWidget {
  final User? user;

  SettingsPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Details
          ListTile(
            title: Text('User Details'),
            leading: Icon(Icons.person),
            subtitle: Text('Profile, Email, and more'),
            onTap: () {
              // Navigate to User Details page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetailsPage(user: user),
                ),
              );
            },
          ),
          Divider(),

          // QR Code Settings
          ListTile(
            title: Text('QR Code Settings'),
            subtitle: Text('Scan mode, camera settings, and more'),
            leading: Icon(Icons.qr_code),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QRCodeSettingsPage(),
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GradeSettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // Notification Settings
          ListTile(
            title: Text('Notification Settings'),
            subtitle: Text('Manage push and email notifications'),
            leading: Icon(Icons.notifications),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // Security Settings
          ListTile(
            title: Text('Security Settings'),
            subtitle: Text('App lock, data encryption, and more'),
            leading: Icon(Icons.lock),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SecuritySettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // Language & Region Settings
          ListTile(
            title: Text('Language & Region'),
            subtitle: Text('Language selection and regional settings'),
            leading: Icon(Icons.language),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LanguageRegionSettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // Backup & Sync
          ListTile(
            title: Text('Backup & Sync'),
            subtitle: Text('Cloud backup and data synchronization'),
            leading: Icon(Icons.backup),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BackupSyncPage(),
                ),
              );
            },
          ),
          Divider(),

          // Theme & Display Settings
          ListTile(
            title: Text('Theme & Display'),
            subtitle: Text('App theme, font size, and layout'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ThemeDisplaySettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // App Information
          ListTile(
            title: Text('App Information'),
            subtitle: Text('Version, licenses, and support'),
            leading: Icon(Icons.info),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppInfoPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}



