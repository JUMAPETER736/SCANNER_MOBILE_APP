

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentName;

  const School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentName,
    Key? key,
  }) : super(key: key);

  @override
  _School_Report_ViewState createState() => _School_Report_ViewState();
}

class _School_Report_ViewState extends State<School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? teacherSchoolName; // <-- Added this
  Map<String, dynamic>? studentInfo;
  List<Map<String, dynamic>> subjectsWithGrades = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      // Fetch teacher's details
      DocumentSnapshot teacherSnapshot = await _firestore
          .doc('Teachers_Details/${FirebaseAuth.instance.currentUser?.email}')
          .get();

      if (!teacherSnapshot.exists) {
        throw 'Teacher details not found!';
      }

      Map<String, dynamic> teacherData = teacherSnapshot.data() as Map<String, dynamic>;

      // Get teacher's school and classes
      teacherSchoolName = teacherData['school'] ?? 'Unknown School';
      List<dynamic> teacherClasses = teacherData['classes'] ?? [];

      // Check if the teacher teaches this class
      if (!teacherClasses.contains(widget.studentClass)) {
        throw 'You do not have permission to view this student data';
      }

      String studentPath = 'Schools/$teacherSchoolName/Classes/${widget.studentClass}/Student_Details/${widget.studentName}';

      // Fetch student's personal info
      DocumentSnapshot personalInfoSnapshot = await _firestore
          .doc('$studentPath/Personal_Information/Registered_Information')
          .get();

      // Fetch student's subjects and grades
      QuerySnapshot subjectsSnapshot = await _firestore
          .collection('$studentPath/Student_Subjects')
          .get();

      setState(() {
        studentInfo = personalInfoSnapshot.exists
            ? personalInfoSnapshot.data() as Map<String, dynamic>?
            : {};

        subjectsWithGrades = subjectsSnapshot.docs.map((doc) {
          return {
            'subject': doc['Subject_Name'] ?? 'Unknown',
            'grade': doc['Subject_Grade'] ?? 'N/A',
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching student data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Report Card')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teacherSchoolName ?? 'Loading school...',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Student Name: ${widget.studentName}', style: const TextStyle(fontSize: 18)),
            if (studentInfo != null) ...[
              Text('Age: ${studentInfo!['studentAge'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Class: ${studentInfo!['studentClass'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Gender: ${studentInfo!['studentGender'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            ],
            const Divider(),
            const SizedBox(height: 8),
            if (subjectsWithGrades.isNotEmpty) ...[
              const Text('Subjects & Grades:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: subjectsWithGrades.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(subjectsWithGrades[index]['subject'], style: const TextStyle(fontSize: 16)),
                      subtitle: Text('Grade: ${subjectsWithGrades[index]['grade']}', style: const TextStyle(fontSize: 14)),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('No subjects available', style: TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
