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
                          builder: (context) => SchoolReportPage(studentName: student.id),
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

  const SchoolReportPage({Key? key, required this.studentName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Progress Report'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Students_Details')
            .doc('FORM 2')
            .collection('Student_Details')
            .doc(studentName) // Use the studentName passed to the constructor
            .collection('Student_Subjects')
            .get(), // Fetching all subjects for the student
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

          // Extracting subject grades from the snapshot
          final subjectDocs = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: $studentName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Form: FORM 2',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
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
                ...subjectDocs.map((subjectDoc) {
                  final subjectName = subjectDoc['Subject_Name'] ?? 'Unknown'; // Fetch Subject_Name
                  final subjectGrade = subjectDoc['Subject_Grade'] ?? 'N/A'; // Fetch Subject_Grade
                  return SubjectReportCard(subject: subjectName, score: subjectGrade);
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SubjectReportCard extends StatelessWidget {
  final String subject;
  final dynamic score; // Use dynamic to allow for various data types

  const SubjectReportCard({Key? key, required this.subject, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            subject.toUpperCase(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            score != null ? score.toString() : 'N/A',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
