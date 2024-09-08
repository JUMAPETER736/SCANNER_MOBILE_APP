

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolReports extends StatefulWidget {
  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    try {
      // Replace 'FORM 1' with the actual class if needed
      final snapshot = await _firestore.collection('Students').doc('FORM 1').collection('StudentDetails').get();
      final List<Map<String, dynamic>> students = snapshot.docs.map((doc) => {
        'name': doc['name'],
        'position': doc['position']
      }).toList();

      setState(() {
        _students = students;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Reports'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['name']),
            trailing: Text('Position: ${student['position']}'),
          );
        },
      ),
    );
  }
}
