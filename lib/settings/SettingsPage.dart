import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            // onTap: () {
            //   Navigator.of(context).push(
            //     MaterialPageRoute(
            //       // builder: (context) => UserDetailsPage(user: widget.user),
            //     ),
            //   );
            // },
          ),
          Divider(),

          // QR Code Settings
          ListTile(
            title: Text('QR Code Settings'),
            subtitle: Text('Scan mode, camera settings, and more'),
            leading: Icon(Icons.qr_code),
            onTap: () {
              // Navigate to QR Code Settings Page
            },
          ),
          Divider(),

          // Grade Settings
          ListTile(
            title: Text('Grade Settings'),
            subtitle: Text('Customize grading scale and display'),
            leading: Icon(Icons.grade),
            onTap: () {
              // Navigate to Grade Settings Page
            },
          ),
          Divider(),

          // Other ListTiles here...

          // Language & Region Settings
          ListTile(
            title: Text('Language & Region'),
            subtitle: Text('Language selection and regional settings'),
            leading: Icon(Icons.language),
            onTap: () {
              // Navigate to Language & Region Settings Page
            },
          ),
          Divider(),

          // Backup & Sync
          ListTile(
            title: Text('Backup & Sync'),
            subtitle: Text('Cloud backup and data synchronization'),
            leading: Icon(Icons.backup),
            onTap: () {
              // Navigate to Backup & Sync Page
            },
          ),
          Divider(),

          // Theme & Display Settings
          ListTile(
            title: Text('Theme & Display'),
            subtitle: Text('App theme, font size, and layout'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              // Navigate to Theme & Display Settings Page
            },
          ),
          Divider(),

          // App Information
          ListTile(
            title: Text('App Information'),
            subtitle: Text('Version, licenses, and support'),
            leading: Icon(Icons.info),
            onTap: () {
              // Navigate to App Information Page
            },
          ),
        ],
      ),
    );
  }
}


//
// class UserDetailsPage extends StatefulWidget {
//   final User? user;
//
//   UserDetailsPage({required this.user});
//
//   @override
//   _UserDetailsPageState createState() => _UserDetailsPageState();
// }
//
// class _UserDetailsPageState extends State<UserDetailsPage> {
//   TextEditingController _nameController = TextEditingController();
//   String _username = '';
//   String _classSelected = '';  // Define the class variable
//   String _subjectSelected = ''; // Define the subject variable
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserDetails();
//   }
//
//   Future<void> _fetchUserDetails() async {
//     if (widget.user?.uid != null) {
//       try {
//         DocumentSnapshot snapshot = await FirebaseFirestore.instance
//             .collection('users') // Change to your collection name
//             .doc(widget.user!.uid)
//             .get();
//
//         if (snapshot.exists) {
//           setState(() {
//             _username = snapshot['name'] ?? '';
//             _classSelected = snapshot['class'] ?? 'N/A';  // Fetch the class
//             _subjectSelected = snapshot['subject'] ?? 'N/A'; // Fetch the subject
//             _nameController.text = _username; // Set the username in the controller
//           });
//         }
//       } catch (e) {
//         print('Error fetching user details: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('User Details'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             ListTile(
//               leading: Icon(Icons.person),
//               title: Text('Username'),
//               subtitle: Text(_username.isNotEmpty ? _username : 'N/A'),
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.email),
//               title: Text('Email'),
//               subtitle: Text(widget.user?.email ?? 'N/A'),
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.class_),
//               title: Text('Class Selected'),
//               subtitle: Text(_classSelected),
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.subject),
//               title: Text('Subject Selected'),
//               subtitle: Text(_subjectSelected),
//             ),
//             Divider(),
//             ListTile(
//               title: Text('Change Password'),
//               leading: Icon(Icons.lock),
//               onTap: () {
//                 // Implement change password functionality
//               },
//             ),
//             Divider(),
//             ListTile(
//               title: Text('Update Profile Picture'),
//               leading: Icon(Icons.photo),
//               onTap: () {
//                 // Implement update profile picture functionality
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
