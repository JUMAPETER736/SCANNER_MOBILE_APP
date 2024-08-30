import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Settings/SettingsPage.dart';
import 'package:scanna/Main_Screen/GradeAnalytics.dart';
import 'package:scanna/Main_Screen/ClassSelection.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart'; 
import 'package:barcode/barcode.dart' as barcodeLib; // Alias barcode package
import 'package:barcode_widget/barcode_widget.dart'; 

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
            
            // Button for Entering Student Details
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsPage(),
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
                      Icon(Icons.person_add, size: 40, color: Colors.purple),
                      SizedBox(width: 10),
                      Text(
                        'Enter Student Details',
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
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.pushReplacementNamed(context, Done.id);
          }
        },
      ),
    );
  }
}

class StudentDetailsPage extends StatefulWidget {
  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  String? firstName;
  String? lastName;
  String? studentClass;
  String? studentAge;
  String? studentGender;
  String? studentID;
  String? generatedBarcode;

  String generateRandomStudentID() {
    Random random = Random();
    int id = 100000 + random.nextInt(900000); // Generate a random 6-digit number
    return id.toString();
  }

  void saveStudentDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Generate random student ID
      studentID = generateRandomStudentID();

      // Save student details to Firestore
      await _firestore.collection('Students').add({

        'firstName': firstName,
        'lastName': lastName,
        'studentClass': studentClass,
        'studentAge': studentAge,
        'studentGender': studentGender,
        'studentID': studentID,
        'createdBy': loggedInUser?.uid,
      });

      // Generate Barcode after saving
      setState(() {
        generatedBarcode = studentID; // Use studentID as the barcode data
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student details saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Student Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Student Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter Student Name';
                  }
                  return null;
                },
                onSaved: (value) {
                  
                  firstName = value;
                  lastName = value;
                  studentClass = value;
                  studentAge = value;
                  studentGender = value;

                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: saveStudentDetails,
                child: Text('Save Student Details'),
              ),
              SizedBox(height: 20.0),
              if (generatedBarcode != null)
                Column(
                  children: [
                    Text(
                      'Generated Barcode:',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    BarcodeWidget(
                      barcode: barcodeLib.Barcode.code128(), // Use the aliased barcode class
                      data: generatedBarcode!,
                      width: 200,
                      height: 80,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class QRCodeScannerPage extends StatefulWidget {
  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller; // Update based on latest QR package
  String? scanResult;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    // Create QRView directly without a controller constructor
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scanResult = scanData.code;
      });
      Navigator.pop(context, scanData.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
