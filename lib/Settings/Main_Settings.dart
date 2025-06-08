import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/User_Details.dart';
import 'package:scanna/Settings/Theme_Display_Settings.dart';
import 'package:scanna/Settings/Backup_Sync.dart';
import 'package:scanna/Settings/App_Info.dart';
import 'package:scanna/Settings/Grade_Settings.dart';
import 'package:scanna/Settings/Notification_Settings.dart';
import 'package:scanna/Settings/QR_Code_Settings.dart';
import 'package:scanna/Settings/Security_Settings.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, Main_Home.id, (route) => false);
          },
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _buildSettingsItem(
                  title: 'User Details',
                  subtitle: 'Profile, Email, and more',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => User_Details(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  title: 'Security Settings',
                  subtitle: 'Manage Security options',
                  icon: Icons.security_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Security_Settings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // App Features Section
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _buildSettingsItem(
                  title: 'QR Code Settings',
                  subtitle: 'Scan mode, camera settings, and more',
                  icon: Icons.qr_code_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QR_Code_Settings(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  title: 'Grade Settings',
                  subtitle: 'Customize grading scale and display',
                  icon: Icons.grade_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Grade_Settings(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  title: 'Notifications',
                  subtitle: 'Message, group & call tones',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Notification_Settings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Data and Storage Section
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _buildSettingsItem(
                  title: 'Backup & Sync',
                  subtitle: 'Cloud backup and data synchronization',
                  icon: Icons.backup_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Backup_Sync(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Appearance Section
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _buildSettingsItem(
                  title: 'Theme & Display',
                  subtitle: 'App theme, font size, and layout',
                  icon: Icons.palette_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Theme_Display_Settings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // About Section
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              children: [
                _buildSettingsItem(
                  title: 'App Information',
                  subtitle: 'Version, licenses, and support',
                  icon: Icons.info_outline,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AppI_nfo(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: Colors.blueAccent,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.blueAccent,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blueAccent,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.blueAccent,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey[300],
      indent: 56,
    );
  }
}
