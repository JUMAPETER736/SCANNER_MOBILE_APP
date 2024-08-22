import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              // Navigate to QR Code Settings page
            },
          ),
          Divider(),

          // Grade Settings
          ListTile(
            title: Text('Grade Settings'),
            subtitle: Text('Customize grading scale and display'),
            leading: Icon(Icons.grade),
            onTap: () {
              // Navigate to Grade Settings page
            },
          ),
          Divider(),

          // Notification Settings
          ListTile(
            title: Text('Notification Settings'),
            subtitle: Text('Manage push and email notifications'),
            leading: Icon(Icons.notifications),
            onTap: () {
              // Navigate to Notification Settings page
            },
          ),
          Divider(),

          // Security Settings
          ListTile(
            title: Text('Security Settings'),
            subtitle: Text('App lock, data encryption, and more'),
            leading: Icon(Icons.lock),
            onTap: () {
              // Navigate to Security Settings page
            },
          ),
          Divider(),

          // Language & Region Settings
          ListTile(
            title: Text('Language & Region'),
            subtitle: Text('Language selection and regional settings'),
            leading: Icon(Icons.language),
            onTap: () {
              // Navigate to Language & Region Settings page
            },
          ),
          Divider(),

          // Backup & Sync
          ListTile(
            title: Text('Backup & Sync'),
            subtitle: Text('Cloud backup and data synchronization'),
            leading: Icon(Icons.backup),
            onTap: () {
              // Navigate to Backup & Sync page
            },
          ),
          Divider(),

          // Theme & Display Settings
          ListTile(
            title: Text('Theme & Display'),
            subtitle: Text('App theme, font size, and layout'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              // Navigate to Theme & Display Settings page
            },
          ),
          Divider(),

          // App Information
          ListTile(
            title: Text('App Information'),
            subtitle: Text('Version, licenses, and support'),
            leading: Icon(Icons.info),
            onTap: () {
              // Navigate to App Information page
            },
          ),
        ],
      ),
    );
  }
}


class UserDetailsPage extends StatefulWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Name'),
              subtitle: Text(widget.user?.displayName ?? 'N/A'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text(widget.user?.email ?? 'N/A'),
            ),
            Divider(),
            ListTile(
              title: Text('Change Password'),
              leading: Icon(Icons.lock),
              onTap: () {
                // Implement change password functionality
              },
            ),
            Divider(),
            ListTile(
              title: Text('Update Profile Picture'),
              leading: Icon(Icons.photo),
              onTap: () {
                // Implement update profile picture functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
