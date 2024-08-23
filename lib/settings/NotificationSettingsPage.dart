import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Your Notification Preferences',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Enable Notifications'),
              subtitle: Text('Toggle notifications on or off.'),
              trailing: Switch(
                value: true, // Change to actual state management
                onChanged: (value) {
                  // Add logic to enable/disable notifications
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Notification Sound'),
              subtitle: Text('Select the sound for notifications.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to notification sound settings
              },
            ),
            Divider(),
            ListTile(
              title: Text('Notification Types'),
              subtitle: Text('Choose which notifications to receive.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to select notification types
              },
            ),
            Divider(),
            ListTile(
              title: Text('Do Not Disturb'),
              subtitle: Text('Set quiet hours for notifications.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Add navigation to do not disturb settings
              },
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Tips for Managing Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '• Customize notifications to stay informed without being overwhelmed.\n'
                  '• Regularly check settings to ensure you receive important alerts.\n'
                  '• Use do not disturb during meetings or personal time.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
