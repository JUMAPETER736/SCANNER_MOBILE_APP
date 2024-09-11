import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensure this is included


class ThemeDisplaySettings extends StatefulWidget {
  @override
  _ThemeDisplaySettingsState createState() => _ThemeDisplaySettingsState();
}

class _ThemeDisplaySettingsState extends State<ThemeDisplaySettings> {
  bool _isDarkMode = false;
  String _selectedDateFormat = 'MM/DD/YYYY';
  final List<String> _dateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme & Display', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                'Customize App Theme',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildSettingsItem(
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark themes.',
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                      // Change theme mode based on the switch state
                      if (_isDarkMode) {
                        Provider.of<ThemeModeProvider>(context, listen: false).setTheme(ThemeMode.dark);
                      } else {
                        Provider.of<ThemeModeProvider>(context, listen: false).setTheme(ThemeMode.light);
                      }
                    });
                  },
                ),
              ),
              
              SizedBox(height: 20),
              Text(
                'Date Format',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              _buildSettingsItem(
                title: 'Select Date Format',
                subtitle: 'Choose your preferred date format.',
                trailing: DropdownButton<String>(
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
              ),
            
              SizedBox(height: 20),
              Text(
                'Other Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
  
              _buildSettingsItem(
                title: 'Privacy Settings',
                subtitle: 'Adjust your privacy options.',
              ),
              _buildSettingsItem(
                title: 'Language Settings',
                subtitle: 'Select your preferred language.',
              ),
              // Add more settings items as needed
            ],
          ),
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





class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }
}
