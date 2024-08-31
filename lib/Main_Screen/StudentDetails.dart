import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';

User? loggedInUser;

class StudentDetails extends StatefulWidget {
  @override
  _StudentDetailsState createState() => _StudentDetailsState();
}

class _StudentDetailsState extends State<StudentDetails> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  String? firstName;
  String? lastName;
  String? studentClass;
  String? studentAge;
  String? studentGender;
  String? studentID;
  String? generatedBarcode;

  @override
  void initState() {
    super.initState();
    getCurrentUser(); // Fetch the current user on initialization
  }

  void getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser; // Get the current user
      if (user != null) {
        setState(() {
          loggedInUser = user; // Set the logged-in user
        });
      }
    } catch (e) {
      print(e);
    }
  }

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
            .doc(loggedInUser?.uid) // Use the logged-in user's UID
            .collection('StudentDetails')
            .doc(studentID) // Use the generated student ID as the document ID
            .set({
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
                keyboardType: TextInputType.number,
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
                items: ['Male', 'Female'].map((String genderValue) {
                  return DropdownMenuItem<String>(
                    value: genderValue,
                    child: Text(genderValue),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    studentGender = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the Student\'s Gender';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: saveStudentDetails,
                child: Text('Save Details and Generate Barcode'),
              ),
              SizedBox(height: 20.0),
              if (generatedBarcode != null)
                BarcodeWidget(
                  barcode: Barcode.code128(), // Barcode type
                  data: generatedBarcode!, // The generated barcode data
                  width: 200,
                  height: 80,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
