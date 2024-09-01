import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemeModeWrapper(
      child: MaterialApp(
        title: 'Theme & Display Settings',
        theme: ThemeData.light(), // Light theme
        darkTheme: ThemeData.dark(), // Dark theme
        themeMode: ThemeModeProvider.of(context).themeMode, // Use the theme mode from the provider
        home: ThemeDisplaySettingsPage(),
      ),
    );
  }
}

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
                  // Change theme mode based on the switch state
                  if (_isDarkMode) {
                    ThemeModeProvider.of(context).setTheme(ThemeMode.dark);
                  } else {
                    ThemeModeProvider.of(context).setTheme(ThemeMode.light);
                  }
                });
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

// ThemeMode provider class
class ThemeModeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) setTheme;

  ThemeModeProvider({required Widget child, required this.themeMode, required this.setTheme}) : super(child: child);

  static ThemeModeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeModeProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeModeProvider oldWidget) {
    return oldWidget.themeMode != themeMode;
  }
}

// Create a widget to wrap the app and manage the theme mode
class ThemeModeWrapper extends StatefulWidget {
  final Widget child;

  ThemeModeWrapper({required this.child});

  @override
  _ThemeModeWrapperState createState() => _ThemeModeWrapperState();
}

class _ThemeModeWrapperState extends State<ThemeModeWrapper> {
  ThemeMode _themeMode = ThemeMode.light; // Default to light mode

  void setTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeProvider(
      themeMode: _themeMode,
      setTheme: setTheme,
      child: widget.child,
    );
  }
}
