import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GradeEntryForm extends StatefulWidget {
  final List<String> selectedSubjects; // Pass selected subjects
  final String userId; // Pass the user ID

  GradeEntryForm({required this.selectedSubjects, required this.userId});

  @override
  _GradeEntryFormState createState() => _GradeEntryFormState();
}

class _GradeEntryFormState extends State<GradeEntryForm> {
  final Map<String, String> studentGrades = {}; // Map to hold grades
  final List<String> students = []; // List of students

  @override
  void initState() {
    super.initState();
    _fetchStudents(); // Fetch students from Firestore
  }

  Future<void> _fetchStudents() async {
    try {
      // Fetch student details from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('students')
          .get();

      setState(() {
        // Assuming each document contains a 'name' field
        students.addAll(querySnapshot.docs.map((studentDoc) => studentDoc['name'] as String));
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> _saveGrades() async {
    try {
      // Save grades to Firestore
      for (var student in students) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('grades')
            .doc(student)
            .set({
          'grades': studentGrades[student] ?? {},
        });
      }
      _showToast('Grades saved successfully!');
    } catch (e) {
      print('Error saving grades: $e');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Grades'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter Grades for Selected Subjects',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  String student = students[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ...widget.selectedSubjects.map((subject) {
                            return TextField(
                              decoration: InputDecoration(
                                labelText: 'Enter grade for $subject',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                studentGrades[student] = value; // Store grades
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveGrades,
              child: Text('Save Grades'),
            ),
          ],
        ),
      ),
    );
  }
}
