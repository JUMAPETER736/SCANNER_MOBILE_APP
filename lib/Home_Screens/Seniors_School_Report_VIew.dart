import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Seniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentDataAndSubjects();
  }

  Future<void> fetchStudentDataAndSubjects() async {
    print('🔄 Starting to fetch student data and subjects...');
    setState(() {
      isLoading = true;
    });

    try {
      final teacherEmail = FirebaseAuth.instance.currentUser?.email;
      if (teacherEmail == null) throw 'User not authenticated.';
      print('👨‍🏫 Authenticated Teacher Email: $teacherEmail');

      final teacherSnapshot = await _firestore.doc('Teachers_Details/$teacherEmail').get();
      if (!teacherSnapshot.exists) throw 'Teacher details not found.';
      print('✅ Fetched teacher details');

      final teacherData = teacherSnapshot.data()!;
      teacherSchoolName = teacherData['school'];
      final teacherClasses = List<String>.from(teacherData['classes'] ?? []);
      print('🏫 Teacher School: $teacherSchoolName');
      print('📚 Teacher Classes: $teacherClasses');

      if (!teacherClasses.contains(widget.studentClass.trim())) {
        throw '⛔ You do not have permission to view this student\'s data.';
      }

      final trimmedSchool = teacherSchoolName?.trim();
      final trimmedClass = widget.studentClass.trim();

      // Correcting the reference to Firestore
      final studentRef = _firestore
          .collection('Schools') // Fetch the Schools collection
          .doc(trimmedSchool) // Document for the specific school
          .collection('Classes') // Fetch the Classes collection
          .doc(trimmedClass) // Document for the specific class
          .collection('Student_Details'); // Student details collection

      final personalInfo = await studentRef
          .doc('Registered_Information') // Fetch a specific student's document
          .get();

      if (personalInfo.exists) {
        studentInfo = personalInfo.data()!;
        print('\n📋 Student Information:');
        print('First Name: ${studentInfo?['firstName']}');
        print('Last Name: ${studentInfo?['lastName']}');
        print('Age: ${studentInfo?['studentAge']}');
        print('Gender: ${studentInfo?['studentGender']}');
        print('Student ID: ${studentInfo?['studentID']}');
      } else {
        // Handle the case where student info doesn't exist
        print('⚠️ No student personal information found.');
      }

      // Fetch subjects
      final subjects = await studentRef.collection('Subjects').get();
      subjectsWithGrades = {};
      print('\n📚 Subjects:');
      for (var doc in subjects.docs) {
        final data = doc.data();
        final subjectName = data['Subject_Name'] ?? 'Unknown';
        final grade = data['Subject_Grade'] ?? 'N/A';

        subjectsWithGrades![doc.id] = {
          'subject': subjectName,
          'grade': grade,
        };
      }

      // Fetch total marks
      final marksDoc = await studentRef.collection('TOTAL_MARKS').doc('Marks').get();
      if (marksDoc.exists) {
        final marks = marksDoc.data()!;
        studentTotalMarks = marks['Total_Student_Points']?.toString();
        teacherTotalMarks = marks['Teacher_Total_Marks']?.toString();

        print('\n📊 Total Marks:');
        print('Student Points: $studentTotalMarks');
        print('Teacher Total: $teacherTotalMarks');
      } else {
        print('⚠️ TOTAL_MARKS/Marks not found');
      }
    } catch (e) {
      print('❌ Error while fetching student data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      print('✅ Finished fetching student data and subjects.');
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
                  // Displaying Full Name dynamically
                  Text(
                    'Student: ${studentInfo?['firstName'] ?? 'N/A'} ${studentInfo?['lastName'] ?? 'N/A'}',
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
                  Text('Student Total Marks: $studentTotalMarks'),
                  Text('Teacher Total Marks: $teacherTotalMarks'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on CollectionReference<Map<String, dynamic>> {
  collection(String s) {}
}
