import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/School_Report/Juniors_School_Reports_PDF_Lists.dart';
import 'package:scanna/School_Report/Seniors_School_Reports_PDF_Lists.dart';

// Dummy placeholders for actual report view pages
class Juniors_School_Report_View extends StatelessWidget {
  final String studentClass;
  final String studentFullName;

  Juniors_School_Report_View({required this.studentClass, required this.studentFullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Junior Report')),
      body: Center(child: Text('Viewing Junior Report for $studentFullName')),
    );
  }
}

class Seniors_School_Report_View extends StatelessWidget {
  final String studentClass;
  final String studentFullName;

  Seniors_School_Report_View({required this.studentClass, required this.studentFullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Senior Report')),
      body: Center(child: Text('Viewing Senior Report for $studentFullName')),
    );
  }
}

class School_Reports_PDF_List extends StatefulWidget {
  @override
  _School_Reports_PDF_ListState createState() => _School_Reports_PDF_ListState();
}

class _School_Reports_PDF_ListState extends State<School_Reports_PDF_List> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userEmail;
  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> classStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userEmail = user.email!;

      try {
        DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

        if (userDoc.exists) {
          if (userDoc['school'] == null || userDoc['classes'] == null || userDoc['classes'].isEmpty) {
            setState(() {
              hasError = true;
              errorMessage = 'Please select a School and Classes before accessing reports.';
              isLoading = false;
            });
          } else {
            setState(() {
              teacherSchool = userDoc['school'];
              teacherClasses = List<String>.from(userDoc['classes']);
              selectedClass = teacherClasses![0];
              _hasSelectedCriteria = true;
              isLoading = true;
            });

            await _fetchStudentDetailsForClass(userDoc, selectedClass!);
          }
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'User details not found.';
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Classes before accessing School Reports.';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
    }
  }

  Future<void> _fetchStudentDetailsForClass(DocumentSnapshot userDoc, String classId) async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(userDoc['school'])
          .collection('Classes')
          .doc(classId)
          .collection('Student_Details')
          .get();

      setState(() {
        classStudents = studentsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          return {
            'fullName': '$firstName $lastName',
            'studentClass': data['studentClass'] ?? '',
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching student data: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load students for class $classId.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Students PDFs'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text(errorMessage))
          : classStudents.isEmpty
          ? Center(child: Text('No student records found.'))
          : ListView.builder(
        itemCount: classStudents.length,
        itemBuilder: (context, index) {
          final student = classStudents[index];
          final fullName = student['fullName'];

          return ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            title: Text(fullName),
            onTap: () {
              String studentClass = student['studentClass']?.toUpperCase() ?? '';

              if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Juniors_School_Report_PDF(
                      studentClass: studentClass,
                      studentFullName: fullName,
                    ),
                  ),
                );
              } else if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Seniors_School_Reports_PDF_List(
                      studentClass: studentClass,
                      studentFullName: fullName,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unknown Student Class: $studentClass')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
