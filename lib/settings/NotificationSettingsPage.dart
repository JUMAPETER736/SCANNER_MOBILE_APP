import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Settings App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationSettingsPage(),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = true; // State management for notifications
  TimeOfDay _startTime = TimeOfDay(hour: 22, minute: 0); // Default start time
  TimeOfDay _endTime = TimeOfDay(hour: 7, minute: 0); // Default end time
  String _selectedSound = 'Default'; // Placeholder for selected sound
  List<String> _notificationTypes = [
    'Messages',
    'Updates',
    'Promotions',
  ];
  List<bool> _notificationSelections = [true, true, true]; // State for notification types

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
              trailing: Text(_selectedSound),
              onTap: () async {
                // Simulated sound selection
                final List<String> sounds = [
                  'Default',
                  'Sound 1',
                  'Sound 2',
                  'Sound 3',
                ]; // Simulated sound options

                String? chosenSound = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Select Notification Sound'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: sounds.map((sound) {
                            return ListTile(
                              title: Text(sound),
                              onTap: () {
                                Navigator.pop(context, sound);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );

                if (chosenSound != null) {
                  setState(() {
                    _selectedSound = chosenSound;
                  });
                }
              },
            ),
            Divider(),
            ListTile(
              title: Text('Notification Types'),
              subtitle: Text('Choose which notifications to receive.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                _showNotificationTypesDialog();
              },
            ),
            Divider(),
            ListTile(
              title: Text('Do Not Disturb'),
              subtitle: Text('Set quiet hours for notifications.'),
              onTap: () {
                _selectQuietHours(context);
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

  // Function to select quiet hours
  Future<void> _selectQuietHours(BuildContext context) async {
    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (newStartTime != null) {
      final TimeOfDay? newEndTime = await showTimePicker(
        context: context,
        initialTime: _endTime,
      );
      if (newEndTime != null) {
        setState(() {
          _startTime = newStartTime;
          _endTime = newEndTime;
        });
      }
    }
    _showQuietHoursDialog();
  }

  // Show the selected quiet hours
  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Quiet Hours'),
          content: Text(
            'From ${_startTime.format(context)} to ${_endTime.format(context)}',
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show notification types dialog
  void _showNotificationTypesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notification Types'),
          content: SingleChildScrollView(
            child: ListBody(
              children: List.generate(_notificationTypes.length, (index) {
                return CheckboxListTile(
                  title: Text(_notificationTypes[index]),
                  value: _notificationSelections[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _notificationSelections[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
