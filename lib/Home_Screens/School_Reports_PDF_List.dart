import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../School_Report/Juniors_School_Reports_PDF_Lists.dart';
import '../School_Report/Seniors_School_Reports_PDF_Lists.dart';

class School_Reports_PDF_List extends StatefulWidget {
  @override
  _School_Reports_PDF_ListState createState() => _School_Reports_PDF_ListState();
}

class _School_Reports_PDF_ListState extends State<School_Reports_PDF_List> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _navigateToReportsPage();
  }

  Future<void> _navigateToReportsPage() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        _showErrorAndReturn('No user is currently logged in.');
        return;
      }

      // Get teacher details
      DocumentSnapshot userDoc = await _firestore
          .collection('Teachers_Details')
          .doc(user.email!)
          .get();

      if (!userDoc.exists) {
        _showErrorAndReturn('User details not found.');
        return;
      }

      // Check if teacher has selected school and classes
      if (userDoc['school'] == null ||
          userDoc['classes'] == null ||
          userDoc['classes'].isEmpty) {
        _showErrorAndReturn('Please select a School and Classes before accessing PDF reports.');
        return;
      }

      String teacherSchool = userDoc['school'];
      List<String> teacherClasses = List<String>.from(userDoc['classes']);

      // Navigate to appropriate reports page based on classes taught
      if (_hasJuniorClasses(teacherClasses)) {
        // Navigate to Juniors page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Juniors_School_Reports_PDF_List(
              schoolName: teacherSchool,
              className: _getFirstJuniorClass(teacherClasses),
              studentClass: _getFirstJuniorClass(teacherClasses),
              studentFullName: '',
            ),
          ),
        );
      } else if (_hasSeniorClasses(teacherClasses)) {
        // Navigate to Seniors page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Seniors_School_Reports_PDF_List(
              schoolName: teacherSchool,
              className: _getFirstSeniorClass(teacherClasses),
              studentClass: _getFirstSeniorClass(teacherClasses),
              studentFullName: '',
            ),
          ),
        );
      } else {
        _showErrorAndReturn('No valid classes found for PDF reports.');
      }

    } catch (e) {
      print("Error in navigation: $e");
      _showErrorAndReturn('Please select a School and Classes before accessing PDF Reports.');
    }
  }

  bool _hasJuniorClasses(List<String> classes) {
    return classes.any((cls) =>
    cls.toUpperCase() == 'FORM 1' || cls.toUpperCase() == 'FORM 2');
  }

  bool _hasSeniorClasses(List<String> classes) {
    return classes.any((cls) =>
    cls.toUpperCase() == 'FORM 3' || cls.toUpperCase() == 'FORM 4');
  }

  String _getFirstJuniorClass(List<String> classes) {
    return classes.firstWhere(
          (cls) => cls.toUpperCase() == 'FORM 1' || cls.toUpperCase() == 'FORM 2',
      orElse: () => 'FORM 1',
    );
  }

  String _getFirstSeniorClass(List<String> classes) {
    return classes.firstWhere(
          (cls) => cls.toUpperCase() == 'FORM 3' || cls.toUpperCase() == 'FORM 4',
      orElse: () => 'FORM 3',
    );
  }

  void _showErrorAndReturn(String message) {
    // Show error message and navigate back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while navigation is happening
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading PDF Reports...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}