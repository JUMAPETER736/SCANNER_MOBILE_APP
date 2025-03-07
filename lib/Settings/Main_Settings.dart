import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/UserDetails.dart';
import 'package:scanna/Settings/ThemeDisplaySettings.dart';
import 'package:scanna/Settings/BackupSync.dart';
import 'package:scanna/Settings/AppInfo.dart';
import 'package:scanna/Settings/GradeSettings.dart';
import 'package:scanna/Settings/NotificationSettings.dart';
import 'package:scanna/Settings/QRCodeSettings.dart';
import 'package:scanna/Settings/SecuritySettings.dart';
import 'package:scanna/Home_Screens/Main_Home.dart';
class Main_Settings extends StatefulWidget {
  final User? user;

  Main_Settings({required this.user});

  @override
  _Main_SettingsState createState() => _Main_SettingsState();
}

class _Main_SettingsState extends State<Main_Settings> {
  final List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa'];
  String defaultLanguage = 'English';




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,

        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Back arrow icon
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, Home.id, (route) => false);

          },
        ),
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
                    builder: (context) => UserDetails(user: widget.user),
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
                    builder: (context) => QRCodeSettings(),
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
                    builder: (context) => GradeSettings(),
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
                    builder: (context) => BackupSync(),
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
                    builder: (context) => ThemeDisplaySettings(),
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
                    builder: (context) => NotificationSettings(),
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
                    builder: (context) => SecuritySettings(),
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
                    builder: (context) => AppInfo(),
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
