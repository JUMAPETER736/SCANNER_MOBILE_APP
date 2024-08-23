import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Main Settings Page
class SettingsPage extends StatefulWidget {
  final User? user;

  SettingsPage({required this.user});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'United States';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Chichewa'];
  final List<String> _regions = ['United States', 'Canada', 'United Kingdom', 'Australia', 'India', 'Malawi'];

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _changeRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
  }

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
              // Add the logic here for Language & Region Settings Page
            },
          ),
          Divider(),

          // Backup & Sync
          ListTile(
            title: Text('Backup & Sync'),
            subtitle: Text('Cloud backup and data synchronization'),
            leading: Icon(Icons.backup),
            onTap: () {
              // Add the logic here for Backup & Sync Page
            },
          ),
          Divider(),

          // Theme & Display Settings
          ListTile(
            title: Text('Theme & Display'),
            subtitle: Text('App theme, font size, and layout'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              // Add the logic here for Theme & Display Settings Page
            },
          ),
          Divider(),

          // App Information
          ListTile(
            title: Text('App Information'),
            subtitle: Text('Version, licenses, and support'),
            leading: Icon(Icons.info),
            onTap: () {
              // Add the logic here for App Information Page
            },
          ),
        ],
      ),
    );
  }
}

// User Details Page
class UserDetailsPage extends StatefulWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  TextEditingController _nameController = TextEditingController();
  String _username = '';
  String _classSelected = '';
  String _subjectSelected = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.user?.uid != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users') // Replace with your actual collection name
            .doc(widget.user!.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _username = snapshot['name'] ?? '';
            _nameController.text = _username;
            _classSelected = snapshot['classSelected'] ?? 'Not Selected';
            _subjectSelected = snapshot['subjectSelected'] ?? 'Not Selected';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
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
              title: Text('Username'),
              subtitle: Text(_username.isNotEmpty ? _username : 'N/A'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text(widget.user?.email ?? 'N/A'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.class_),
              title: Text('Class Selected'),
              subtitle: Text(_classSelected),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.subject),
              title: Text('Subject Selected'),
              subtitle: Text(_subjectSelected),
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

// QR Code Settings Page
class QRCodeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('Customize QR code settings here.'),
        ),
      ),
    );
  }
}

// Grade Settings Page
class GradeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('Customize your grading scale and display.'),
        ),
      ),
    );
  }
}
