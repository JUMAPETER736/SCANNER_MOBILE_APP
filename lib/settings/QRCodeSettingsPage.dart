import 'package:flutter/material.dart';

class QRCodeSettingsPage extends StatefulWidget {
  @override
  _QRCodeSettingsPageState createState() => _QRCodeSettingsPageState();
}

class _QRCodeSettingsPageState extends State<QRCodeSettingsPage> {
  bool _qrCodeScanningEnabled = true;
  String _qrCodeDisplayOption = "Default";
  String _qrCodeData = "Sample Data";
  String _qrCodeExpiry = "24 hours";

  void _navigateToDisplayOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select QR Code Display Option'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Default');
              },
              child: Text('Default'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Compact');
              },
              child: Text('Compact'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Detailed');
              },
              child: Text('Detailed'),
            ),
          ],
        );
      },
    );

    if (option != null && option.isNotEmpty) {
      setState(() {
        _qrCodeDisplayOption = option;
      });
    }
  }

  void _navigateToManageData() async {
    final data = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage QR Code Data'),
          content: TextField(
            decoration: InputDecoration(
              labelText: 'Enter QR Code Data',
            ),
            onChanged: (value) {
              _qrCodeData = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, _qrCodeData);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (data != null && data.isNotEmpty) {
      setState(() {
        _qrCodeData = data;
      });
    }
  }

  void _navigateToExpirySettings() async {
    final expiry = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Set QR Code Expiry Duration'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, '24 hours');
              },
              child: Text('24 hours'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, '7 days');
              },
              child: Text('7 days'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, '30 days');
              },
              child: Text('30 days'),
            ),
          ],
        );
      },
    );

    if (expiry != null && expiry.isNotEmpty) {
      setState(() {
        _qrCodeExpiry = expiry;
      });
    }
  }

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
                value: _qrCodeScanningEnabled,
                onChanged: (value) {
                  setState(() {
                    _qrCodeScanningEnabled = value;
                  });
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('QR Code Display Options'),
              subtitle: Text('Choose how QR codes are displayed in the app.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_qrCodeDisplayOption),
                  Icon(Icons.arrow_forward),
                ],
              ),
              onTap: _navigateToDisplayOptions,
            ),
            Divider(),
            ListTile(
              title: Text('Manage QR Code Data'),
              subtitle: Text('View and edit the data associated with QR codes.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_qrCodeData),
                  Icon(Icons.arrow_forward),
                ],
              ),
              onTap: _navigateToManageData,
            ),
            Divider(),
            ListTile(
              title: Text('QR Code Expiry Settings'),
              subtitle: Text('Set expiry duration for generated QR codes.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_qrCodeExpiry),
                  Icon(Icons.arrow_forward),
                ],
              ),
              onTap: _navigateToExpirySettings,
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
