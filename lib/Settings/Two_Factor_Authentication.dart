

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Two_Factor_Authentication extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _setup2FA(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _auth.verifyPhoneNumber(
        phoneNumber: user.phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.updatePhoneNumber(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Two-Factor Authentication set up successfully!")),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification failed: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification code sent!")));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
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
                onPressed: () => _setup2FA(context),
                child: Text('Set Up 2FA'),
              ),
              SizedBox(height: 20),
              Text(
                'Other Security Tips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Always use strong and unique passwords.\n'
                '• Keep your app updated for the latest security features.\n'
                '• Monitor your account for suspicious activity.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
