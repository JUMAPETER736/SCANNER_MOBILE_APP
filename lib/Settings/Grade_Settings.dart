import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences

class Grade_Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              'Customize Your Grading Scale and Display:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your grading settings efficiently to ensure accurate assessment of student performance.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),

            // View current grading settings
            _buildSettingsItem(
              title: 'View Current Grading Settings',
              subtitle: 'Check the current grading scale in use.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CurrentSettingsPage()),
                );
              },
            ),
            SizedBox(height: 8),

            // Reset to default settings
            _buildSettingsItem(
              title: 'Reset to Default Settings',
              subtitle: 'Restore the default grading settings.',
              onTap: () => _showResetConfirmationDialog(context),
            ),
            SizedBox(height: 16),

            Text(
              'Additional Features:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 8),

            // Save custom grading scales
            _buildSettingsItem(
              title: 'Save Custom Grading Scales',
              subtitle: 'Save your modifications for future use.',
              onTap: () => _showSaveConfirmationDialog(context),
            ),
            SizedBox(height: 8),

            // Export grading settings
            _buildSettingsItem(
              title: 'Export Grading Settings',
              subtitle: 'Export your settings as a file.',
              onTap: _exportSettings,
            ),
            SizedBox(height: 8),

            // Import grading settings
            _buildSettingsItem(
              title: 'Import Grading Settings',
              subtitle: 'Import grading settings from a file.',
              onTap: _importSettings,
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Settings'),
          content: Text('Are you sure you want to reset to default settings?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetSettings(); // Reset settings logic here
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showSaveConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Save Settings'),
          content: Text('Your custom grading scales will be saved. Do you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveSettings(); // Save settings logic here
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _exportSettings() {
    // Logic to export settings
  }

  void _importSettings() {
    // Logic to import settings
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Replace 'yourGradingScaleKey' and 'yourGradingScaleValue' with actual data
    await prefs.setString('gradingScale', 'A: 90-100, B: 80-89, C: 70-79'); // Example grading scale
  }

  Future<void> _resetSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('gradingScale'); // Remove saved grading scale
  }
}

class CurrentSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Grading Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<String?>(
        future: _loadCurrentSettings(), // Load current settings
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  color: Colors.blue[50], // Match color to SettingsPage
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Current Grading Scale: ${snapshot.data}',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  color: Colors.blue[50], // Match color to SettingsPage
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No grading settings found.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<String?> _loadCurrentSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('gradingScale'); // Load the grading scale
  }
}
