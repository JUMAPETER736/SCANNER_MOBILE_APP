

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Juniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentName;

  const Juniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() =>
      _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState
    extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? teacherSchoolName;
  Map<String, dynamic>? studentInfo;
  List<Map<String, dynamic>> subjectsWithGrades = [];
  String? studentTotalMarks;
  String? teacherTotalMarks;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final teacherEmail = FirebaseAuth.instance.currentUser?.email;
      if (teacherEmail == null) throw 'User not authenticated.';

      // Fetch teacher's school and classes
      final teacherSnapshot =
      await _firestore.doc('Teachers_Details/$teacherEmail').get();
      if (!teacherSnapshot.exists) throw 'Teacher details not found.';

      final teacherData = teacherSnapshot.data() as Map<String, dynamic>;
      teacherSchoolName = teacherData['school'];
      final teacherClasses = List<String>.from(teacherData['classes'] ?? []);

      if (!teacherClasses.contains(widget.studentClass)) {
        throw 'You do not have permission to view this student\'s data.';
      }

      final studentRef = _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentName);

      // 1. Fetch Registered Information
      final personalInfoDoc = await studentRef
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      studentInfo =
      personalInfoDoc.exists ? personalInfoDoc.data() ?? {} : {};

      // 2. Fetch All Student Subjects
      final subjectsSnapshot =
      await studentRef.collection('Student_Subjects').get();
      subjectsWithGrades = subjectsSnapshot.docs
          .map((doc) => {'subject': doc.id, 'grade': doc['grade'] ?? 'N/A'})
          .toList();

      // 3. Fetch Total Marks
      final totalMarksDoc =
      await studentRef.collection('TOTAL_MARKS').doc('Marks').get();
      if (totalMarksDoc.exists) {
        studentTotalMarks = totalMarksDoc.data()?['studentTotal']?.toString();
        teacherTotalMarks = totalMarksDoc.data()?['teacherTotal']?.toString();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Junior Report Card')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teacherSchoolName ?? 'School: N/A',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (studentInfo != null) ...[
              Text('First Name: ${studentInfo!['firstName'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
              Text('Last Name: ${studentInfo!['lastName'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
              Text('Class: ${studentInfo!['studentClass'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
              Text('Gender: ${studentInfo!['studentGender'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
            ],
            const Divider(),
            const SizedBox(height: 8),
            if (subjectsWithGrades.isNotEmpty) ...[
              const Text('Subjects & Grades:',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: subjectsWithGrades.length,
                  itemBuilder: (context, index) {
                    final subject = subjectsWithGrades[index];
                    return ListTile(
                      title: Text(subject['subject'],
                          style: const TextStyle(fontSize: 16)),
                      subtitle: Text('Grade: ${subject['grade']}',
                          style: const TextStyle(fontSize: 14)),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('No subjects available',
                  style: TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 8),
            if (studentTotalMarks != null &&
                teacherTotalMarks != null) ...[
              const Divider(),
              Text('Student Total Marks: $studentTotalMarks',
                  style: const TextStyle(fontSize: 16)),
              Text('Teacher Total Marks: $teacherTotalMarks',
                  style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
