import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Juniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() =>
      _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? studentInfo;
  Map<String, dynamic>? subjectsWithGrades = {};
  String? studentTotalMarks;
  String? teacherTotalMarks;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use the studentFullName passed through the widget
    fetchStudentData();
  }



  Future<void> fetchStudentData() async {


    try {
      // Reference to Student_Details collection
      final studentDetailsRef = _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details');

      // Step 0: Log all document IDs in Student_Details
      final allStudentsSnapshot = await studentDetailsRef.get();
      if (allStudentsSnapshot.docs.isNotEmpty) {
        print('📂 Listing all students in Student_Details collection:');
        for (var doc in allStudentsSnapshot.docs) {
          print('📝 Student Document ID: ${doc.id}');
        }
      } else {
        print('⚠️ No students found in the Student_Details collection for class ${widget.studentClass}');
      }

      // Reference to the specific student document
      final studentRef = studentDetailsRef.doc(widget.studentFullName);

      // Step 1: Fetch student personal info
      final studentDoc = await studentRef
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (!studentDoc.exists) {
        print('❌ Error: Personal information for ${widget.studentFullName} not found.');
        setState(() {
          studentInfo = {}; // Clear previous data if needed
          subjectsWithGrades = {};
          studentTotalMarks = 'N/A';
          teacherTotalMarks = 'N/A';
          isLoading = false; // Important: Update loading state
        });
        return;
      }

      final studentData = studentDoc.data()!;
      print('📋 Student Information for ${widget.studentFullName}: $studentData');

      setState(() {
        studentInfo = {
          'firstName': studentData['firstName'] ?? 'N/A',
          'lastName': studentData['lastName'] ?? 'N/A',
          'studentAge': studentData['studentAge']?.toString() ?? 'N/A',
          'studentGender': studentData['studentGender'] ?? 'N/A',
          'studentID': studentData['studentID']?.toString() ?? 'N/A',
          'studentClass': studentData['studentClass'] ?? 'N/A',
        };
      });

      // Step 2: Fetch subjects and grades
      final subjectsRef = studentRef.collection('Student_Subjects');
      final subjectsSnapshot = await subjectsRef.get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        print('\n📚 Subjects for ${widget.studentFullName}:');
        final Map<String, Map<String, String>> updatedSubjects = {};
        for (var subjectDoc in subjectsSnapshot.docs) {
          final subjectName = subjectDoc.id;
          final subjectGrade = subjectDoc.data()['Subject_Grade'] ?? 'N/A';

          print('Subject: $subjectName');
          print('Grade: $subjectGrade');

          updatedSubjects[subjectName] = {
            'subject': subjectName,
            'grade': subjectGrade,
          };
        }

        setState(() {
          subjectsWithGrades = updatedSubjects;
        });
      } else {
        print('⚠️ No subjects found for student ${widget.studentFullName}');
        setState(() {
          subjectsWithGrades = {};
        });
      }

      // Step 3: Fetch total marks
      final marksDoc = await studentRef
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get();

      if (marksDoc.exists) {
        final marks = marksDoc.data()!;
        final studentTotal = marks['Student_Total_Marks']?.toString() ?? 'N/A';
        final teacherTotal = marks['Teacher_Total_Marks']?.toString() ?? 'N/A';

        print('\n📊 Total Marks for ${widget.studentFullName}:');
        print('Student Total: $studentTotal');
        print('Teacher Total: $teacherTotal');

        setState(() {
          studentTotalMarks = studentTotal;
          teacherTotalMarks = teacherTotal;
          isLoading = false; // Set loading to false once all data is fetched
        });
      } else {
        print('⚠️ TOTAL_MARKS/Marks not found for ${widget.studentFullName}');
        setState(() {
          studentTotalMarks = 'N/A';
          teacherTotalMarks = 'N/A';
          isLoading = false; // Set loading to false even if marks not found
        });
      }

    } catch (e, stacktrace) {
      print('❗ Exception while fetching student data: $e');
      print(stacktrace);
      setState(() {
        isLoading = false; // Set loading to false on error
      });
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
                    'School: ${widget.schoolName}',
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
                  ? subjectsWithGrades!.values.map<Widget>((subject) {
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