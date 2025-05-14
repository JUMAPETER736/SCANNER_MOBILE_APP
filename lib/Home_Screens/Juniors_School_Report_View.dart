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

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? teacherSchoolName;
  Map<String, dynamic>? studentInfo;
  Map<String, dynamic>? subjectsWithGrades = {};
  String? studentTotalMarks;
  String? teacherTotalMarks;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use the student name passed through the widget
    findStudentDocIDAndFetch(widget.studentName);
  }



  Future<void> findStudentDocIDAndFetch(String studentName) async {
    final studentRef = FirebaseFirestore.instance.collection('Schools')
        .doc(widget.schoolName) // Use the dynamic school name
        .collection('Classes')
        .doc(widget.studentClass) // Use the dynamic student class
        .collection('Student_Details');

    // Fetch personal information from the correct path
    final studentDoc = await studentRef
        .where('fullName', isEqualTo: studentName) // Use a dynamic query if student name is part of the document
        .get();

    if (studentDoc.docs.isNotEmpty) {
      final studentData = studentDoc.docs.first.data();
      final firstName = studentData['firstName'] ?? 'N/A';
      final lastName = studentData['lastName'] ?? 'N/A';
      final age = studentData['studentAge']?.toString() ?? 'N/A';
      final gender = studentData['studentGender'] ?? 'N/A';
      final studentID = studentData['studentID']?.toString() ?? 'N/A';
      final studentClass = studentData['studentClass'] ?? 'N/A';

      print('📋 Student Information for $studentName:');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Age: $age');
      print('Gender: $gender');
      print('Student ID: $studentID');
      print('Class: $studentClass');

      setState(() {
        studentInfo = {
          'firstName': firstName,
          'lastName': lastName,
          'studentAge': age,
          'studentGender': gender,
          'studentID': studentID,
          'studentClass': studentClass,
        };
      });
    } else {
      print('❌ Error: Student $studentName not found.');
    }

    // Fetch subjects and grades
    final subjectsRef = studentRef.doc(studentDoc.docs.first.id).collection('Student_Subjects');
    final subjectsSnapshot = await subjectsRef.get();

    if (subjectsSnapshot.docs.isNotEmpty) {
      print('\n📚 Subjects for $studentName:');
      for (var subjectDoc in subjectsSnapshot.docs) {
        final subjectName = subjectDoc.id; // Subject Name (e.g., CHEMISTRY)
        final subjectGrade = subjectDoc.data()['Subject_Grade'] ?? 'N/A'; // Grade for the subject
        print('Subject: $subjectName');
        print('Grade: $subjectGrade');

        setState(() {
          subjectsWithGrades![subjectName] = {
            'subject': subjectName,
            'grade': subjectGrade,
          };
        });
      }
    } else {
      print('⚠️ No subjects found for student $studentName');
    }

    // Fetch total marks (from TOTAL_MARKS/Marks)
    final marksDoc = await studentRef
        .doc(studentDoc.docs.first.id)
        .collection('TOTAL_MARKS')
        .doc('Marks')
        .get();

    if (marksDoc.exists) {
      final marks = marksDoc.data()!;
      final studentTotalMarks = marks['Student_Total_Marks']?.toString() ?? 'N/A';
      final teacherTotalMarks = marks['Teacher_Total_Marks']?.toString() ?? 'N/A';

      print('\n📊 Total Marks for $studentName:');
      print('Student Total: $studentTotalMarks');
      print('Teacher Total: $teacherTotalMarks');

      setState(() {
        this.studentTotalMarks = studentTotalMarks;
        this.teacherTotalMarks = teacherTotalMarks;
      });
    } else {
      print('⚠️ TOTAL_MARKS/Marks not found for $studentName');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Junior Student Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School: ${widget.schoolName ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${studentInfo?['firstName'] ?? 'N/A'} ${studentInfo?['lastName'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Class: ${widget.studentClass}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Info
            buildCardSection(
              title: 'Personal Information:',
              children: [
                Text('First Name: ${studentInfo?['firstName'] ?? 'N/A'}'),
                Text('Last Name: ${studentInfo?['lastName'] ?? 'N/A'}'),
                Text('Age: ${studentInfo?['studentAge'] ?? 'N/A'}'),
                Text('Gender: ${studentInfo?['studentGender'] ?? 'N/A'}'),
                Text('Student ID: ${studentInfo?['studentID'] ?? 'N/A'}'),
              ],
            ),

            const SizedBox(height: 20),

            // Subjects
            buildCardSection(
              title: 'Subjects & Grades:',
              children: subjectsWithGrades != null &&
                  subjectsWithGrades!.isNotEmpty
                  ? subjectsWithGrades!.values.map((subject) {
                return ListTile(
                  title: Text(subject['subject'] ?? 'N/A'),
                  subtitle: Text('Grade: ${subject['grade'] ?? 'N/A'}'),
                );
              }).toList()
                  : [const Text('No subjects available')],
            ),

            const SizedBox(height: 20),

            // Total Marks
            buildCardSection(
              title: 'Total Marks:',
              children: [
                Text('Student Total Marks: $studentTotalMarks'),
                Text('Teacher Total Marks: $teacherTotalMarks'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCardSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}
