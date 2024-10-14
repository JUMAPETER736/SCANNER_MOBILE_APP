import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolReports extends StatefulWidget {
  final User? loggedInUser;

  const SchoolReports({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  String? teacherClass;
  bool _hasSelectedClass = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.loggedInUser;

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        currentUser = user;
        if (currentUser != null) {
          _checkTeacherSelection();
        }
      });
    });

    if (currentUser != null) {
      _checkTeacherSelection();
    }
  }

  void _checkTeacherSelection() async {
    if (currentUser != null) {
      var teacherSnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(currentUser!.email)
          .get();

      if (teacherSnapshot.exists) {
        var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
        var classes = teacherData['classes'] as List<dynamic>? ?? [];

        if (classes.isNotEmpty) {
          setState(() {
            teacherClass = classes[0];
            _hasSelectedClass = true;
          });
        }
      }
    }
  }

  Future<void> _calculateAndUpdateMarks(String studentDocId) async {
    try {
      DocumentReference studentRef = FirebaseFirestore.instance
          .collection('Students_Details')
          .doc(teacherClass!)
          .collection('Student_Details')
          .doc(studentDocId);

      DocumentSnapshot studentDoc = await studentRef.get();

      if (studentDoc.exists) {
        int totalMarks = 0;
        int totalTeacherMarks = 0;

        var subjectsSnapshot = await studentRef.collection('Student_Subjects').get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          var subjectData = subjectDoc.data() as Map<String, dynamic>;

          if (subjectData.containsKey('Subject_Grade')) {
            var gradeString = subjectData['Subject_Grade'];
            int grade = int.tryParse(gradeString.toString()) ?? 0;

            totalMarks += grade;
            totalTeacherMarks += 100; // Adjust this according to your grading scale
          }
        }

        await studentRef.set({
          'Student_Total_Marks': totalMarks,
          'Teachers_Total_Marks': totalTeacherMarks,
        }, SetOptions(merge: true));

        print('Updated marks for student: $studentDocId');
      } else {
        print('Student document does not exist: $studentDocId');
      }
    } catch (e) {
      print('Error updating marks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getStudentNames() async {
    List<Map<String, dynamic>> studentNames = [];
    QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
        .collection('Students_Details')
        .doc(teacherClass!)
        .collection('Student_Details')
        .get();

    for (var studentDoc in studentsSnapshot.docs) {
      var personalInfoDoc = await studentDoc.reference.collection('Personal_Information')
          .doc('Registered_Information').get();

      if (personalInfoDoc.exists) {
        var personalInfo = personalInfoDoc.data() as Map<String, dynamic>;
        var firstName = personalInfo['firstName'] ?? 'N/A';
        var lastName = personalInfo['lastName'] ?? 'N/A';
        var gender = personalInfo['studentGender'] ?? 'N/A';

        // Fetch total marks
        var totalMarksData = studentDoc.data() as Map<String, dynamic>;
        var studentTotalMarks = totalMarksData['Student_Total_Marks'] ?? 0;
        var teachersTotalMarks = totalMarksData['Teachers_Total_Marks'] ?? 0;

        studentNames.add({
          'fullName': '$lastName $firstName',
          'gender': gender,
          'id': studentDoc.id,
          'studentTotalMarks': studentTotalMarks,
          'teachersTotalMarks': teachersTotalMarks,
        });
      }
    }

    // Sort students by total marks in descending order
    studentNames.sort((a, b) => b['studentTotalMarks'].compareTo(a['studentTotalMarks']));

    return studentNames;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'School Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Text('No user is logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasSelectedClass ? '$teacherClass STUDENTS' : 'School Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: _hasSelectedClass
            ? [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog(context);
            },
          ),
        ]
            : [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: _hasSelectedClass
            ? FutureBuilder<List<Map<String, dynamic>>>(  // FutureBuilder to fetch student names
          future: _getStudentNames(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No Student found.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );
            }

            var filteredStudents = snapshot.data!.where((student) {
              return student['fullName'].toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredStudents.isEmpty) {
              return Center(
                child: Text(
                  'Student NOT found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );
            }

            // Update marks for each student
            for (var student in filteredStudents) {
              _calculateAndUpdateMarks(student['id']);
            }

            return ListView.separated(
              itemCount: filteredStudents.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var student = filteredStudents[index];
                var fullName = student['fullName'];
                var studentGender = student['gender'] ?? 'N/A';
                var studentTotalMarks = student['studentTotalMarks'] ?? 0; // Use default value if null
                var teachersTotalMarks = student['teachersTotalMarks'] ?? 0; // Use default value if null

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text(
                      fullName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns content to the ends
                      children: [
                        Text(
                          'Gender: $studentGender',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: $studentTotalMarks/$teachersTotalMarks', // Format for total marks
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchoolReportPage(
                            studentName: student['id'],
                            studentClass: teacherClass!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        )
            : Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search Student'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Enter student name'),
            onChanged: (value) {
              setState(() {
                _searchQuery = value; // Update search query
              });
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Search'),
              onPressed: () {
                setState(() {
                  _searchQuery = _searchController.text; // Update search query
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}





class SchoolReportPage extends StatelessWidget {
  final String studentName;
  final String studentClass;

  const SchoolReportPage({Key? key, required this.studentName, required this.studentClass}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Progress Report',
          style: TextStyle(fontWeight: FontWeight.bold), // Make the title bold
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Students_Details')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentName)
            .collection('Student_Subjects')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No grades found.'));
          }

          final subjectDocs = snapshot.data!.docs;

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('Students_Details')
                .doc(studentClass)
                .collection('Student_Details')
                .orderBy('Student_Total_Marks', descending: true)
                .get(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Calculate position
              int position = studentSnapshot.data!.docs
                  .indexWhere((doc) => doc.id == studentName) + 1; // +1 to make it 1-based index

              int totalStudents = studentSnapshot.data!.docs.length;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'STUDENT SCHOOL REPORT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STUDENT NAME: $studentName',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'CLASS: $studentClass',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TERM:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('YEAR:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('ENROLLMENT: $totalStudents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('POSITION: $position', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    DataTable(
                      border: TableBorder.all(),
                      dataRowHeight: 40,
                      headingRowHeight: 50,
                      columnSpacing: 8,
                      columns: [
                        DataColumn(label: Text('SUBJECTS', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SCORE', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('GRADE', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("TEACHER'S REMARK", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SIGNATURE', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: subjectDocs.map((subjectDoc) {
                        final subjectData = subjectDoc.data() as Map<String, dynamic>;

                        final subjectName = subjectData['Subject_Name'] ?? 'Unknown';
                        final subjectGrade = (subjectData['Subject_Grade'] is int)
                            ? subjectData['Subject_Grade']
                            : (subjectData['Subject_Grade'] is String)
                            ? int.tryParse(subjectData['Subject_Grade']) ?? 0
                            : 0;

                        final scorePercentage = '$subjectGrade%';
                        final grade = getGrade(subjectGrade);
                        final teacherRemark = getTeacherRemark(subjectGrade);

                        return DataRow(cells: [
                          DataCell(Text(subjectName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(scorePercentage, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(grade, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(teacherRemark, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(" ", style: TextStyle(fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to determine the grade based on the score
  String getGrade(int score) {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {

      if (score >= 80) return 'A';
      if (score >= 70) return 'B';
      if (score >= 60) return 'C';
      if (score >= 50) return 'D';
      if (score >= 40) return 'E';

      return 'F';


    } else {

      if (score >= 80) return '1';
      if (score >= 75) return '2';
      if (score >= 70) return '3';
      if (score >= 65) return '4';
      if (score >= 60) return '5';
      if (score >= 55) return '6';
      if (score >= 50) return '7';
      if (score >= 40) return '8';

      return '9';

    }
  }

  // Function to return the teacher's remark based on the score
  String getTeacherRemark(int score) {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      // Remarks for FORM 1 & 2
      if (score >= 80) return 'EXCELLENT';
      if (score >= 70) return 'VERY GOOD';
      if (score >= 60) return 'GOOD';
      if (score >= 50) return 'AVERAGE';
      if (score >= 40) return 'NEEDS IMPROVEMENT';
      return 'FAIL';

    } else {
      // Remarks for FORM 3 & 4
      if (score >= 80) return 'EXCELLENT';
      if (score >= 75) return 'VERY GOOD';
      if (score >= 70) return 'GOOD';
      if (score >= 65) return 'STRONG CREDIT';
      if (score >= 60) return 'WEAK CREDIT';
      if (score >= 50) return 'PASS';
      if (score >= 40) return 'NEED SUPPORT';

      return 'FAIL';

    }
  }
}
