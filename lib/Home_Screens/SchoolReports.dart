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

            // Only count the subject if the grade is not "N/A"
            if (gradeString != "N/A") {
              totalMarks += grade;
              totalTeacherMarks += 100; // Increase the teacher's total marks by 100 only for valid subjects
            }
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
            ? StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Students_Details')
              .doc(teacherClass!)
              .collection('Student_Details')
              .orderBy('Student_Total_Marks', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

            var filteredDocs = snapshot.data!.docs.where((doc) {
              var firstName = doc['firstName'] ?? '';
              var lastName = doc['lastName'] ?? '';
              return firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  lastName.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredDocs.isEmpty) {
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

            for (var student in filteredDocs) {
              _calculateAndUpdateMarks(student.id);
            }

            return ListView.separated(
              itemCount: filteredDocs.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var student = filteredDocs[index];
                var firstName = student['firstName'] ?? 'N/A';
                var lastName = student['lastName'] ?? 'N/A';
                var studentGender = student['studentGender'] ?? 'N/A';
                var totalMarks = student['Student_Total_Marks'] ?? '0';
                var teacherMarks = student['Teachers_Total_Marks'] ?? '0';

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
                      '${lastName.toUpperCase()} ${firstName.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gender: $studentGender',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Total Marks: $totalMarks / $teacherMarks',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchoolReportPage(
                              studentName: student.id,
                              studentClass: teacherClass!, // Pass the selected class),
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
          child: Text(
            'Please wait while loading...',
            style: TextStyle(fontSize: 18),
          ),
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
            decoration: InputDecoration(hintText: 'Enter Student Name...'),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}



class SchoolReportPage extends StatelessWidget {
  final String studentName;
  final String studentClass; // Add form parameter

  const SchoolReportPage({Key? key, required this.studentName, required this.studentClass}) : super(key: key);

  // Define grade ranges for junior and senior students
  static const List<Map<String, String>> juniorGradeRanges = [
    {'range': '80 - 100%', 'grade': 'A'},
    {'range': '70 - 79%', 'grade': 'B'},
    {'range': '60 - 69%', 'grade': 'C'},
    {'range': '50 - 59%', 'grade': 'D'},
    {'range': '40 - 49%', 'grade': 'E'},
    {'range': '0 - 39%', 'grade': 'F'},
  ];

  static const List<Map<String, String>> seniorGradeRanges = [
    {'range': '80 - 100%', 'grade': '1'},
    {'range': '75 - 79%', 'grade': '2'},
    {'range': '70 - 74%', 'grade': '3'},
    {'range': '65 - 69%', 'grade': '4'},
    {'range': '60 - 64%', 'grade': '5'},
    {'range': '55 - 59%', 'grade': '6'},
    {'range': '50 - 54%', 'grade': '7'},
    {'range': '40 - 49%', 'grade': '8'},
    {'range': '0 - 39%', 'grade': '9'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Progress Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Students_Details')
            .doc(studentClass) // Use the form parameter
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

          // Calculate total marks and enrollment
          int totalMarks = 0;
          int totalStudents = 0;

          // Get all students in the current form to calculate enrollment
          FirebaseFirestore.instance
              .collection('Students_Details')
              .doc(studentClass) // Use the form parameter
              .collection('Student_Details')
              .get()
              .then((value) {
            totalStudents = value.docs.length;
          });

          // Calculate total marks for the position
          for (var subjectDoc in subjectDocs) {
            final subjectData = subjectDoc.data() as Map<String, dynamic>;
            final subjectGrade = (subjectData['Subject_Grade'] is int)
                ? subjectData['Subject_Grade']
                : (subjectData['Subject_Grade'] is String)
                ? int.tryParse(subjectData['Subject_Grade']) ?? 0
                : 0;

          }

          // Placeholder for position, will be calculated later
          int position = 1;

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
                      'NAME: $studentName',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'FORM: $studentClass',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

                    final scorePercentage = '$subjectGrade%'; // Assuming grades are given as integers
                    final grade = getGrade(subjectGrade); // Use the updated getGrade method

                    return DataRow(cells: [
                      DataCell(Text(subjectName.toUpperCase())),
                      DataCell(Text(scorePercentage)),
                      DataCell(Text(grade)),
                      DataCell(Text(" ")), // Placeholder for teacher's remark
                      DataCell(Text(" ")), // Placeholder for signature
                    ]);
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Function to determine the grade based on the score
  String getGrade(int score) {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      // Junior grades A-F
      if (score >= 80) return 'A';
      if (score >= 70) return 'B';
      if (score >= 60) return 'C';
      if (score >= 50) return 'D';
      if (score >= 40) return 'E';
      return 'F'; // 0 - 39%
    } else {
      // Senior grades 1-9
      if (score >= 80) return '1';
      if (score >= 75) return '2';
      if (score >= 70) return '3';
      if (score >= 65) return '4';
      if (score >= 60) return '5';
      if (score >= 55) return '6';
      if (score >= 50) return '7';
      if (score >= 40) return '8';
      return '9'; // 0 - 39%
    }
  }
}
