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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    try {
      // Fetch teacher details from Teachers_Details collection
      DocumentSnapshot teacherSnapshot = await _firestore
          .doc('/Teachers_Details/${widget.teacherEmail}')
          .get();

      if (teacherSnapshot.exists) {
        Map<String, dynamic> teacherData = teacherSnapshot.data() as Map<String, dynamic>;
        teacherSchool = teacherData['school'] as String?;
        teacherClass = teacherData['class'] as String?;

        // Fetch student data if teacher details are found
        fetchStudentData();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Optionally, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching teacher data: $e')),
      );
    }
  }

  Future<void> fetchStudentData() async {
    if (teacherSchool != null && teacherClass != null) {
      String basePath = '/Schools/$teacherSchool/Classes/$teacherClass/Student_Details/${widget.studentName}';

      try {
        // Fetch Personal Information of the student
        DocumentSnapshot personalInfoSnapshot = await _firestore
            .doc('$basePath/Personal_Information/Registered_Information')
            .get();

        if (personalInfoSnapshot.exists) {
          setState(() {
            studentInfo = personalInfoSnapshot.data() as Map<String, dynamic>?;
            isAuthorized = true; // Only set authorized if data exists
          });
        }

        // Fetch Student Subjects
        QuerySnapshot subjectsSnapshot = await _firestore
            .collection('$basePath/Student_Subjects')
            .get();

        setState(() {
          subjects = subjectsSnapshot.docs.map((doc) => doc.id).toList(); // Fetch subjects
          isLoading = false; // Set loading to false once data is fetched
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        // Optionally, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching student data: $e')),
        );
      }
    }
  }

  Future<String> fetchGradeForSubject(String subject) async {
    try {
      final gradeRef = _firestore
          .collection('Schools')
          .doc(teacherSchool)
          .collection('Classes')
          .doc(teacherClass)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Student_Subjects')
          .doc(subject);

      final gradeSnapshot = await gradeRef.get();

      if (gradeSnapshot.exists) {
        final grade = gradeSnapshot['Subject_Grade'];
        if (grade != null && grade.isNotEmpty) {
          print("Fetched Grade for $subject: $grade");
          return grade; // Return the grade if it's not null or empty
        } else {
          print("Subject_Grade is null or empty for $subject");
        }
      } else {
        print("No document found for $subject");
      }
    } catch (e) {
      print('Error fetching Grade for Subject: $e');
    }
    return ''; // Return empty string if no grade is found
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
              teacherSchool ?? 'No School Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Student Name: ${widget.studentName}',
              style: TextStyle(fontSize: 18),
            ),
            if (studentInfo != null) ...[
              Text(
                'Age: ${studentInfo!['studentAge'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Class: ${studentInfo!['studentClass'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Gender: ${studentInfo!['studentGender'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16),
              ),
            ],
            const Divider(),
            if (subjects.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<String>(
                      future: fetchGradeForSubject(subjects[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text(subjects[index], style: TextStyle(fontSize: 16)),
                            subtitle: Text('Fetching grade...', style: TextStyle(fontSize: 14)),
                          );
                        }

                        if (snapshot.hasError) {
                          return ListTile(
                            title: Text(subjects[index], style: TextStyle(fontSize: 16)),
                            subtitle: Text('Error fetching grade', style: TextStyle(fontSize: 14)),
                          );
                        }

                        return ListTile(
                          title: Text(subjects[index], style: TextStyle(fontSize: 16)),
                          subtitle: Text('Grade: ${snapshot.data ?? 'N/A'}', style: TextStyle(fontSize: 14)),
                        );
                      },
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
