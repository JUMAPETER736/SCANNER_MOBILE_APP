import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Home_Screens/SchoolReportPDFGenerator.dart';


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
  //String formNumber = 'FORM 2'; // Example form number, modify based on your logic

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
<<<<<<< HEAD
          var subjectData = subjectDoc.data();
=======
          var subjectData = subjectDoc.data() as Map<String, dynamic>;
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a

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

        print('Updated Marks for Student: $studentDocId');
      } else {
        print('Student document does NOT Exist: $studentDocId');
      }
    } catch (e) {
      print('Error updating Marks: $e');
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
                          'Total Marks: $studentTotalMarks/$teachersTotalMarks', // Format for total marks
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchoolReportPDFGenerator(
                            studentName: student['id'],
                            studentClass: teacherClass!,

                            studentTotalMarks: studentTotalMarks,  // Pass studentTotalMarks
                            teachersTotalMarks: teachersTotalMarks, // Pass teachersTotalMarks if needed
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
            decoration: InputDecoration(hintText: 'Enter Student Name'),
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



