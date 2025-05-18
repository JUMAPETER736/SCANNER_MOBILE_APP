import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Student_Subjects extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const Student_Subjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  _Student_SubjectsState createState() => _Student_SubjectsState();
}

class _Student_SubjectsState extends State<Student_Subjects> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _subjects = [];
  List<String> _userSubjects = [];
  bool isLoading = true;

  Future<void> _fetchSubjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        String schoolName = docSnapshot['school'] ?? '';
        String className = widget.studentClass;

        // Fetch all subjects for the selected class
        final classRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details');

        final classSnapshot = await classRef.get();
        Set<String> allSubjectsSet = {};

        for (var studentDoc in classSnapshot.docs) {
          final studentSubjectRef = studentDoc.reference.collection('Student_Subjects');
          final subjectSnapshot = await studentSubjectRef.get();
          for (var subjectDoc in subjectSnapshot.docs) {
            allSubjectsSet.add(subjectDoc['Subject_Name'].toString());
          }
        }

        // ✅ Fetch the logged-in user's subjects from Firestore array field
        List<String> userSubjectsList = List<String>.from(docSnapshot['subjects'] ?? []);

        setState(() {
          _subjects = allSubjectsSet.toList();
          _userSubjects = userSubjectsList;
          isLoading = false;
        });

        print("All subjects: $_subjects");
        print("User's assigned Subjects: $_userSubjects");
      }
    } catch (e) {
      print('Error fetching Subjects: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _fetchGradeForSubject(String subject) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'N/A';

      final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        String schoolName = docSnapshot['school'] ?? '';
        String className = widget.studentClass;

        final gradeRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details')
            .doc(widget.studentName)
            .collection('Student_Subjects')
            .doc(subject);

        final gradeSnapshot = await gradeRef.get();

        if (gradeSnapshot.exists) {
          final grade = gradeSnapshot['Subject_Grade'];
          if (grade != null && grade.isNotEmpty) {
            print("Fetched Grade for $subject: $grade");  // Debugging statement
            return grade; // Return the grade if it's not null or empty
          } else {
            print("Subject_Grade is null or empty for $subject");  // Debugging statement
          }
        } else {
          print("No document found for $subject");  // Debugging statement
        }
      } else {
        print("User document does not exist.");  // Debugging statement
      }
    } catch (e) {
      print('Error fetching Grade for Subject: $e');
    }
    return ''; // Return empty string if no grade is found
  }



  Future<void> _updateGrade(String subject) async {
    String newGrade = '';
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Grade for $subject'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(hintText: "Enter new Grade"),
                    onChanged: (value) {
                      setState(() {
                        newGrade = value.trim(); // Remove extra spaces
                        errorMessage = ''; // Clear error message when input changes
                      });
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                // Validation for grade input
                if (newGrade.isEmpty || int.tryParse(newGrade) == null) {
                  setState(() {
                    errorMessage = 'Please enter a valid grade (numeric value)';
                  });
                } else if (int.parse(newGrade) < 0) {
                  setState(() {
                    errorMessage = 'Grade cannot be less than 0';
                  });
                } else if (int.parse(newGrade) > 100) {
                  setState(() {
                    errorMessage = 'Grade cannot be greater than 100';
                  });
                }

                else {
                  try {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;

                    final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
                    final docSnapshot = await userRef.get();

                    if (docSnapshot.exists) {
                      String schoolName = (docSnapshot['school'] ?? '').trim();
                      String className = widget.studentClass.trim();
                      String studentName = widget.studentName.trim();

                      List<String> nameParts = studentName.split(" ");
                      String reversedName = nameParts.length == 2
                          ? "${nameParts[1]} ${nameParts[0]}"
                          : studentName;

                      final studentRefNormal = _firestore
                          .collection('Schools')
                          .doc(schoolName)
                          .collection('Classes')
                          .doc(className)
                          .collection('Student_Details')
                          .doc(studentName);

                      final studentRefReversed = _firestore
                          .collection('Schools')
                          .doc(schoolName)
                          .collection('Classes')
                          .doc(className)
                          .collection('Student_Details')
                          .doc(reversedName);

                      final studentSnapshotNormal = await studentRefNormal.get();
                      final studentSnapshotReversed = await studentRefReversed.get();

                      DocumentReference studentRef;
                      if (studentSnapshotNormal.exists) {
                        studentRef = studentRefNormal;
                      } else if (studentSnapshotReversed.exists) {
                        studentRef = studentRefReversed;
                      } else {
                        return; // Student not found
                      }

                      final subjectRef = studentRef.collection('Student_Subjects').doc(subject);

                      // Check if it's FORM 3 or FORM 4
                      if (className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4') {
                        // FORM 3 and FORM 4 → Add Grade_Point too
                        int gradeInt = int.parse(newGrade);
                        int gradePoint;

                        if (gradeInt >= 85) {
                          gradePoint = 1;
                        } else if (gradeInt >= 80) {
                          gradePoint = 2;
                        } else if (gradeInt >= 75) {
                          gradePoint = 3;
                        } else if (gradeInt >= 70) {
                          gradePoint = 4;
                        } else if (gradeInt >= 65) {
                          gradePoint = 5;
                        } else if (gradeInt >= 60) {
                          gradePoint = 6;
                        } else if (gradeInt >= 55) {
                          gradePoint = 7;
                        } else if (gradeInt >= 50) {
                          gradePoint = 8;
                        } else {
                          gradePoint = 9;
                        }

                        await subjectRef.set({
                          'Subject_Grade': newGrade,
                          'Grade_Point': gradePoint,
                        }, SetOptions(merge: true));
                      } else {
                        // FORM 1 and FORM 2 → Save Subject_Grade and Grade_Score letter grade
                        int gradeInt = int.parse(newGrade);
                        String gradeScore;

                        if (gradeInt >= 85 && gradeInt <= 100) {
                          gradeScore = 'A';
                        } else if (gradeInt >= 70) {
                          gradeScore = 'B';
                        } else if (gradeInt >= 60) {
                          gradeScore = 'C';
                        } else if (gradeInt >= 50) {
                          gradeScore = 'D';
                        } else {
                          gradeScore = 'F';
                        }

                        await subjectRef.set({
                          'Subject_Grade': newGrade,
                          'Grade_Score': gradeScore,
                        }, SetOptions(merge: true));
                      }


                      setState(() {
                        _fetchSubjects();
                      });

                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    print('Error updating Subject Grade and Grade Point: $e');
                  }
                }

              },
            ),
          ],
        );
      },
    );

  }


  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects for ${widget.studentName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? const Center(
        child: Text(
          'No Subjects Available.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            bool isUserSubject = _userSubjects.contains(_subjects[index]);

            return FutureBuilder<String>(
              future: _fetchGradeForSubject(_subjects[index]),
              builder: (context, snapshot) {
                String grade = snapshot.data ?? '';  // Default to an empty string instead of 'N/A'

                // Show N/A if the grade is empty
                if (grade.isEmpty) {
                  grade = 'N/A';
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      '${index + 1}. ${_subjects[index]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Text(
                      'Grade: $grade',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: isUserSubject
                        ? IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.blueAccent,
                      onPressed: () {
                        _updateGrade(_subjects[index]);
                      },
                    )
                        : null,
                  ),
                );
              },
            );

          },
        ),
      ),
    );
  }
}

