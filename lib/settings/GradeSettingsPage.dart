import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GradeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Settings'),
      ),
      body: Center(
        child: Text('Customize your grading scale and display.'),
      ),
    );
  }
}

