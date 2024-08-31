import 'package:flutter/material.dart';

class GradeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Customize Your Grading Scale and Display:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your grading settings efficiently to ensure accurate assessment of student performance.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),

            // View current grading settings
            Card(
              child: ListTile(
                title: Text('View Current Grading Settings'),
                subtitle: Text('Check the current grading scale in use.'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Action to view current settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CurrentSettingsPage()),
                  );
                },
              ),
            ),
            SizedBox(height: 8),

            // Reset to default settings
            Card(
              child: ListTile(
                title: Text('Reset to Default Settings'),
                subtitle: Text('Restore the default grading settings.'),
                trailing: Icon(Icons.restore),
                onTap: () {
                  // Action to reset settings
                  _showResetConfirmationDialog(context);
                },
              ),
            ),
            SizedBox(height: 16),

            Text(
              'Additional Features:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Save custom grading scales
            Card(
              child: ListTile(
                title: Text('Save Custom Grading Scales'),
                subtitle: Text('Save your modifications for future use.'),
                trailing: Icon(Icons.save),
                onTap: () {
                  // Action to save custom settings
                  _showSaveConfirmationDialog(context);
                },
              ),
            ),
            SizedBox(height: 8),

            // Export grading settings
            Card(
              child: ListTile(
                title: Text('Export Grading Settings'),
                subtitle: Text('Export your settings as a file.'),
                trailing: Icon(Icons.file_download),
                onTap: () {
                  // Action to export settings
                  _exportSettings();
                },
              ),
            ),
            SizedBox(height: 16),

            // Additional options
            Card(
              child: ListTile(
                title: Text('Import Grading Settings'),
                subtitle: Text('Import grading settings from a file.'),
                trailing: Icon(Icons.file_upload),
                onTap: () {
                  // Action to import settings
                  _importSettings();
                },
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
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
                // Reset settings logic here
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
                // Save settings logic here
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

  void _setNotificationPreferences() {
    // Logic to set notification preferences
  }
}

class CurrentSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Grading Settings'),
      ),
      body: Center(
        child: Text('Display current grading settings here.'),
      ),
    );
  }
}
