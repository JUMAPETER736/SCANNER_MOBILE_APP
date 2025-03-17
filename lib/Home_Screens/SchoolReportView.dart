import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolReportView extends StatefulWidget {
  final Map<String, dynamic> student;
  final String studentName;
  final String teacherEmail;

  const SchoolReportView({
    required this.student,
    required this.studentName,
    required this.teacherEmail,
    Key? key,
  }) : super(key: key);

  @override
  _SchoolReportViewState createState() => _SchoolReportViewState();
}

class _SchoolReportViewState extends State<SchoolReportView> {
  Map<String, dynamic>? studentInfo;
  List<String> subjects = [];
  String? teacherSchool;
  String? teacherClass;
  bool isAuthorized = false;
  bool isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    // Fetch teacher details from Teachers_Details collection
    DocumentSnapshot teacherSnapshot = await FirebaseFirestore.instance
        .doc('/Teachers_Details/${widget.teacherEmail}')
        .get();

    if (teacherSnapshot.exists) {
      Map<String, dynamic> teacherData = teacherSnapshot.data() as Map<String, dynamic>;
      teacherSchool = teacherData['school'] as String?;
      teacherClass = teacherData['class'] as String?;

      // Fetch student data if teacher details are found
      fetchStudentData();
    }
  }

  Future<void> fetchStudentData() async {
    if (teacherSchool != null && teacherClass != null) {
      String basePath = '/Schools/$teacherSchool/Classes/$teacherClass/Student_Details/${widget.studentName}';

      // Fetch Personal Information of the student
      DocumentSnapshot personalInfoSnapshot = await FirebaseFirestore.instance
          .doc('$basePath/Personal_Information/Registered_Information')
          .get();

      if (personalInfoSnapshot.exists) {
        setState(() {
          studentInfo = personalInfoSnapshot.data() as Map<String, dynamic>?; // Fetch student details
          isAuthorized = true; // Only set authorized if data exists
        });
      }

      // Fetch Student Subjects
      QuerySnapshot subjectsSnapshot = await FirebaseFirestore.instance
          .collection('$basePath/Student_Subjects')
          .get();

      setState(() {
        subjects = subjectsSnapshot.docs.map((doc) => doc.id).toList(); // Fetch subjects
        isLoading = false; // Set loading to false once data is fetched
      });
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
              teacherSchool ?? 'No School Available', // Display fetched school name or fallback text
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Student Name: ${widget.studentName}',
              style: TextStyle(fontSize: 18),
            ),
            if (studentInfo != null) ...[
              Text(
                'Age: ${studentInfo!['studentAge'] ?? 'N/A'}', // Display age if available
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Class: ${studentInfo!['studentClass'] ?? 'N/A'}', // Display class if available
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Gender: ${studentInfo!['studentGender'] ?? 'N/A'}', // Display gender if available
                style: TextStyle(fontSize: 16),
              ),
            ],
            const Divider(),
            if (subjects.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(subjects[index], style: TextStyle(fontSize: 16)),
                      subtitle: Text('Grade: F (Placeholder)'), // Replace with actual grade if needed
                    );
                  },
                ),
              ),
            ] else ...[
              Text('No subjects available', style: TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
