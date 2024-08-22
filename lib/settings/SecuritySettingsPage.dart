import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings'),
      ),
      body: Center(
        child: Text('Configure app security settings.'),
      ),
    );
  }
}

