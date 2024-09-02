import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved preferences
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedSound = prefs.getString('selectedSound') ?? 'Default';
      _startTime = TimeOfDay(
          hour: prefs.getInt('quietHoursStartHour') ?? 22,
          minute: prefs.getInt('quietHoursStartMinute') ?? 0);
      _endTime = TimeOfDay(
          hour: prefs.getInt('quietHoursEndHour') ?? 7,
          minute: prefs.getInt('quietHoursEndMinute') ?? 0);
      _notificationSelections = List.generate(
          _notificationTypes.length,
          (index) => prefs.getBool('notificationType$index') ?? true);
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setString('selectedSound', _selectedSound);
    await prefs.setInt('quietHoursStartHour', _startTime.hour);
    await prefs.setInt('quietHoursStartMinute', _startTime.minute);
    await prefs.setInt('quietHoursEndHour', _endTime.hour);
    await prefs.setInt('quietHoursEndMinute', _endTime.minute);
    for (int i = 0; i < _notificationTypes.length; i++) {
      await prefs.setBool('notificationType$i', _notificationSelections[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildSettingsItem(
              title: 'Enable Notifications',
              subtitle: 'Toggle notifications on or off.',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _savePreferences(); // Save preferences
                },
              ),
            ),
            _buildSettingsItem(
              title: 'Notification Sound',
              subtitle: 'Select the sound for notifications.',
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
                  _savePreferences(); // Save preferences
                }
              },
            ),
            _buildSettingsItem(
              title: 'Notification Types',
              subtitle: 'Choose which notifications to receive.',
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                _showNotificationTypesDialog();
              },
            ),
            _buildSettingsItem(
              title: 'Do Not Disturb',
              subtitle: 'Set quiet hours for notifications.',
              onTap: () {
                _selectQuietHours(context);
              },
            ),
            SizedBox(height: 20),

            _buildSettingsItem(

            title: 'Tips for Managing Notifications',
              
            subtitle: 
              '• Customize notifications to stay informed without being overwhelmed.\n'
              '• Regularly check settings to ensure you receive important alerts.\n'
              '• Use do not disturb during meetings or personal time.',
              
            
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
    VoidCallback? onTap,
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
        onTap: onTap,
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
        _savePreferences(); // Save preferences
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
                    _savePreferences(); // Save preferences
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
