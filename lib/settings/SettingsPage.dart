import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  final User? user;

  SettingsPage({required this.user});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetailsPage(user: widget.user),
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

          // Notification Settings
          ListTile(
            title: Text('Notification Settings'),
            subtitle: Text('Manage notifications and alerts'),
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
            subtitle: Text('Change password and security options'),
            leading: Icon(Icons.security),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SecuritySettingsPage(),
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

// Dummy placeholder classes for other pages
class UserDetailsPage extends StatelessWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  Widget build(BuildContext context) {
    // Implement UserDetailsPage UI
    return Scaffold(appBar: AppBar(title: Text('User Details')));
  }
}

class QRCodeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('QR Code Settings')));
  }
}

class GradeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Grade Settings')));
  }
}

class LanguageRegionSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Language & Region Settings')));
  }
}

class BackupSyncPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Backup & Sync')));
  }
}

class ThemeDisplaySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Theme & Display Settings')));
  }
}

class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Notification Settings')));
  }
}

class SecuritySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Security Settings')));
  }
}

class AppInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('App Information')));
  }
}
