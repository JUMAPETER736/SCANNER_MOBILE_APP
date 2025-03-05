import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:scanna/Settings/SecurityQuestions.dart';
import 'package:scanna/Settings/TwoFactorAuthentication.dart';

class SecuritySettings extends StatefulWidget {
  @override
  _SecuritySettingsState createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: ListView(
            children: [
              Text(
                'Configure App Security Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildSettingsItem(
                title: 'Enable Two-Factor Authentication (2FA)',
                subtitle: 'Add an extra layer of security to your account.',
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TwoFactorAuthentication()),
                  );
                },
              ),
              _buildSettingsItem(
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face recognition for secure access.',
                trailing: Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometricAuthentication,
                ),
              ),
              _buildSettingsItem(
                title: 'Security Questions',
                subtitle: 'Set up security questions for account recovery.',
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecurityQuestions()),
                  );
                },
              ),
              SizedBox(height: 20),

              _buildSettingsItem(
              
               title:  'Other Security Tips',
               
               subtitle: 

                '• Always use strong and unique passwords.\n'
                '• Keep your app updated for the latest security features.\n'
                '• Monitor your account for suspicious activity.',
               
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 16)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}







