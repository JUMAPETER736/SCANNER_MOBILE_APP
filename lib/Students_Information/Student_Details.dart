import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';


class Student_Details extends StatefulWidget {
  @override
  _Student_DetailsState createState() => _Student_DetailsState();
}

class _Student_DetailsState extends State<Student_Details> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Controllers for text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? studentClass;
  String? studentGender;
  String? studentID;
  String? generatedQRcode;
  String? studentFullName;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  // Fetch the current logged-in user
  User? loggedInUser;
  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

  // Generate a random student ID
  String generateRandomStudentID() {
    Random random = Random();
    int id = 100000 + random.nextInt(900000);
    return id.toString();
  }


  void saveStudentDetails() async {
    if (_formKey.currentState!.validate()) {
      // Create a unique student ID and combine the full name
      studentFullName = '${_lastNameController.text.trim().toUpperCase()} ${_firstNameController.text.trim().toUpperCase()}';
      studentID = generateRandomStudentID();  // Generate a new student ID



      // Define default subjects for each form
      final defaultSubjects = {
        'FORM 1': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
        'FORM 2': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
        'FORM 3': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
        'FORM 4': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
      };

      try {
        // Assuming the school name is stored in the teacher's details
        final teacherEmail = loggedInUser?.email;
        final teacherDetails = await _firestore.collection('Teachers_Details').doc(teacherEmail).get();
        String schoolName = teacherDetails['school'];

        // Save the student details under the corresponding school and class
        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentFullName)
            .set({
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create the Student_Biography document containing student details
        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentFullName)
            .collection('Personal_Information')
            .doc('Registered_Information') // Single document for biography details
            .set({
          'firstName': _firstNameController.text.trim().toUpperCase(),
          'lastName': _lastNameController.text.trim().toUpperCase(),
          'studentClass': studentClass!,
          'studentAge': _ageController.text.trim(),
          'studentGender': studentGender!,
          'studentID': studentID!,
          'createdBy': loggedInUser?.email ?? '',
          'timestamp': FieldValue.serverTimestamp(), // Timestamp
        });

        // Create the Student_Subjects documents with default grades
        for (String subject in defaultSubjects[studentClass]!) {
          await _firestore
              .collection('Schools')
              .doc(schoolName)
              .collection('Classes')
              .doc(studentClass)
              .collection('Student_Details')
              .doc(studentFullName)
              .collection('Student_Subjects')
              .doc(subject) // Use the subject name as the document ID
              .set({
            'Subject_Name': subject,
            'Subject_Grade': 'N/A', // Default grade for all subjects
          });
        }

        // Add TOTAL_MARKS document
        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentFullName)
            .collection('TOTAL_MARKS')
            .doc('Marks') // Single document for total marks
            .set({
          'Best_Six_Total_Points': '0',
          'Student_Total_Marks': '0', // Default total marks
          'Teacher_Total_Marks': '0',
        });

        // Encode the QR code with the studentID
        setState(() {
          generatedQRcode = studentID;  // Encode only the studentID in the QR code
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student Details saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving Student Details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


// Generate a random number to append to the ID for uniqueness
  String generateRandomNumber() {
    Random random = Random();
    return random.nextInt(1000).toString(); // Generate a random number between 0-999
  }


  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enter Student Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildStyledTextFormField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the student\'s first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildStyledTextFormField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the student\'s last name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildStyledDropdownField(
                      value: studentClass,
                      labelText: 'Class',
                      items: ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'],
                      onChanged: (newValue) {
                        setState(() {
                          studentClass = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the student\'s Class';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildStyledTextFormField(
                      controller: _ageController,
                      labelText: 'Age',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the student\'s Age';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Please enter a valid Age';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildStyledDropdownField(
                      value: studentGender,
                      labelText: 'Gender',
                      items: ['Male', 'Female'],
                      onChanged: (newValue) {
                        setState(() {
                          studentGender = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the student\'s Gender';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: saveStudentDetails,
                            child: Text(
                              'Save & Generate QR Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              if (generatedQRcode != null) ...[
                Text(
                  'Below is the QR Code Generated:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: generatedQRcode!,
                    width: 200,
                    height: 200,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Student ID: $studentID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Custom styled text form field
  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Custom styled dropdown form field
  Widget _buildStyledDropdownField({
    required String? value,
    required String labelText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

