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
              title: Text('Enable Two-Factor Authentication (2FA)'),
              subtitle: Text('Add an extra layer of security to your account.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('Biometric Authentication'),
              subtitle: Text('Use fingerprint or face recognition for secure access.'),
              trailing: Switch(
                value: false, // Replace with actual state management for biometrics
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecurityQuestionsPage()),
                );
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

class TwoFactorAuthenticationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enable Two-Factor Authentication (2FA)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Two-Factor Authentication (2FA) adds an extra layer of security to your account by requiring an additional verification step during login.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement 2FA setup logic here
              },
              child: Text('Set Up 2FA'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityQuestionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Questions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Up Security Questions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Security questions help verify your identity in case you forget your password or need to recover your account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Add security question fields here
            ElevatedButton(
              onPressed: () {
                // Implement security questions setup logic here
              },
              child: Text('Set Up Security Questions'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Biometric Authentication State Management
// class BiometricAuthenticationState extends State<SecuritySettingsPage> {
//   bool isBiometricEnabled = false;
//
//   void toggleBiometricAuthentication(bool value) {
//     setState(() {
//       isBiometricEnabled = value;
//       // Implement logic to enable/disable biometric authentication
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Switch(
//       value: isBiometricEnabled,
//       onChanged: toggleBiometricAuthentication,
//     );
//   }
// }
