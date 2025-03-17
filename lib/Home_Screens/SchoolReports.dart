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

          // Fetch the 'TOTAL_MARKS/Marks' document for the student
          DocumentSnapshot totalMarksDoc = await studentDoc.reference
              .collection('TOTAL_MARKS')
              .doc('Marks')
              .get();

          // Check if both documents exist
          if (registeredInformationDoc.exists && totalMarksDoc.exists) {
            var registeredData = registeredInformationDoc.data() as Map<String, dynamic>;
            var totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;

            // Retrieve student personal details
            var firstName = registeredData['firstName'] ?? 'N/A';
            var lastName = registeredData['lastName'] ?? 'N/A';
            var gender = registeredData['studentGender'] ?? 'N/A';

            // Retrieve the total marks as strings and convert to integers
            var studentTotalMarks = int.tryParse(totalMarksData['Student_Total_Marks'] ?? '0') ?? 0;
            var teacherTotalMarks = int.tryParse(totalMarksData['Teacher_Total_Marks'] ?? '0') ?? 0;

            var fullName = '$lastName $firstName'; // Combine last and first names

            // Add the student details to the temp list
            tempStudentDetails.add({
              'fullName': fullName,
              'studentGender': gender,
              'Student_Total_Marks': studentTotalMarks,
              'Teacher_Total_Marks': teacherTotalMarks,
            });
          }
        }
      }

      // Sort the list of students by their total marks in descending order
      tempStudentDetails.sort((a, b) => b['Student_Total_Marks'].compareTo(a['Student_Total_Marks']));

      // Update the state after all data is fetched and sorted
      setState(() {
        studentDetails = tempStudentDetails; // Store the fetched and sorted student details
        isLoading = false; // Set loading to false after data is fetched
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
                        student: student,
                        studentName: "${student['firstName'] ?? 'N/A'} ${student['lastName'] ?? 'N/A'}",
                        teacherEmail: student['createdBy'] ?? 'No email provided', // Assuming createdBy is the teacher's email
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