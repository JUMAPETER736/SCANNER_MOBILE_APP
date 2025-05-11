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

  String? teacherSchoolName;
  Map<String, dynamic>? studentInfo;
  Map<String, dynamic>? subjectsWithGrades = {};
  String? studentTotalMarks;
  String? teacherTotalMarks;
  String? bestSixTotalPoints;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentDataAndSubjects();
  }

  Future<void> fetchStudentDataAndSubjects() async {
    setState(() {
      isLoading = true;
    });

    try {
      final teacherEmail = FirebaseAuth.instance.currentUser?.email;
      if (teacherEmail == null) throw 'User not authenticated.';

      print('🔐 Teacher email: $teacherEmail');

      final teacherSnapshot = await _firestore.doc('Teachers_Details/$teacherEmail').get();
      if (!teacherSnapshot.exists) throw 'Teacher details not found.';

      final teacherData = teacherSnapshot.data()!;
      teacherSchoolName = teacherData['school'];
      final teacherClasses = List<String>.from(teacherData['classes'] ?? []);

      print('🏫 Teacher School: $teacherSchoolName');
      print('📚 Teacher Classes: $teacherClasses');

      if (!teacherClasses.contains(widget.studentClass.trim())) {
        throw 'You do not have permission to view this student\'s data.';
      }

      final trimmedSchool = widget.schoolName.trim();
      final trimmedClass = widget.studentClass.trim();
      final trimmedStudent = widget.studentName.trim();

      print(' Looking in path: Schools/$trimmedSchool/Classes/$trimmedClass/Student_Details/$trimmedStudent');

      final studentRef = _firestore
          .collection('Schools')
          .doc(trimmedSchool)
          .collection('Classes')
          .doc(trimmedClass)
          .collection('Student_Details')
          .doc(trimmedStudent);

      // Fetch Registered Information
      final personalInfoDoc = await studentRef
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (personalInfoDoc.exists) {
        studentInfo = personalInfoDoc.data();
        print('Student info: $studentInfo');
      } else {
        print('No Registered_Information found for this student');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Registered Information found for this student')),
        );
      }

      // Fetch subjects
      final subjectsSnapshot = await studentRef.collection('Student_Subjects').get();
      subjectsWithGrades = {};
      for (var doc in subjectsSnapshot.docs) {
        final subjectData = doc.data();
        subjectsWithGrades![doc.id] = {
          'subject': subjectData['Subject_Name'],
          'grade': subjectData['Subject_Grade'],
          'points': subjectData['Grade_Point'],
        };
      }

      // Fetch TOTAL MARKS
      final totalMarksDoc = await studentRef.collection('TOTAL_MARKS').doc('Marks').get();
      if (totalMarksDoc.exists) {
        final data = totalMarksDoc.data();
        studentTotalMarks = data?['Student_Total_Marks'];
        teacherTotalMarks = data?['Teacher_Total_Marks'];
        bestSixTotalPoints = data?['Best_Six_Total_Points'];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('🔥 Error fetching student data: $e');
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
      appBar: AppBar(title: const Text('Senior Student Report')),
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
              Text('Age: ${studentInfo!['studentAge'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Student ID: ${studentInfo!['studentID'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Class: ${studentInfo!['studentClass'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              Text('Gender: ${studentInfo!['studentGender'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            ] else ...[
              const Text('Student personal info not available.', style: TextStyle(fontSize: 16)),
            ],

            const Divider(),
            const SizedBox(height: 8),

            if (subjectsWithGrades != null && subjectsWithGrades!.isNotEmpty) ...[
              const Text('Subjects & Grades:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: subjectsWithGrades!.length,
                  itemBuilder: (context, index) {
                    final subject = subjectsWithGrades!.values.toList()[index];
                    return ListTile(
                      title: Text(subject['subject'] ?? 'N/A', style: const TextStyle(fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grade: ${subject['grade'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14)),
                          Text('Grade Points: ${subject['points'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('No subjects available', style: TextStyle(fontSize: 16)),
            ],

            const SizedBox(height: 8),

            if (studentTotalMarks != null || teacherTotalMarks != null || bestSixTotalPoints != null) ...[
              const Divider(),
              if (studentTotalMarks != null)
                Text('Student Total Marks: $studentTotalMarks', style: const TextStyle(fontSize: 16)),
              if (teacherTotalMarks != null)
                Text('Teacher Total Marks: $teacherTotalMarks', style: const TextStyle(fontSize: 16)),
              if (bestSixTotalPoints != null)
                Text('Best Six Total Points: $bestSixTotalPoints',
                    style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
