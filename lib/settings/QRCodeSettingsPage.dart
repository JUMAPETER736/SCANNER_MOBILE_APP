import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Settings'),
      ),
      body: Center(
        child: Text('Manage QR Code settings here.'),
      ),
    );
  }
}

