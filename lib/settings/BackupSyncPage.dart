import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupSyncPage extends StatefulWidget {
  @override
  _BackupSyncPageState createState() => _BackupSyncPageState();
}

class _BackupSyncPageState extends State<BackupSyncPage> {
  bool _autoBackupEnabled = false;
  bool _syncWithCloudEnabled = false;

  void _toggleAutoBackup(bool? value) {
    setState(() {
      _autoBackupEnabled = value ?? false;
    });
    // Add logic to handle auto backup setting
  }

  void _toggleSyncWithCloud(bool? value) {
    setState(() {
      _syncWithCloudEnabled = value ?? false;
    });
    // Add logic to handle cloud sync setting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Sync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: Text('Enable Auto Backup'),
              value: _autoBackupEnabled,
              onChanged: _toggleAutoBackup,
              subtitle: Text('Automatically back up your data regularly.'),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('Sync with Cloud'),
              value: _syncWithCloudEnabled,
              onChanged: _toggleSyncWithCloud,
              subtitle: Text('Keep your data synchronized with the cloud.'),
            ),
            SizedBox(height: 20),
            Text(
              'Backup Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last backup: ${_autoBackupEnabled ? "Enabled" : "Disabled"}\n'
                  'Cloud sync: ${_syncWithCloudEnabled ? "Active" : "Inactive"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic to manually trigger backup
              },
              child: Text('Backup Now'),
            ),
          ],
        ),
      ),
    );
  }
}
