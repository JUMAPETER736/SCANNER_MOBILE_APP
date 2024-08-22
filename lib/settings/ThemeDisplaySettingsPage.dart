import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeDisplaySettingsPage extends StatefulWidget {
  @override
  _ThemeDisplaySettingsPageState createState() => _ThemeDisplaySettingsPageState();
}

class _ThemeDisplaySettingsPageState extends State<ThemeDisplaySettingsPage> {
  bool _isDarkMode = false;
  String _selectedDateFormat = 'MM/DD/YYYY';
  final List<String> _dateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme & Display'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize App Theme',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                // You can add logic here to apply the theme to your app
              },
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Date Format',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedDateFormat,
              items: _dateFormats.map((String format) {
                return DropdownMenuItem<String>(
                  value: format,
                  child: Text(format),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDateFormat = newValue!;
                });
                // You can add logic here to apply the date format in your app
              },
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Other Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // You can add more settings here as needed
          ],
        ),
      ),
    );
  }
}
