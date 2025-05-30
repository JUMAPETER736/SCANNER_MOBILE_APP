import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/School_Report/Juniors_School_Report_PDF_Lists.dart';
import 'package:scanna/School_Report/Seniors_School_Report_PDF_Lists.dart';

class School_Reports_PDF_List extends StatefulWidget {
  @override
  _School_Reports_PDF_ListState createState() => _School_Reports_PDF_ListState();
}

class _School_Reports_PDF_ListState extends State<School_Reports_PDF_List> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userEmail;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> studentDetails = [];

  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userEmail = user.email!;

      try {
        DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

        if (userDoc.exists) {
          if (userDoc['school'] == null || userDoc['classes'] == null || userDoc['classes'].isEmpty) {
            setState(() {
              hasError = true;
              errorMessage = 'Please select a School and Classes before accessing PDF reports.';
              isLoading = false;
            });
          } else {
            setState(() {
              teacherSchool = userDoc['school'];
              teacherClasses = List<String>.from(userDoc['classes']);
              selectedClass = teacherClasses![0];
              _hasSelectedCriteria = true;
              isLoading = true;
            });
            await _fetchStudentDetailsForClass(userDoc, selectedClass!);
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
          errorMessage = 'Please select a School and Classes before accessing PDF Reports.';
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

  Future<void> _fetchStudentDetailsForClass(DocumentSnapshot userDoc, String classId) async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Map<String, dynamic>> tempStudentDetails = [];

      QuerySnapshot studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(userDoc['school'])
          .collection('Classes')
          .doc(classId)
          .collection('Student_Details')
          .get(GetOptions(source: Source.serverAndCache));

      for (var studentDoc in studentsSnapshot.docs) {
        String studentName = studentDoc.id;

        // Get student gender
        String? gender;
        try {
          DocumentSnapshot personalInfoDoc = await studentDoc.reference
              .collection('Personal_Information')
              .doc('Registered_Information')
              .get(GetOptions(source: Source.serverAndCache));

          if (personalInfoDoc.exists) {
            var personalData = personalInfoDoc.data() as Map<String, dynamic>? ?? {};
            gender = personalData['studentGender'] as String?;
          }
        } catch (e) {
          print("Error fetching personal info for $studentName: $e");
          gender = 'Unknown';
        }

        tempStudentDetails.add({
          'fullName': studentName,
          'studentGender': gender ?? 'Unknown',
          'studentClass': classId,
        });
      }

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
        title: _hasSelectedCriteria
            ? Text(
          '$teacherSchool - PDF Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'PDF Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: _hasSelectedCriteria
            ? Column(
          children: [
            // Class selection buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: (teacherClasses ?? []).map((classItem) {
                  final isSelected = classItem == selectedClass;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          selectedClass = classItem;
                        });

                        DocumentSnapshot userDoc = await _firestore
                            .collection('Teachers_Details')
                            .doc(userEmail)
                            .get();

                        await _fetchStudentDetailsForClass(userDoc, classItem);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.red : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                      ),
                      child: Text(
                        classItem,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 16),

            // Student list
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  strokeWidth: 3,
                ),
              )
                  : hasError
                  ? Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              )
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
                      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['fullName'].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          Text(
                            'Gender: ${student['studentGender'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Class: ${student['studentClass']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onTap: () {
                        String studentClass = student['studentClass']?.toUpperCase() ?? '';

                        // Navigate based on student class
                        if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Juniors_School_Report_PDF_Lists(
                                studentClass: studentClass,
                                studentFullName: student['fullName'],
                              ),
                            ),
                          );
                        }
                        else if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Seniors_School_Report_PDF_Lists(
                                studentClass: studentClass,
                                studentFullName: student['fullName'],
                              ),
                            ),
                          );
                        } else {
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
          ],
        )
            : Center(
          child: isLoading
              ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
            strokeWidth: 3,
          )
              : Text(
            hasError ? errorMessage : 'Please select Class First',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasError ? Colors.red : Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }
}