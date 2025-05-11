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
  _Seniors_School_Report_ViewState createState() =>
      _Seniors_School_Report_ViewState();
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

      final teacherSnapshot =
      await _firestore.doc('Teachers_Details/$teacherEmail').get();
      if (!teacherSnapshot.exists) throw 'Teacher details not found.';

      final teacherData = teacherSnapshot.data()!;
      teacherSchoolName = teacherData['school'];
      final teacherClasses = List<String>.from(teacherData['classes'] ?? []);

      if (!teacherClasses.contains(widget.studentClass.trim())) {
        throw 'You do not have permission to view this student\'s data.';
      }

      final trimmedSchool = teacherSchoolName?.trim();
      final trimmedClass = widget.studentClass.trim();

      // Step 1: Get the student name from fallback
      final fallbackDoc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(trimmedSchool)
          .collection('Classes')
          .doc(trimmedClass)
          .collection('Student_Details')
          .doc('N/A N/A')
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (!fallbackDoc.exists) throw 'Fallback student not found.';

      final fallbackData = fallbackDoc.data()!;
      final firstName = (fallbackData['firstName'] ?? '').toString().trim().toUpperCase();
      final lastName = (fallbackData['lastName'] ?? '').toString().trim().toUpperCase();

      final studentFullName = '$lastName $firstName'; // 🧠 Last name first
      print('📁 Student Document ID: $studentFullName');

      final studentRef = FirebaseFirestore.instance
          .collection('Schools')
          .doc(trimmedSchool)
          .collection('Classes')
          .doc(trimmedClass)
          .collection('Student_Details')
          .doc(studentFullName);

      // Step 2: Fetch personal info
      final personalInfo = await studentRef
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (personalInfo.exists) {
        final info = personalInfo.data()!;
        print('\n📋 Student Information:');
        print('First Name: ${info['firstName']}');
        print('Last Name: ${info['lastName']}');
        print('Age: ${info['studentAge']}');
        print('Gender: ${info['studentGender']}');
        print('Class: ${info['studentClass']}');
        print('Student ID: ${info['studentID']}');
      }

      // Step 3: Fetch subjects
      final subjects = await studentRef.collection('Subjects').get();
      print('\n📚 Subjects:');
      for (var doc in subjects.docs) {
        final data = doc.data();
        print('Subject: ${data['Subject_Name']}, Grade: ${data['Subject_Grade']}');
      }

      // Step 4: Fetch total marks
      final marksDoc = await studentRef.collection('TOTAL_MARKS').doc('Marks').get();
      if (marksDoc.exists) {
        final marks = marksDoc.data()!;
        print('\n📊 Total Marks:');
        print('Teacher Total: ${marks['Teacher_Total_Marks']}');
        print('Student Points: ${marks['Total_Student_Points']}');
      }

    } catch (e) {
      print('❌ Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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
              const Text('Subjects & Grades:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          Text('Grade: ${subject['grade'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                          Text('Grade Points: ${subject['points'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
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
                Text('Best Six Total Points: $bestSixTotalPoints', style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
