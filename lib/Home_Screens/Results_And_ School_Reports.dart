

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Home_Screens/Juniors_School_Report_View.dart';
import 'package:scanna/Home_Screens/Seniors_School_Report_View.dart';


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

      for (var classId in userDoc['classes']) {
        QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(userDoc['school'])
            .collection('Classes')
            .doc(classId)
            .collection('Student_Details')
            .get();

        for (var studentDoc in studentsSnapshot.docs) {
          DocumentSnapshot registeredInformationDoc = await studentDoc.reference
              .collection('Personal_Information')
              .doc('Registered_Information')
              .get();

          DocumentReference marksRef = studentDoc.reference
              .collection('TOTAL_MARKS')
              .doc('Marks');

          DocumentSnapshot totalMarksDoc = await marksRef.get();

          if (registeredInformationDoc.exists && totalMarksDoc.exists) {
            var registeredData = registeredInformationDoc.data() as Map<String, dynamic>;
            var totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;

            var firstName = registeredData['firstName'] ?? 'N/A';
            var lastName = registeredData['lastName'] ?? 'N/A';
            var gender = registeredData['studentGender'] ?? 'N/A';
            var studentClass = registeredData['studentClass'] ?? 'N/A';
            var fullName = '$lastName $firstName';

            if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
              List<int> subjectPoints = [];

              var subjectsSnapshot = await studentDoc.reference.collection('Student_Subjects').get();
              for (var subjectDoc in subjectsSnapshot.docs) {
                if (subjectDoc.exists && subjectDoc.data().containsKey('Grade_Point')) {
                  int gradePoint = subjectDoc['Grade_Point'] ?? 0;
                  subjectPoints.add(gradePoint);
                }
              }

              int bestSixPoints = 0;
              if (subjectPoints.isNotEmpty) {
                subjectPoints.sort((a, b) => b.compareTo(a)); // Sort descending
                bestSixPoints = subjectPoints.take(6).reduce((a, b) => a + b);
              }

              int? existingBestSixPoints = totalMarksData['Best_Six_Total_Points'];

              if (existingBestSixPoints == null) {
                // Create Best_Six_Total_Points if it does not exist
                await marksRef.set({
                  'Best_Six_Total_Points': bestSixPoints,
                }, SetOptions(merge: true));
              } else if (existingBestSixPoints != bestSixPoints) {
                // Update Best_Six_Total_Points if it already exists but changed
                await marksRef.update({
                  'Best_Six_Total_Points': bestSixPoints,
                });
              }

              tempStudentDetails.add({
                'fullName': fullName,
                'studentGender': gender,
                'studentClass': studentClass,
                'Best_Six_Total_Points': existingBestSixPoints ?? bestSixPoints,

              });
            }

            else if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
              var studentTotalMarks = totalMarksData['Student_Total_Marks'] ?? 0;
              var teacherTotalMarks = totalMarksData['Teacher_Total_Marks'] ?? 0;

              tempStudentDetails.add({
                'fullName': fullName,
                'studentGender': gender,
                'studentClass': studentClass,
                'Student_Total_Marks': studentTotalMarks,
                'Teacher_Total_Marks': teacherTotalMarks,
              });
            }
          }
        }
      }

      // 🔹 Sort FORM 1/2 students by Student_Total_Marks descending
      tempStudentDetails.sort((a, b) {
        if ((a['studentClass'] == 'FORM 1' || a['studentClass'] == 'FORM 2') &&
            (b['studentClass'] == 'FORM 1' || b['studentClass'] == 'FORM 2')) {
          return (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0);
        }
        return 0;
      });

      // 🔹 Sort FORM 3/4 students by Best_Six_Total_Points ascending
      tempStudentDetails.sort((a, b) {
        if ((a['studentClass'] == 'FORM 3' || a['studentClass'] == 'FORM 4') &&
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