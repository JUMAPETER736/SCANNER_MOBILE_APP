

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/School_Report/Juniors_School_Report_View.dart';
import 'package:scanna/School_Report/Seniors_School_Report_View.dart';


class Results_And_School_Reports extends StatefulWidget {

  @override
  _Results_And_School_ReportsState createState() => _Results_And_School_ReportsState();
}

class _Results_And_School_ReportsState extends State<Results_And_School_Reports> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userEmail;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> studentDetails = [];


  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  // Simulate loading for 1 second
  Future<void> _simulateLoading() async {
    await Future.delayed(Duration(seconds: 1)); // Delay for 1 second
    _fetchUserDetails(); // After delay, fetch user details
  }

  // Fetch user details from Firestore based on logged-in user's email
  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userEmail = user.email!;

      try {
        // Fetch user details from Firestore (Teachers_Details)
        DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

        if (userDoc.exists) {
          // Check if the user has selected a school and classes
          if (userDoc['school'] == null || userDoc['classes'] == null || userDoc['classes'].isEmpty) {
            setState(() {
              hasError = true;
              errorMessage = 'Please select a School and Classes before accessing reports.';
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = true; // Keep loading until student data is fetched
            });

            // Fetch student details for the teacher's assigned classes
            await _fetchStudentDetails(userDoc);
          }
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'User details not found.';
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Classes before accessing School Reports.';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
    }
  }


  Future<void> _fetchStudentDetails(DocumentSnapshot userDoc) async {
    try {
      List<Map<String, dynamic>> tempStudentDetails = [];

      // Map to store students by class for position calculation
      Map<String, List<Map<String, dynamic>>> studentsByClass = {};

      for (var classId in userDoc['classes']) {
        QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(userDoc['school'])
            .collection('Classes')
            .doc(classId)
            .collection('Student_Details')
            .get();

        List<Map<String, dynamic>> classStudents = [];

        for (var studentDoc in studentsSnapshot.docs) {
          // Get student basic information from the document ID (which is the student name)
          String studentName = studentDoc.id;
          var studentData = studentDoc.data() as Map<String, dynamic>? ?? {};

          // Extract basic info - adjust field names based on your actual document structure
          var gender = studentData['studentGender'];
          var studentClass = classId; // Use the class ID directly since we're iterating through classes

          // Parse the student name (assuming format is "LastName FirstName" or "FirstName LastName")
          List<String> nameParts = studentName.split(" ");
          String fullName = studentName; // Keep original name format

          // Get total marks document
          DocumentReference marksRef = studentDoc.reference
              .collection('TOTAL_MARKS')
              .doc('Marks');

          DocumentSnapshot totalMarksDoc = await marksRef.get();

          if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
            // Calculate Best Six Points from subject grades
            List<int> subjectPoints = [];

            var subjectsSnapshot = await studentDoc.reference
                .collection('Student_Subjects')
                .get();

            for (var subjectDoc in subjectsSnapshot.docs) {
              var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};

              // Check if Subject_Grade exists and is not "N/A"
              if (subjectData.containsKey('Subject_Grade')) {
                var subjectGradeValue = subjectData['Subject_Grade'];

                // Skip subjects with "N/A" grades
                if (subjectGradeValue == null ||
                    subjectGradeValue.toString().toUpperCase() == 'N/A') {
                  continue;
                }

                // Convert Subject_Grade to integer score
                int? subjectScore;
                if (subjectGradeValue is int) {
                  subjectScore = subjectGradeValue;
                } else if (subjectGradeValue is String) {
                  subjectScore = int.tryParse(subjectGradeValue);
                }

                // Calculate grade point using the Seniors_Grade function
                if (subjectScore != null && subjectScore >= 0) {
                  int gradePoint = int.parse(Seniors_Grade(subjectScore));
                  subjectPoints.add(gradePoint);
                }
              }
            }

            // Calculate Best Six Total Points
            int bestSixPoints = 0;
            if (subjectPoints.length >= 6) {
              subjectPoints.sort(); // Lower is better
              bestSixPoints = subjectPoints.take(6).fold(0, (sum, point) => sum + point);
            } else if (subjectPoints.isNotEmpty) {
              // Sum all valid subjects if fewer than 6
              bestSixPoints = subjectPoints.fold(0, (sum, point) => sum + point);
            }

            // Update or create Best_Six_Total_Points in Firestore
            if (totalMarksDoc.exists) {
              var totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;
              var existingPointsValue = totalMarksData['Best_Six_Total_Points'];
              int? existingBestSixPoints;

              if (existingPointsValue is int) {
                existingBestSixPoints = existingPointsValue;
              } else if (existingPointsValue is String) {
                existingBestSixPoints = int.tryParse(existingPointsValue);
              }

              // Update only if changed
              if (existingBestSixPoints == null || existingBestSixPoints != bestSixPoints) {
                await marksRef.set({
                  'Best_Six_Total_Points': bestSixPoints,
                }, SetOptions(merge: true));
              }
            } else {
              // Create the document if it doesn't exist
              await marksRef.set({
                'Best_Six_Total_Points': bestSixPoints,
              });
            }

            // Add to class students list for position calculation
            classStudents.add({
              'fullName': fullName,
              'studentGender': gender,
              'studentClass': studentClass,
              'Best_Six_Total_Points': bestSixPoints,
              'marksRef': marksRef,
              'studentType': 'senior'
            });

            // Add to temporary list
            tempStudentDetails.add({
              'fullName': fullName,
              'studentGender': gender,
              'studentClass': studentClass,
              'Best_Six_Total_Points': bestSixPoints,
            });
          }
          else if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
            // JUNIORS: Calculate total marks from Subject grades
            int totalMarks = 0;
            int totalPossibleMarks = 0;

            var subjectsSnapshot = await studentDoc.reference.collection('Student_Subjects').get();
            for (var subjectDoc in subjectsSnapshot.docs) {
              var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};
              if (subjectData.containsKey('Subject_Grade')) {
                // Handle both int and string types for Subject_Grade
                var subjectGradeValue = subjectData['Subject_Grade'];

                // Skip subjects with "N/A" grades for juniors too
                if (subjectGradeValue == null ||
                    subjectGradeValue.toString().toUpperCase() == 'N/A') {
                  continue;
                }

                int subjectGrade = 0;

                if (subjectGradeValue is int) {
                  subjectGrade = subjectGradeValue;
                } else if (subjectGradeValue is String) {
                  subjectGrade = int.tryParse(subjectGradeValue) ?? 0;
                }

                if (subjectGrade > 0) {
                  totalMarks += subjectGrade;
                  totalPossibleMarks += 100; // Assuming each subject is out of 100
                }
              }
            }

            // Update or create total marks in Firebase
            if (totalMarksDoc.exists) {
              var totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;

              // Handle both int and string types for existing values
              var existingStudentTotalValue = totalMarksData['Student_Total_Marks'];
              var existingTeacherTotalValue = totalMarksData['Teacher_Total_Marks'];

              int existingStudentTotal = 0;
              int existingTeacherTotal = 0;

              if (existingStudentTotalValue is int) {
                existingStudentTotal = existingStudentTotalValue;
              } else if (existingStudentTotalValue is String) {
                existingStudentTotal = int.tryParse(existingStudentTotalValue) ?? 0;
              }

              if (existingTeacherTotalValue is int) {
                existingTeacherTotal = existingTeacherTotalValue;
              } else if (existingTeacherTotalValue is String) {
                existingTeacherTotal = int.tryParse(existingTeacherTotalValue) ?? 0;
              }

              if (existingStudentTotal != totalMarks || existingTeacherTotal != totalPossibleMarks) {
                await marksRef.update({
                  'Student_Total_Marks': totalMarks,
                  'Teacher_Total_Marks': totalPossibleMarks,
                });
              }
            } else {
              // Create the document if it doesn't exist
              await marksRef.set({
                'Student_Total_Marks': totalMarks,
                'Teacher_Total_Marks': totalPossibleMarks,
              });
            }

            // Add to class students list for position calculation
            classStudents.add({
              'fullName': fullName,
              'studentGender': gender,
              'studentClass': studentClass,
              'Student_Total_Marks': totalMarks,
              'Teacher_Total_Marks': totalPossibleMarks,
              'marksRef': marksRef,
              'studentType': 'junior'
            });

            tempStudentDetails.add({
              'fullName': fullName,
              'studentGender': gender,
              'studentClass': studentClass,
              'Student_Total_Marks': totalMarks,
              'Teacher_Total_Marks': totalPossibleMarks,
            });
          }
        }

        // Store students by class for position calculation
        if (classStudents.isNotEmpty) {
          studentsByClass[classId] = classStudents;
        }
      }

      // Calculate positions for each class and update Firebase
      for (String classId in studentsByClass.keys) {
        List<Map<String, dynamic>> classStudents = studentsByClass[classId]!;
        int totalClassStudents = classStudents.length;

        // Sort students by performance for position calculation
        if (classId == 'FORM 1' || classId == 'FORM 2') {
          // Sort by Student_Total_Marks descending (higher is better)
          classStudents.sort((a, b) =>
              (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0));
        } else if (classId == 'FORM 3' || classId == 'FORM 4') {
          // Sort by Best_Six_Total_Points ascending (lower is better)
          classStudents.sort((a, b) =>
              (a['Best_Six_Total_Points'] ?? 0).compareTo(b['Best_Six_Total_Points'] ?? 0));
        }

        // Update position for each student
        for (int i = 0; i < classStudents.length; i++) {
          int position = i + 1;
          DocumentReference marksRef = classStudents[i]['marksRef'];

          try {
            await marksRef.set({
              'Student_Class_Position': position,
              'Total_Class_Students_Number': totalClassStudents,
            }, SetOptions(merge: true));
          } catch (e) {
            print("Error updating position for student ${classStudents[i]['fullName']}: $e");
          }
        }
      }

      // Sort students by performance within their respective form groups for display
      tempStudentDetails.sort((a, b) {
        // Sort FORM 1/2 students by Student_Total_Marks descending (higher is better)
        if ((a['studentClass'] == 'FORM 1' || a['studentClass'] == 'FORM 2') &&
            (b['studentClass'] == 'FORM 1' || b['studentClass'] == 'FORM 2')) {
          return (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0);
        }
        // Sort FORM 3/4 students by Best_Six_Total_Points ascending (lower is better)
        else if ((a['studentClass'] == 'FORM 3' || a['studentClass'] == 'FORM 4') &&
            (b['studentClass'] == 'FORM 3' || b['studentClass'] == 'FORM 4')) {
          return (a['Best_Six_Total_Points'] ?? 0).compareTo(b['Best_Six_Total_Points'] ?? 0);
        }
        return 0;
      });

      setState(() {
        studentDetails = tempStudentDetails;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching student details: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching student details.';
      });
    }
  }

// Helper function to convert score to grade point
  String Seniors_Grade(int Seniors_Score) {
    if (Seniors_Score >= 90) return '1';
    if (Seniors_Score >= 80) return '2';
    if (Seniors_Score >= 75) return '3';
    if (Seniors_Score >= 70) return '4';
    if (Seniors_Score >= 65) return '5';
    if (Seniors_Score >= 60) return '6';
    if (Seniors_Score >= 55) return '7';
    if (Seniors_Score >= 50) return '8';
    return '9';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Add a search icon only if data is loaded and no errors
          if (!isLoading && !hasError)
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearchDialog(context);
              },
            ),
        ],
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
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : hasError
            ? Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        )
            : studentDetails.isEmpty
            ? Center(child: Text('No students found.')) // This message shows after loading
            : ListView.separated(
          shrinkWrap: true,
          itemCount: studentDetails.length,
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            var student = studentDetails[index];

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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['fullName'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Text(
                      'Gender: ${student['studentGender']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (student['studentClass'] == 'FORM 1' || student['studentClass'] == 'FORM 2')
                      Text(
                        '${student['Student_Total_Marks']} / ${student['Teacher_Total_Marks']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                    else if (student['studentClass'] == 'FORM 3' || student['studentClass'] == 'FORM 4')
                      Text(
                        '${student['Best_Six_Total_Points'] ?? 0} Points',

                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ],
                ),

                onTap: () {


                  String studentClass = student['studentClass']?.toUpperCase() ?? '';


                  if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {

                    // Junior school report
                    Navigator.push(
                      context,

                      MaterialPageRoute(

                        builder: (context) => Juniors_School_Report_View(

                          studentClass: studentClass,
                          studentFullName: student['fullName'],
                        ),
                      ),

                    );
                  } else if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
                    // Senior school report
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Seniors_School_Report_View(

                          studentClass: studentClass,
                          studentFullName: student['fullName'],

                        ),
                      ),
                    );

                  } else {
                    // Unknown or unsupported class
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unknown Student Class: $studentClass')),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  //final Map<String, dynamic> student;

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search Student'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Enter first or last name',
            ),
            onChanged: (value) {
              setState(() {
                // Filter the student list based on the search query
                studentDetails = studentDetails
                    .where((student) =>
                    student['fullName']
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                    .toList();
              });
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