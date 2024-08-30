import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/SettingsPage.dart';
import 'package:scanna/Main_Screen/GradeAnalytics.dart';
import 'package:scanna/Main_Screen/ClassSelection.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import for barcode scanning

User? loggedInUser;

class Done extends StatefulWidget {
  static String id = '/Done';

  @override
  _DoneState createState() => _DoneState();
}

class _DoneState extends State<Done> {
  final _auth = FirebaseAuth.instance;
  String? scanResult;

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanna Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(user: loggedInUser),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.0), // Add padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Message
            Text(
              'Welcome, ${loggedInUser?.displayName ?? 'User'}!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40.0), // Spacing before buttons
            
            // Button for Class Selection
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassSelection(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 40, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Select Class',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0), // Spacing between buttons
            
            // Button for Viewing Grade Analytics
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeAnalytics(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 40, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        'View Grade Analytics',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0), // Spacing between buttons
            
            // Button for Scanning Grades
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarcodeScannerPage(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Scan Student Grades',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0), // Spacing for last text
            
            // Display Last Scan Result
            if (scanResult != null)
              Text(
                'Last Scan: $scanResult',
                style: TextStyle(fontSize: 16.0, color: Colors.black),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.pushReplacementNamed(context, Done.id);
          } else {
            // Navigate to Settings
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(user: loggedInUser),
              ),
            );
          }
        },
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  String? scanResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (BarcodeCapture barcodeCapture) {
                final barcode = barcodeCapture.barcodes.first;
                final String code = barcode.displayValue ?? '---';
                setState(() {
                  scanResult = code;
                });
                Navigator.pop(context, code);
              },
            ),
          ),
          if (scanResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Scanned Code: $scanResult',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
        ],
      ),
    );
  }
}
