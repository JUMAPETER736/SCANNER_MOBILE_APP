import 'package:flutter/material.dart';

class SecuritySettingsPage extends StatefulWidget {
  @override
  _SecuritySettingsPageState createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _isBiometricEnabled = false;

  void _navigateTo2FASettings() {
    // Navigate to 2FA settings page
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Two-Factor Authentication (2FA)'),
          content: Text('Here you can enable or manage your 2FA settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSecurityQuestions() {
    // Navigate to security questions settings page
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Security Questions'),
          content: Text('Here you can set or update your security questions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
              onTap: _navigateTo2FASettings,
            ),
            Divider(),
            ListTile(
              title: Text('Biometric Authentication'),
              subtitle: Text('Use fingerprint or face recognition for secure access.'),
              trailing: Switch(
                value: _isBiometricEnabled,
                onChanged: (value) {
                  setState(() {
                    _isBiometricEnabled = value;
                  });
                  // Add logic to enable/disable biometric authentication
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Security Questions'),
              subtitle: Text('Set up security questions for account recovery.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: _navigateToSecurityQuestions,
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
