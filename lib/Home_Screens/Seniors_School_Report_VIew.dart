import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Seniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentName;

  const Seniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentName,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_School_Report_ViewState createState() => _Seniors_School_Report_ViewState();
}

class _Seniors_School_Report_ViewState extends State<Seniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? teacherSchoolName;
  Map<String, dynamic>? studentInfo;
  List<Map<String, dynamic>> subjectsWithGrades = [];
  int? totalPoints;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final teacherDoc = await _firestore.doc('Teachers_Details/${user.email}').get();

      if (!teacherDoc.exists) throw 'Teacher details not found!';

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      teacherSchoolName = teacherData['school'];
      List<dynamic> teacherClasses = teacherData['classes'] ?? [];

      if (!teacherClasses.contains(widget.studentClass)) {
        throw 'Access denied to class: ${widget.studentClass}';
      }

      final studentPath = 'Schools/$teacherSchoolName/Classes/${widget.studentClass}/Student_Details/${widget.studentName}';

      // Get student info
      final personalInfoSnapshot = await _firestore
          .doc('$studentPath/Personal_Information/Registered_Information')
          .get();

      studentInfo = personalInfoSnapshot.exists
          ? personalInfoSnapshot.data() as Map<String, dynamic>
          : {};

      // Get subjects and grades
      final subjectsSnapshot = await _firestore.collection('$studentPath/Student_Subjects').get();
      subjectsWithGrades = subjectsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'subject': data['Subject_Name'] ?? 'Unknown',
          'grade': data['Subject_Grade'] ?? 'N/A',
        };
      }).toList();

      // Get total marks (best six points)
      final totalMarksDoc = await _firestore.doc('$studentPath/TOTAL_MARKS/Marks').get();
      if (totalMarksDoc.exists) {
        totalPoints = totalMarksDoc.data()?['Best_Six_Total_Points'];
      }

      setState(() => isLoading = false);
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
      appBar: AppBar(title: const Text('Senior Student Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School: ${teacherSchoolName ?? "Unknown"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (studentInfo != null) ...[
              Text('Name: ${studentInfo!['firstName'] ?? ''} ${studentInfo!['lastName'] ?? ''}',
                  style: const TextStyle(fontSize: 16)),
              Text('Class: ${studentInfo!['studentClass'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
              Text('Gender: ${studentInfo!['studentGender'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            if (totalPoints != null) ...[
              Text('Best Six Total Points: $totalPoints',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const Text('Subjects & Grades:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: subjectsWithGrades.isNotEmpty
                  ? ListView.builder(
                itemCount: subjectsWithGrades.length,
                itemBuilder: (context, index) {
                  final subject = subjectsWithGrades[index];
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.green),
                    title: Text(subject['subject'], style: const TextStyle(fontSize: 16)),
                    subtitle: Text('Grade: ${subject['grade']}', style: const TextStyle(fontSize: 14)),
                  );
                },
              )
                  : const Text('No subject grades found'),
            ),
          ],
        ),
      ),
    );
  }
}
