import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _backupStatus = '';
  double _backupProgress = 0.0;
  bool _isBackingUp = false;
  String _lastBackupTime = '';
  String _lastBackupResult = '';

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  void _toggleAutoBackup(bool? value) {
    setState(() {
      _autoBackupEnabled = value ?? false;
    });
  }

  void _toggleSyncWithCloud(bool? value) {
    setState(() {
      _syncWithCloudEnabled = value ?? false;
    });
  }

  Future<void> _backupNow() async {
    setState(() {
      _backupStatus = 'Backing up...';
      _backupProgress = 0.0;
      _isBackingUp = true;
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 30));
      setState(() {
        _backupProgress = i / 100;
      });
    }

    setState(() {
      _backupStatus = 'Backup completed successfully!';
      _lastBackupResult = _backupStatus;
      _isBackingUp = false;
      _lastBackupTime = DateFormat('dd-MM-yyyy   kk:mm').format(DateTime.now());
    });

    await _saveLastBackupTime(_lastBackupTime);
  }

  Future<void> _loadLastBackupTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTime = prefs.getString('lastBackupTime');
    setState(() {
      _lastBackupTime = savedTime ?? '';
      _lastBackupResult = savedTime != null ? 'Last Backup Successful' : '';
    });
  }

  Future<void> _saveLastBackupTime(String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastBackupTime', time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Sync', style: TextStyle(fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Backup Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),
            _buildSettingsItem(
              title: 'Enable Auto Backup',
              subtitle: 'Automatically back up your data regularly.',
              trailing: Switch(
                value: _autoBackupEnabled,
                onChanged: _toggleAutoBackup,
                activeColor: Colors.blueAccent, // Change active color of switch
              ),
            ),
            SizedBox(height: 20),
            _buildSettingsItem(
              title: 'Sync with Cloud',
              subtitle: 'Keep your data synchronized with the cloud.',
              trailing: Switch(
                value: _syncWithCloudEnabled,
                onChanged: _toggleSyncWithCloud,
                activeColor: Colors.blueAccent, // Change active color of switch
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Backup Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 10),
            Text(
              'Last backup: ${_lastBackupTime.isNotEmpty ? _lastBackupTime : "No backup available"}\n'
              'Cloud sync: ${_syncWithCloudEnabled ? "Active" : "Inactive"}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
            if (_backupStatus.isNotEmpty)
              Text(
                _backupStatus,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            if (_lastBackupResult.isNotEmpty)
              Text(
                'Last Backup Status: $_lastBackupResult',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            SizedBox(height: 20),
            if (_isBackingUp)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _backupProgress,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${(_backupProgress * 100).round()}%',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isBackingUp ? null : _backupNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Backup Now', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    Widget? trailing,
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
        onTap: () {
          // Optional: Add functionality for tapping on the item
        },
      ),
    );
  }
}
