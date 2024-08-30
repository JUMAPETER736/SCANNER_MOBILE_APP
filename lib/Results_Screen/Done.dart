import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Settings/SettingsPage.dart';
import 'package:scanna/Main_Screen/GradeAnalytics.dart';
import 'package:scanna/Main_Screen/ClassSelection.dart';
import 'package:qr_flutter/qr_flutter.dart'; 

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
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'Help',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.pushReplacementNamed(context, Done.id);
          }
          if (index == 1) {
            // Navigate to Help or any other feature you want to add
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
  String? generatedQRCode;

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

      // Save student details to Firestore under the user's document
      try {
        await _firestore
            .collection('Students') 
            .doc(loggedInUser?.uid) 
            .collection('StudentDetails') 
            .doc(studentID) 
            .set({
          'firstName': firstName,
          'lastName': lastName,
          'studentClass': studentClass,
          'studentAge': studentAge,
          'studentGender': studentGender,
          'studentID': studentID,
          'createdBy': loggedInUser?.uid,
        });

        // Generate QR Code after saving
        setState(() {
          generatedQRCode = studentID; // Use studentID as the QR code data
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student Details saved Successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Student Details: $e')),
        );
      }
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
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter the Student\'s First Name';
                  }
                  return null;
                },
                onSaved: (value) {
                  firstName = value;
                },
              ),
              SizedBox(height: 10.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter the Student\'s Last Name';
                  }
                  return null;
                },
                onSaved: (value) {
                  lastName = value;
                },
              ),
              SizedBox(height: 10.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Class'),
                items: ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4']
                    .map((String classValue) {
                  return DropdownMenuItem<String>(
                    value: classValue,
                    child: Text(classValue),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    studentClass = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the Student\'s Class';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter the Student\'s Age';
                  }
                  return null;
                },
                onSaved: (value) {
                  studentAge = value;
                },
              ),
              SizedBox(height: 10.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female']
                    .map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    studentGender = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the Student\'s gender';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: saveStudentDetails,
                child: Text('Save Student Details'),
              ),
              SizedBox(height: 20.0),

              // Display QR Code if generated
              if (generatedQRCode != null)
                Column(
                  children: [
                    Text('Generated QR Code for Student ID: $generatedQRCode'),
                    QrImage(
                      data: generatedQRCode!,
                      version: QrVersions.auto,
                      size: 200.0,
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
