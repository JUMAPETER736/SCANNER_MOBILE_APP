import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupSyncPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Sync'),
      ),
      body: Center(
        child: Text('Manage backup and sync options.'),
      ),
    );
  }
}


