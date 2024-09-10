import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentSubjectGrade extends StatefulWidget {
  final String studentId;
  final String firstName;
  final String lastName;

  StudentSubjectGrade({
    required this.studentId,
    required this.firstName,
    required this.lastName,
  });

  @override
  _StudentSubjectGradeState createState() => _StudentSubjectGradeState();
}

class _StudentSubjectGradeState extends State<StudentSubjectGrade> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userClass;

  @override
  void initState() {
    super.initState();
    _getUserClass();
  }

  Future<void> _getUserClass() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('Teacher').doc(user.uid).get();
        if (userDoc.exists) {
          var classes = userDoc['classes'] as List<dynamic>? ?? [];
          if (classes.isNotEmpty) {
            setState(() {
              _userClass = classes[0]; // Assume the first class is selected
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching user class: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStudentSubjectGrades() async {
    if (_userClass == null) {
      return [];
    }

    try {
      List<Map<String, dynamic>> allGrades = [];

      QuerySnapshot gradeQuerySnapshot = await _firestore
          .collection('SchoolReports')
          .doc(_userClass!)
          .collection('StudentReports')
          .get();

      allGrades = gradeQuerySnapshot.docs.map((doc) {
        return {
          'studentId': doc.id,
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'grades': doc['grades'] ?? '', // Ensure 'name' is not null
          'totalMarks': doc['totalMarks'] ?? 0,
          'teacherTotalMarks': doc['teacherTotalMarks'] ?? 0,
          'grades': doc['grades'] ?? [], // Ensure 'grades' is a list
        };
      }).toList();

      if (allGrades.isEmpty) {
        print('No documents found for student ${widget.studentId}');
      } else {
        print('Documents found: ${allGrades.length}');
      }

      return allGrades;
    } catch (e) {
      print('Error fetching Student Subject Grades: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            '${widget.lastName} ${widget.firstName} Subject Grade',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStudentSubjectGrades(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching data',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No Subjects & Grades found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              );
            }

            List<Map<String, dynamic>> grades = snapshot.data!;

            return ListView.separated(
              itemCount: grades.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var grade = grades[index];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '${grade['grades']?.toUpperCase() ?? 'UNKNOWN SUBJECT'}', // Handle null values
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Text(
                      'Grade: ${grade['grade'] ?? 'N/A'}', // Handle null values
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
