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

      final subjects = await studentRef.collection('Subjects').get();
      print('\n📚 Subjects:');
      for (var doc in subjects.docs) {
        final data = doc.data();
        print('Subject: ${data['Subject_Name']}, Grade: ${data['Subject_Grade']}');
      }

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
      appBar: AppBar(title: const Text('Junior Student Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School and Student Header
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
                    'School: ${teacherSchoolName ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${widget.studentName}',
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

            // Student Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Divider(),
                  Text('First Name: ${studentInfo?['firstName'] ?? 'N/A'}'),
                  Text('Last Name: ${studentInfo?['lastName'] ?? 'N/A'}'),
                  Text('Age: ${studentInfo?['studentAge'] ?? 'N/A'}'),
                  Text('Gender: ${studentInfo?['studentGender'] ?? 'N/A'}'),
                  Text('Student ID: ${studentInfo?['studentID'] ?? 'N/A'}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Subjects and Grades Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subjects & Grades:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Divider(),
                  if (subjectsWithGrades != null && subjectsWithGrades!.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: subjectsWithGrades!.length,
                      itemBuilder: (context, index) {
                        final subject = subjectsWithGrades!.values.toList()[index];
                        return ListTile(
                          title: Text(subject['subject'] ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Grade: ${subject['grade'] ?? 'N/A'}'),
                              Text('Grade Points: ${subject['points'] ?? 'N/A'}'),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    const Text('No subjects available'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Total Marks Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Marks:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Divider(),

                  Text('Teacher Total Marks: $teacherTotalMarks'),
                  Text('Student Total Marks: $bestSixTotalPoints'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
