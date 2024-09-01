import 'package:flutter/material.dart';

class QRCodeSettingsPage extends StatefulWidget {
  @override
  _QRCodeSettingsPageState createState() => _QRCodeSettingsPageState();
}

class _QRCodeSettingsPageState extends State<QRCodeSettingsPage> {
  bool isScanningEnabled = true; // State for the toggle switch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
              title: 'Enable QR Code Scanning',
              subtitle: 'Toggle QR code scanning feature on or off.',
              trailing: Switch(
                value: isScanningEnabled,
                onChanged: (value) {
                  setState(() {
                    isScanningEnabled = value; // Update the state
                  });
                },
              ),
            ),
            _buildSettingsItem(
              title: 'QR Code Display Options',
              subtitle: 'Choose how QR codes are displayed in the app.',
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRCodeDisplayOptionsPage()),
                );
              },
            ),
            _buildSettingsItem(
              title: 'Manage QR Code Data',
              subtitle: 'View and edit the data associated with QR codes.',
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageQRCodeDataPage()),
                );
              },
            ),
            _buildSettingsItem(
              title: 'QR Code Expiry Settings',
              subtitle: 'Set expiry duration for generated QR codes.',
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRCodeExpirySettingsPage()),
                );
              },
            ),
            SizedBox(height: 20),

            _buildSettingsItem(
              title: 'Tips for Using QR Codes',
             
              subtitle:
              '• Ensure QR codes are clear and easy to scan.\n'
              '• Regularly update QR code data as needed.\n'
              '• Use secure methods to generate and share QR codes.',
            
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
}

// QR Code Display Options Page
class QRCodeDisplayOptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Display Options', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose QR Code Display Options',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '• Option 1: Display QR Code with logo\n'
                '• Option 2: Display QR Code with a custom color\n'
                '• Option 3: Display QR Code in various sizes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Manage QR Code Data Page
class ManageQRCodeDataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage QR Code Data', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Manage Your QR Code Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '• View existing QR Code data\n'
                '• Edit QR Code information\n'
                '• Delete unwanted QR Codes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// QR Code Expiry Settings Page
class QRCodeExpirySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Expiry Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Set Expiry Duration for QR Codes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '• Choose duration for QR code validity\n'
                '• Set alerts for expired QR codes\n'
                '• Manage multiple expiry settings',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
