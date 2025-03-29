import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Home_Screens/SchoolReportView.dart';

class SchoolReports extends StatefulWidget {
  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userEmail;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> studentDetails = []; // List to store student details

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
          errorMessage = 'An error occurred while fetching user details.';
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
      List<Map<String, dynamic>> tempStudentDetails = []; // Temp list to collect all student details

      // Loop through the classes the teacher is assigned to
      for (var classId in userDoc['classes']) {
        // Fetch students for each class from the 'Student_Details' collection
        QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(userDoc['school']) // Use the teacher's school
            .collection('Classes')
            .doc(classId) // Use each class the teacher is assigned to
            .collection('Student_Details')
            .get();

        for (var studentDoc in studentsSnapshot.docs) {
          // Fetch the 'Personal_Information/Registered_Information' document for each student
          DocumentSnapshot registeredInformationDoc = await studentDoc.reference
              .collection('Personal_Information')
              .doc('Registered_Information')
              .get();

          // Retrieve the student's class
          String studentClass = registeredInformationDoc['studentClass'] ?? 'N/A';

          if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
            // For FORM 1 and FORM 2 students, use Student_Total_Marks and Teacher_Total_Marks
            DocumentSnapshot totalMarksDoc = await studentDoc.reference
                .collection('TOTAL_MARKS')
                .doc('Marks')
                .get();

            if (totalMarksDoc.exists) {
              var totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;

              var studentTotalMarks = int.tryParse(totalMarksData['Student_Total_Marks'] ?? '0') ?? 0;
              var teacherTotalMarks = int.tryParse(totalMarksData['Teacher_Total_Marks'] ?? '0') ?? 0;

              // Retrieve student personal details
              var firstName = registeredInformationDoc['firstName'] ?? 'N/A';
              var lastName = registeredInformationDoc['lastName'] ?? 'N/A';
              var gender = registeredInformationDoc['studentGender'] ?? 'N/A';

              var fullName = '$lastName $firstName'; // Combine last and first names

              // Add the student details to the temp list
              tempStudentDetails.add({
                'fullName': fullName,
                'studentGender': gender,
                'Student_Total_Marks': studentTotalMarks,
                'Teacher_Total_Marks': teacherTotalMarks,
              });
            }
          } else if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
            // For FORM 3 and FORM 4 students, use Grade_Point and Subject_Grade
            QuerySnapshot subjectSnapshot = await studentDoc.reference
                .collection('Student_Subjects')
                .get();

            for (var subjectDoc in subjectSnapshot.docs) {
              var subjectData = subjectDoc.data() as Map<String, dynamic>;
              var subjectGrade = int.tryParse(subjectData['Subject_Grade'] ?? '0') ?? 0;
              var subjectName = subjectData['Subject_Name'] ?? 'N/A';

              // Calculate Grade_Point based on Subject_Grade

              int gradePoint = 0;

              if (subjectGrade >= 85) {
                gradePoint = 1;
              } else if (subjectGrade >= 80) {
                gradePoint = 2;
              } else if (subjectGrade >= 75) {
                gradePoint = 3;
              } else if (subjectGrade >= 70) {
                gradePoint = 4;
              } else if (subjectGrade >= 65) {
                gradePoint = 5;
              } else if (subjectGrade >= 60) {
                gradePoint = 6;
              } else if (subjectGrade >= 55) {
                gradePoint = 7;
              } else if (subjectGrade >= 50) {
                gradePoint = 8;
              } else if (subjectGrade <= 49) {
                gradePoint = 9;
              }


              // If Grade_Point is not set in Firestore, create it
              if (subjectData['Grade_Point'] == null) {
                // Set the Grade_Point in the correct path for FORM 3 and FORM 4 students
                await subjectDoc.reference.update({
                  'Grade_Point': gradePoint.toString(),
                });
              }

              // Retrieve student personal details
              var firstName = registeredInformationDoc['firstName'] ?? 'N/A';
              var lastName = registeredInformationDoc['lastName'] ?? 'N/A';
              var gender = registeredInformationDoc['studentGender'] ?? 'N/A';

              var fullName = '$lastName $firstName'; // Combine last and first names

              // Add the student details to the temp list
              tempStudentDetails.add({
                'fullName': fullName,
                'studentGender': gender,
                'Subject_Name': subjectName,
                'Subject_Grade': subjectGrade,
                'Grade_Point': gradePoint,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching student details: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Reports',
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
                  mainAxisSize: MainAxisSize.min, // To prevent stretching
                  children: [
                    // Displaying marks in the "studentMarks/teacherMarks" format in black color
                    Text(
                      '${student['Student_Total_Marks']} / ${student['Teacher_Total_Marks']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Black color for the marks
                      ),
                    ),
                    SizedBox(width: 10), // Add space between marks and forward icon
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SchoolReportView(
                        schoolName: "Your School Name",  // Replace with the actual school name from your data
                        studentClass: student['studentClass'] ?? 'N/A',  // Use the student class from your data
                        studentName: "${student['firstName'] ?? 'N/A'} ${student['lastName'] ?? 'N/A'}",  // Format the student name
                      ),
                    ),
                  );

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