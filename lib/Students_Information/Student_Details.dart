import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Student_Details extends StatefulWidget {
  @override
  _Student_DetailsState createState() => _Student_DetailsState();
}

class _Student_DetailsState extends State<Student_Details> {
  // Form and Firebase instances
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // State variables
  String? studentClass;
  String? studentGender;
  String? studentID;
  String? generatedQRcode;
  String? studentFullName;
  User? loggedInUser;

  // Default subjects for each form
  final Map<String, List<String>> defaultSubjects = {

    'FORM 1': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH','GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS', 'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'],
    'FORM 2': ['AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS',  'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'],
    'FORM 3': ['ADDITIONAL MATHEMATICS', 'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS',  'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'],
    'FORM 4': ['ADDITIONAL MATHEMATICS', 'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS',  'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'],


  };

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Get current logged-in user
  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

  // Generate a random 6-digit student ID
  String generateRandomStudentID() {
    Random random = Random();
    int id = 100000 + random.nextInt(900000);
    return id.toString();
  }

  // Calculate age based on DOB in DD-MM-YYYY format
  int calculateAge(String dob) {
    try {
      DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      DateTime birthDate = dateFormat.parse(dob);
      DateTime currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;

      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0; // Return 0 if parsing fails
    }
  }

  // Validate date format and future date
  String? validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the student\'s Date of Birth';
    }

    // Check if the format is correct (DD-MM-YYYY)
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
      return 'Please enter date in DD-MM-YYYY format';
    }

    try {
      DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      DateTime dob = dateFormat.parseStrict(value);

      if (dob.isAfter(DateTime.now())) {
        return 'Date of Birth cannot be in the future';
      }

      // Check if the date is reasonable (not too old)
      if (DateTime.now().year - dob.year > 100) {
        return 'Please enter a valid Date of Birth';
      }

    } catch (e) {
      return 'Please enter a valid Date of Birth (DD-MM-YYYY)';
    }

    return null;
  }

  // Save student details to Firestore
  void saveStudentDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white, // Set to white
              ),
            );
          },
        );


        // Create student data
        studentFullName = '${_lastNameController.text.trim().toUpperCase()}'
            ' ${_firstNameController.text.trim().toUpperCase()}';
        studentID = generateRandomStudentID();

        // Get teacher's school information
        final teacherEmail = loggedInUser?.email;
        final teacherDetails = await _firestore
            .collection('Teachers_Details')
            .doc(teacherEmail)
            .get();

        if (!teacherDetails.exists) {
          throw Exception('Teacher details not found');
        }

        String schoolName = teacherDetails['school'];

        // Save main student document
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

        // Save student personal information (keeping DOB in DD-MM-YYYY format)
        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentFullName)
            .collection('Personal_Information')
            .doc('Registered_Information')
            .set({
          'firstName': _firstNameController.text.trim().toUpperCase(),
          'lastName': _lastNameController.text.trim().toUpperCase(),
          'studentClass': studentClass!,
          'studentDOB': _dobController.text.trim(), // Saved in DD-MM-YYYY format
          'studentAge': calculateAge(_dobController.text.trim()).toString(),
          'studentGender': studentGender!,
          'studentID': studentID!,
          'createdBy': loggedInUser?.email ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create student subjects with default grades
        final batch = _firestore.batch();
        for (String subject in defaultSubjects[studentClass]!) {
          final subjectRef = _firestore
              .collection('Schools')
              .doc(schoolName)
              .collection('Classes')
              .doc(studentClass)
              .collection('Student_Details')
              .doc(studentFullName)
              .collection('Student_Subjects')
              .doc(subject);

          batch.set(subjectRef, {
            'Subject_Name': subject,
            'Subject_Grade': 'N/A',
          });
        }
        await batch.commit();

        // Add total marks document
        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentFullName)
            .collection('TOTAL_MARKS')
            .doc('Marks')
            .set({
          'Aggregate_Grade': 'N/A',
          'Best_Six_Total_Points': 0,
          'Student_Total_Marks': '0',
          'Teacher_Total_Marks': '0',
        });

        // Generate QR code with student ID
        setState(() {
          generatedQRcode = studentID;
        });

        // Hide loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student Details saved successfully!'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 3),
          ),
        );

      } catch (e) {
        // Hide loading indicator
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving Student Details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enter Student Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
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
              _buildForm(),
              SizedBox(height: 40),
              _buildQRCodeSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Build main form
  Widget _buildForm() {
    return Form(
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
              if (value.length < 2) {
                return 'First name must be at least 2 characters';
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
              if (value.length < 2) {
                return 'Last name must be at least 2 characters';
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
                return 'Please select the student\'s class';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          _buildStyledTextFormField(
            controller: _dobController,
            labelText: 'Date of Birth (DD-MM-YYYY)',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              _DateInputFormatter(),
            ],
            validator: validateDateOfBirth,
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
                return 'Please select the student\'s gender';
              }
              return null;
            },
          ),
          SizedBox(height: 32),

          _buildActionButtons(),
        ],
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
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
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
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
    );
  }

  // Build QR code section
  Widget _buildQRCodeSection() {
    if (generatedQRcode == null) return SizedBox.shrink();

    return Column(
      children: [
        Text(
          'QR Code Generated Successfully!',
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
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: generatedQRcode!,
                width: 200,
                height: 200,
              ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Student ID: $studentID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        Text(
          'Save this QR code for student identification',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Custom styled text form field
  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
      ),
    );
  }
}

// Custom date input formatter for DD-MM-YYYY format
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text.replaceAll('-', '');
    var newText = '';

    for (int i = 0; i < text.length && i < 8; i++) {
      newText += text[i];
      if ((i == 1 || i == 3) && i != text.length - 1) {
        newText += '-';
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}



