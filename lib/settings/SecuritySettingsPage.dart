import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure App Security Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Change Password'),
              subtitle: Text('Update your account password.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to change password page
              },
            ),
            Divider(),
            ListTile(
              title: Text('Enable Two-Factor Authentication (2FA)'),
              subtitle: Text('Add an extra layer of security to your account.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to 2FA settings page
              },
            ),
            Divider(),
            ListTile(
              title: Text('Biometric Authentication'),
              subtitle: Text('Use fingerprint or face recognition for secure access.'),
              trailing: Switch(
                value: false, // Change to actual state management
                onChanged: (value) {
                  // Add logic to enable/disable biometric authentication
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Security Questions'),
              subtitle: Text('Set up security questions for account recovery.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to security questions settings
              },
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Other Security Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '• Always use strong and unique passwords.\n'
                  '• Keep your app updated for the latest security features.\n'
                  '• Monitor your account for suspicious activity.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
