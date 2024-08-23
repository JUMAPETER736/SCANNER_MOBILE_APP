import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = true;
  String _notificationSound = "Default";
  bool _doNotDisturbEnabled = false;

  void _selectNotificationSound() async {
    // Logic to select a notification sound (you can replace this with actual sound selection)
    final sound = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Notification Sound'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Default');
              },
              child: Text('Default'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Chime');
              },
              child: Text('Chime'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Alert');
              },
              child: Text('Alert'),
            ),
          ],
        );
      },
    );

    if (sound != null && sound.isNotEmpty) {
      setState(() {
        _notificationSound = sound;
      });
    }
  }

  void _navigateToNotificationTypes() {
    // Add logic to navigate to notification types settings
    // For now, we'll use a placeholder alert dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notification Types'),
          content: Text('Here you can select the types of notifications you want to receive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDoNotDisturb() {
    // Add logic to navigate to do not disturb settings
    // For now, we'll use a placeholder alert dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Do Not Disturb'),
          content: Text('Here you can set quiet hours for notifications.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Notification Sound'),
              subtitle: Text('Select the sound for notifications.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_notificationSound),
                  Icon(Icons.arrow_forward),
                ],
              ),
              onTap: _selectNotificationSound,
            ),
            Divider(),
            ListTile(
              title: Text('Notification Types'),
              subtitle: Text('Choose which notifications to receive.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: _navigateToNotificationTypes,
            ),
            Divider(),
            ListTile(
              title: Text('Do Not Disturb'),
              subtitle: Text('Set quiet hours for notifications.'),
              trailing: Switch(
                value: _doNotDisturbEnabled,
                onChanged: (value) {
                  setState(() {
                    _doNotDisturbEnabled = value;
                    if (value) {
                      _navigateToDoNotDisturb();
                    }
                  });
                },
              ),
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
