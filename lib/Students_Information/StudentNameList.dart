import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Students_Information/StudentSubjects.dart';

class StudentNameList extends StatefulWidget {
  final User? loggedInUser;

  const StudentNameList({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _StudentNameListState createState() => _StudentNameListState();
}

class _StudentNameListState extends State<StudentNameList> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  String? teacherSchool;
  String? teacherClass;
  bool _hasSelectedCriteria = false;

  @override
  void initState() {
    super.initState();
    _checkTeacherSelection();
  }

  // Method to check if the teacher has selected school and class
  void _checkTeacherSelection() async {
    if (widget.loggedInUser != null) {
      var teacherSnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(widget.loggedInUser!.email)
          .get();

      if (teacherSnapshot.exists) {
        var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
        var school = teacherData['school'];
        var classes = teacherData['classes'] as List<dynamic>? ?? [];

        if (school != null && classes.isNotEmpty) {
          setState(() {
            teacherSchool = school;
            teacherClass = classes[0]; // Set the first selected class
            _hasSelectedCriteria = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Name of Students',
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
        title: _hasSelectedCriteria
            ? Text(
          '$teacherSchool - $teacherClass',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Name of Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: _hasSelectedCriteria
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
        child: _hasSelectedCriteria
            ? StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Schools')
              .doc(teacherSchool) // Use the logged-in teacher's school
              .collection('Classes')
              .doc(teacherClass) // Use the logged-in teacher's class
              .collection('Student_Details')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No Student Found.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );
            }

            var studentDocs = snapshot.data!.docs;

            return ListView.separated(
              shrinkWrap: true,
              itemCount: studentDocs.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var studentDoc = studentDocs[index];
                var registeredInformationDocRef = studentDoc.reference
                    .collection('Personal_Information')
                    .doc('Registered_Information');

                return FutureBuilder<DocumentSnapshot>(
                  future: registeredInformationDocRef.get(),
                  builder: (context, futureSnapshot) {
                    if (!futureSnapshot.hasData || !futureSnapshot.data!.exists) {
                      return Container(); // Skip if no data
                    }

                    var data = futureSnapshot.data!.data() as Map<String, dynamic>;
                    var firstName = data['firstName'] ?? 'N/A';
                    var lastName = data['lastName'] ?? 'N/A';
                    var studentGender = data['studentGender'] ?? 'N/A';
                    var fullName = '$lastName $firstName'; // Change order to lastName firstName

                    if (_searchQuery.isNotEmpty &&
                        !fullName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                      return Container(); // Skip if search query doesn't match
                    }

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                        subtitle: Text(
                          'Gender: $studentGender',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward, color: Colors.blueAccent),


                        onTap: () async {
                          // Fetch the student's subject grades and calculate total marks
                          var studentSubjectsSnapshot = await FirebaseFirestore.instance
                              .collection('Schools')
                              .doc(teacherSchool)
                              .collection('Classes')
                              .doc(teacherClass)
                              .collection('Student_Details')
                              .doc(studentDoc.id)
                              .collection('Student_Subjects')
                              .get();

                          int totalMarks = 0;
                          int totalMaxMarks = 0; // This will store the teacher's total possible marks (maximum marks)

                          for (var subjectDoc in studentSubjectsSnapshot.docs) {
                            var subjectData = subjectDoc.data() as Map<String, dynamic>;
                            var subjectGrade = subjectData['Subject_Grade'] ?? 'N/A';

                            // Only add the valid subject grades that are not "N/A"
                            if (subjectGrade != 'N/A') {
                              totalMarks += int.tryParse(subjectGrade) ?? 0; // Add the grade to total marks
                              totalMaxMarks += 100; // For each valid grade, add 100 to the teacher's max possible marks
                            }
                          }

                          // Update the TOTAL_MARKS subcollection with the calculated total marks
                          await FirebaseFirestore.instance
                              .collection('Schools')
                              .doc(teacherSchool)
                              .collection('Classes')
                              .doc(teacherClass)
                              .collection('Student_Details')
                              .doc(studentDoc.id)
                              .collection('TOTAL_MARKS')
                              .doc('Marks')
                              .set({
                            'Student_Total_Marks': totalMarks.toString(),
                            'Teacher_Total_Marks': totalMaxMarks.toString(), // Store the teacher's total max marks
                          });

                          // Navigate to StudentSubjects page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentSubjects(
                                studentName: fullName,
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
            );
          },
        )
            : Center(
          child: Text(
            'Please select Class First',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search Student'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter first or last name',
            ),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _searchQuery = value;
                });
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _searchQuery = _searchController.text;
                });
              },
              child: Text(
                'Search',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
