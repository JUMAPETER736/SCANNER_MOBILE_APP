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
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  String generateRandomStudentID() {
    Random random = Random();
    int id = 100000 + random.nextInt(900000);
    return id.toString();
  }

  void saveStudentDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      studentID = generateRandomStudentID();

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
          'createdBy': loggedInUser?.email,
          'form': studentClass,
        });

        setState(() {
          generatedBarcode = studentID;
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
        title: Text('Enter Student Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Class',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: saveStudentDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Save & Generate Barcode'),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              if (generatedBarcode != null)
                Center(
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: generatedBarcode!,
                    width: 200,
                    height: 80,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
