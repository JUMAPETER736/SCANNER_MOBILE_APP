import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolReports extends StatefulWidget {
  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _students = [];
  int _teacherTotalMarks = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    User? user = _auth.currentUser;

    if (user == null) {
      print('User is not authenticated');
      return;
    }

    try {
      // Fetch class information for the current teacher
      final teacherDoc = await _firestore
          .collection('Teacher')
          .doc(user.uid) // Assuming user ID is the document ID
          .get();

      if (!teacherDoc.exists) {
        print('Teacher document not found');
        return;
      }

      final teacherData = teacherDoc.data();
      final teacherClasses = teacherData?['classes'] as List<dynamic>?;

      if (teacherClasses == null || teacherClasses.isEmpty) {
        print('No classes found for teacher');
        return;
      }

      // Fetch student reports for the first class
      final classId = teacherClasses.first; // Get the first class or replace with specific class
      final studentSnapshot = await _firestore
          .collection('SchoolReports') // Root collection
          .doc(classId) // Document for the class
          .collection('StudentReports') // Subcollection for student reports
          .get();

      if (studentSnapshot.docs.isEmpty) {
        print('No student documents found');
        return;
      }

      final List<Map<String, dynamic>> students = [];

      for (var doc in studentSnapshot.docs) {
        final data = doc.data();
        final subjects = data['Subjects'] as List<dynamic>?;

        final totalMarks = subjects?.fold<int>(
          0,
              (previousValue, subject) {
            final grade = int.tryParse((subject['grade'] ?? '0') as String) ?? 0;
            return previousValue + grade;
          },
        ) ?? 0;

        students.add({
          'name': data['name'],
          'position': data['position'],
          'gender': data['gender'],
          'totalMarks': totalMarks,
        });
      }

      students.sort((a, b) => b['totalMarks'].compareTo(a['totalMarks']));

      // Fetch teacher's total marks
      final teacherDetailsSnapshot = await _firestore
          .collection('Teacher')
          .doc(user.uid)
          .collection('TeacherDetails')
          .doc('TeacherDocumentID') // Replace with the actual teacher document ID
          .get();

      if (!teacherDetailsSnapshot.exists) {
        print('Teacher document not found');
        return;
      }

      final teacherMarks = teacherDetailsSnapshot.data()?['totalMarks'] ?? 0;

      setState(() {
        _students = students;
        _teacherTotalMarks = teacherMarks;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Teacher\'s Total Marks: $_teacherTotalMarks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return ListTile(
                  title: Text(student['name']),
                  subtitle: Text('Gender: ${student['gender']}'),
                  trailing: Text('Marks: ${student['totalMarks']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
