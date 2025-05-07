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
  _Juniors_School_Report_ViewState createState() => _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
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
      final teacherSnapshot = await _firestore.doc('Teachers_Details/$teacherEmail').get();
      if (!teacherSnapshot.exists) throw 'Teacher details not found.';

      final teacherData = teacherSnapshot.data() as Map<String, dynamic>;
      teacherSchoolName = teacherData['school'];
      final teacherClasses = List<String>.from(teacherData['classes'] ?? []);

      if (!teacherClasses.contains(widget.studentClass)) {
        throw 'You do not have permission to view this student\'s data.';
      }

      // Build student base path
      final studentBasePath = 'Schools/$teacherSchoolName/Classes/${widget.studentClass}/Student_Details/${widget.studentName}';

      // Fetch personal info
      final personalSnapshot = await _firestore.doc('$studentBasePath/Personal_Information/Registered_Information').get();

      // Fetch subject grades
      final subjectSnapshots = await _firestore.collection('$studentBasePath/Student_Subjects').get();

      // Fetch total marks
      final totalMarksSnapshot = await _firestore.doc('$studentBasePath/TOTAL_MARKS/Marks').get();

      setState(() {
        studentInfo = personalSnapshot.data() as Map<String, dynamic>? ?? {};
        subjectsWithGrades = subjectSnapshots.docs.map((doc) {
          return {
            'subject': doc['Subject_Name'] ?? 'Unknown',
            'grade': doc['Subject_Grade'] ?? 'N/A',
          };
        }).toList();

        studentTotalMarks = totalMarksSnapshot['Student_Total_Marks'] ?? 'N/A';
        teacherTotalMarks = totalMarksSnapshot['Teacher_Total_Marks'] ?? 'N/A';

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
              teacherSchoolName ?? 'School: N/A',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (studentInfo != null) ...[
              Text('First Name: ${studentInfo!['firstName'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Last Name: ${studentInfo!['lastName'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
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
                    final subject = subjectsWithGrades[index];
                    return ListTile(
                      title: Text(subject['subject'], style: const TextStyle(fontSize: 16)),
                      subtitle: Text('Grade: ${subject['grade']}', style: const TextStyle(fontSize: 14)),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('No subjects available', style: TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 8),
            if (studentTotalMarks != null && teacherTotalMarks != null) ...[
              const Divider(),
              Text('Student Total Marks: $studentTotalMarks', style: const TextStyle(fontSize: 16)),
              Text('Teacher Total Marks: $teacherTotalMarks', style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
