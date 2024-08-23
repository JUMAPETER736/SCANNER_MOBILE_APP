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
        title: Text('QR Code Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage QR Code Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Enable QR Code Scanning'),
              subtitle: Text('Toggle QR code scanning feature on or off.'),
              trailing: Switch(
                value: isScanningEnabled,
                onChanged: (value) {
                  setState(() {
                    isScanningEnabled = value; // Update the state
                  });
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('QR Code Display Options'),
              subtitle: Text('Choose how QR codes are displayed in the app.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRCodeDisplayOptionsPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('Manage QR Code Data'),
              subtitle: Text('View and edit the data associated with QR codes.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageQRCodeDataPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('QR Code Expiry Settings'),
              subtitle: Text('Set expiry duration for generated QR codes.'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRCodeExpirySettingsPage()),
                );
              },
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Tips for Using QR Codes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '• Ensure QR codes are clear and easy to scan.\n'
                  '• Regularly update QR code data as needed.\n'
                  '• Use secure methods to generate and share QR codes.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
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
        title: Text('QR Code Display Options'),
      ),
      body: Padding(
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
              Text('• Option 1: Display QR Code with logo\n'
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
        title: Text('Manage QR Code Data'),
      ),
      body: Padding(
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
              Text('• View existing QR Code data\n'
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
        title: Text('QR Code Expiry Settings'),
      ),
      body: Padding(
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
              Text('• Choose duration for QR code validity\n'
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
