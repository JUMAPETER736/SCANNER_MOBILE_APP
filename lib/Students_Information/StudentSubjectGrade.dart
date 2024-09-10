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
      DocumentSnapshot studentDoc = await _firestore
          .collection('SchoolReports')
          .doc(_userClass!)
          .collection('StudentReports')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        List<Map<String, dynamic>> grades = List<Map<String, dynamic>>.from(studentDoc['grades']);
        return grades;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching Student Subjects & Grades: $e');
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
              separatorBuilder: (context, index) => SizedBox(height: 5),
              itemBuilder: (context, index) {
                var subject = grades[index]['name'] ?? 'Unknown Subject';
                var grade = grades[index]['grade'] ?? 'N/A';

                // Check if the grade is a number and append '%' if true
                if (grade is int || grade is double) {
                  grade = '$grade%';
                }

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
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Text(
                      '${index + 1}', // Displaying just the number
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Text(
                      'Grade: $grade', // Grade shown on the right with %
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
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
