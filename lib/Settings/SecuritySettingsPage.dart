import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';

class SecuritySettingsPage extends StatefulWidget {
  @override
  _SecuritySettingsPageState createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    setState(() {
      _isBiometricEnabled = isAvailable;
    });
  }

  Future<void> _toggleBiometricAuthentication(bool value) async {
    setState(() {
      _isBiometricEnabled = value;
    });
    // Implement logic to enable/disable biometric authentication
    // This can be saved to Firestore if needed
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
                value: _isBiometricEnabled,
                onChanged: _toggleBiometricAuthentication,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _setup2FA() async {
    User? user = _auth.currentUser;

    if (user != null) {
      // Implement the logic to send a verification code to the user's phone number or email
      // Example for phone number verification:
      await _auth.verifyPhoneNumber(
        phoneNumber: user.phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatically signs the user in if verification is successful
          await user.updatePhoneNumber(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          // Save the verificationId and use it for completing the verification later
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle time out
        },
      );
    }
  }

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
              onPressed: _setup2FA,
              child: Text('Set Up 2FA'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityQuestionsPage extends StatefulWidget {
  @override
  _SecurityQuestionsPageState createState() => _SecurityQuestionsPageState();
}

class _SecurityQuestionsPageState extends State<SecurityQuestionsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _question1Controller = TextEditingController();
  final _question2Controller = TextEditingController();
  final _question3Controller = TextEditingController();

  Future<void> _saveSecurityQuestions() async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.email).set({
        'security_questions': [
          _question1Controller.text,
          _question2Controller.text,
          _question3Controller.text,
        ],
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Security questions saved successfully!')),
      );
    }
  }

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
            TextField(
              controller: _question1Controller,
              decoration: InputDecoration(
                labelText: 'What is your mother\'s maiden name?',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _question2Controller,
              decoration: InputDecoration(
                labelText: 'What was the name of your first pet?',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _question3Controller,
              decoration: InputDecoration(
                labelText: 'What was the name of your first school?',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSecurityQuestions,
              child: Text('Save Security Questions'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _question1Controller.dispose();
    _question2Controller.dispose();
    _question3Controller.dispose();
    super.dispose();
  }
}
