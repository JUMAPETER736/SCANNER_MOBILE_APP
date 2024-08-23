import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import this package for date formatting

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backup & Sync App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BackupSyncPage(),
    );
  }
}

class BackupSyncPage extends StatefulWidget {
  @override
  _BackupSyncPageState createState() => _BackupSyncPageState();
}

class _BackupSyncPageState extends State<BackupSyncPage> {
  bool _autoBackupEnabled = false;
  bool _syncWithCloudEnabled = false;
  String _backupStatus = ''; // To display backup status messages
  double _backupProgress = 0.0; // To track backup progress
  bool _isBackingUp = false; // To check if a backup is in progress
  String _lastBackupTime = ''; // To display the date and time of the last backup

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

  Future<void> _backupNow() async {
    setState(() {
      _backupStatus = 'Backing up...';
      _backupProgress = 0.0;
      _isBackingUp = true;
    });

    // Simulated backup process with progress
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 30)); // Simulate time taken for each percentage
      setState(() {
        _backupProgress = i / 100; // Update progress
      });
    }

    setState(() {
      _backupStatus = 'Backup completed successfully!'; // Update backup status message
      _isBackingUp = false; // Mark backup as completed
      _lastBackupTime = DateFormat('dd-MM-yyyy   kk:mm').format(DateTime.now()); // Get current date and time
    });

    // Here you can add actual backup logic (e.g., saving to a database or cloud)
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
            Text(
              _backupStatus,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            if (_lastBackupTime.isNotEmpty) // Display last backup time if available
              Text(
                'Last Backup Time: $_lastBackupTime',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            SizedBox(height: 20),
            if (_isBackingUp) // Show progress only during backup
              Column(
                children: [
                  LinearProgressIndicator(value: _backupProgress), // Show progress bar
                  SizedBox(height: 10),
                  Text(
                    '${(_backupProgress * 100).round()}%', // Show percentage
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isBackingUp ? null : _backupNow, // Disable button while backing up
              child: Text('Backup Now'),
            ),
          ],
        ),
      ),
    );
  }
}
