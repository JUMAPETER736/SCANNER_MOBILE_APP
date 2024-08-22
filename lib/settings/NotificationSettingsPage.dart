
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
      ),
      body: Center(
        child: Text('Manage your notification preferences.'),
      ),
    );
  }
}

