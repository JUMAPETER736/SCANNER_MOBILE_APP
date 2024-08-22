import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageRegionSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language & Region'),
      ),
      body: Center(
        child: Text('Select your preferred language and region.'),
      ),
    );
  }
}

