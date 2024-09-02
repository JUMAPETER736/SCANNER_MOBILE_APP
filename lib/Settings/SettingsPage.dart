import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/UserDetailsPage.dart';
import 'package:scanna/Settings/ThemeDisplaySettingsPage.dart';
import 'package:scanna/Settings/BackupSyncPage.dart';
import 'package:scanna/Settings/AppInfoPage.dart';
import 'package:scanna/Settings/GradeSettingsPage.dart';
import 'package:scanna/Settings/NotificationSettingsPage.dart';
import 'package:scanna/Settings/QRCodeSettingsPage.dart';
import 'package:scanna/Settings/SecuritySettingsPage.dart';

class SettingsPage extends StatefulWidget {
  final User? user;

  SettingsPage({required this.user});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa'];
  String defaultLanguage = 'English';

  void _onLanguageChanged(String? newLanguage) {
    setState(() {
      defaultLanguage = newLanguage ?? defaultLanguage;
    });
  }

  void _onRegionChanged(String? newRegion) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSettingsItem(
              title: 'User Details',
              subtitle: 'Profile, Email, and more',
              icon: Icons.person,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(user: widget.user),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'QR Code Settings',
              subtitle: 'Scan mode, camera settings, and more',
              icon: Icons.qr_code,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QRCodeSettingsPage(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'Grade Settings',
              subtitle: 'Customize grading scale and display',
              icon: Icons.grade,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GradeSettingsPage(),
                  ),
                );
              },
            ),
   
            _buildSettingsItem(
              title: 'Backup & Sync',
              subtitle: 'Cloud Backup and Data Synchronization',
              icon: Icons.backup,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BackupSyncPage(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'Theme & Display',
              subtitle: 'App Theme, font size, and layout',
              icon: Icons.color_lens,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ThemeDisplaySettingsPage(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'Notification Settings',
              subtitle: 'Manage Notifications preferences',
              icon: Icons.notifications,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsPage(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'Security Settings',
              subtitle: 'Manage Security options',
              icon: Icons.security,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SecuritySettingsPage(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              title: 'App Information',
              subtitle: 'Version, licenses, and support',
              icon: Icons.info,
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
      ),
    );
  }

  Widget _buildSettingsItem({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 16)),
        leading: Icon(icon, color: Colors.blueAccent, size: 28),
        onTap: onTap,
      ),
    );
  }
}
