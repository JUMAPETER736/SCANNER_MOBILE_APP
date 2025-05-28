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

  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _noSearchResults = false;

  late String userEmail;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> studentDetails = [];
  List<Map<String, dynamic>> allStudentDetails = []; // Store original list for search reset

  // Added variables for class selection
  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  // Simulate loading for 0.5 seconds (reduced for faster loading)
  Future<void> _simulateLoading() async {
    await Future.delayed(Duration(milliseconds: 500)); // Reduced delay
    _fetchUserDetails();
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
            // Set up class selection variables
            setState(() {
              teacherSchool = userDoc['school'];
              teacherClasses = List<String>.from(userDoc['classes']);
              selectedClass = teacherClasses![0]; // Set the first class as default
              _hasSelectedCriteria = true;
              isLoading = true; // Keep loading until student data is fetched
            });

            // Fetch student details for the selected class initially
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

  // Enhanced MSCE Aggregate calculation with complex rules
  Map<String, dynamic> calculateMSCEAggregate(List<int> subjectPoints) {
    // Rule 1: If best six subject points total < 6, result = FAIL
    if (subjectPoints.length < 6) {
      return {
        'status': 'FAIL',
        'points': 0,
        'message': 'Insufficient subjects (less than 6)'
      };
    }

    // Sort points (lower is better for MSCE)
    subjectPoints.sort();
    List<int> bestSix = subjectPoints.take(6).toList();
    int totalPoints = bestSix.fold(0, (sum, point) => sum + point);

    // Rule 2: If best six includes a Grade 9, result = STATEMENT
    if (bestSix.contains(9)) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Contains Grade 9 in best six subjects'
      };
    }

    // Rule 3: If best six total > 48, result = STATEMENT
    if (totalPoints > 48) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Total points exceed 48'
      };
    }

    // Rule 4: Normal aggregate points display
    return {
      'status': 'PASS',
      'points': totalPoints,
      'message': 'Qualified aggregate'
    };
  }

  // Modified to fetch students for a specific class with improved performance
  Future<void> _fetchStudentDetailsForClass(DocumentSnapshot userDoc, String classId) async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Map<String, dynamic>> tempStudentDetails = [];
      List<Map<String, dynamic>> classStudents = [];

      // Use get() with source preference for faster loading
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(userDoc['school'])
          .collection('Classes')
          .doc(classId)
          .collection('Student_Details')
          .get(GetOptions(source: Source.serverAndCache));

      // Use batch processing for better performance
      List<Future<Map<String, dynamic>?>> studentFutures = [];

      for (var studentDoc in studentsSnapshot.docs) {
        studentFutures.add(_processStudentData(studentDoc, classId));
      }

      // Wait for all students to be processed concurrently
      List<Map<String, dynamic>?> processedStudents = await Future.wait(studentFutures);

      // Filter out null results and separate by type
      for (var student in processedStudents) {
        if (student != null) {
          tempStudentDetails.add(student);
          classStudents.add(student);
        }
      }

      // Calculate positions for the class and update Firebase
      await _updateStudentPositions(classStudents, classId);

      // Store both lists
      setState(() {
        studentDetails = tempStudentDetails;
        allStudentDetails = List.from(tempStudentDetails); // Store original for search reset
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

  // Extract student processing logic for better performance
  Future<Map<String, dynamic>?> _processStudentData(QueryDocumentSnapshot studentDoc, String classId) async {
    try {
      String studentName = studentDoc.id;
      var studentData = studentDoc.data() as Map<String, dynamic>? ?? {};

      // Fetch gender from the nested subcollection
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

      String fullName = studentName;

      // Get total marks document reference
      DocumentReference marksRef = studentDoc.reference
          .collection('TOTAL_MARKS')
          .doc('Marks');

      DocumentSnapshot totalMarksDoc = await marksRef.get(GetOptions(source: Source.serverAndCache));

      if (classId == 'FORM 3' || classId == 'FORM 4') {
        // SENIORS: Calculate Best Six Points with MSCE rules
        List<int> subjectPoints = [];

        var subjectsSnapshot = await studentDoc.reference
            .collection('Student_Subjects')
            .get(GetOptions(source: Source.serverAndCache));

        for (var subjectDoc in subjectsSnapshot.docs) {
          var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};

          if (subjectData.containsKey('Subject_Grade')) {
            var subjectGradeValue = subjectData['Subject_Grade'];

            if (subjectGradeValue == null ||
                subjectGradeValue.toString().toUpperCase() == 'N/A') {
              continue;
            }

            int? subjectScore;
            if (subjectGradeValue is int) {
              subjectScore = subjectGradeValue;
            } else if (subjectGradeValue is String) {
              subjectScore = int.tryParse(subjectGradeValue);
            }

            if (subjectScore != null && subjectScore >= 0) {
              int gradePoint = int.parse(Seniors_Grade(subjectScore));
              subjectPoints.add(gradePoint);
            }
          }
        }

        // Apply MSCE Aggregate Rules
        Map<String, dynamic> msceResult = calculateMSCEAggregate(subjectPoints);
        int bestSixPoints = msceResult['points'];
        String msceStatus = msceResult['status'];
        String msceMessage = msceResult['message'];

        // Update Firebase with MSCE results
        Map<String, dynamic> updateData = {
          'Best_Six_Total_Points': bestSixPoints,
          'MSCE_Status': msceStatus,
          'MSCE_Message': msceMessage,
        };

        if (totalMarksDoc.exists) {
          await marksRef.set(updateData, SetOptions(merge: true));
        } else {
          await marksRef.set(updateData);
        }

        return {
          'fullName': fullName,
          'studentGender': gender ?? 'Unknown',
          'studentClass': classId,
          'Best_Six_Total_Points': bestSixPoints,
          'MSCE_Status': msceStatus,
          'MSCE_Message': msceMessage,
          'marksRef': marksRef,
          'studentType': 'senior'
        };
      } else if (classId == 'FORM 1' || classId == 'FORM 2') {
        // JUNIORS: Calculate total marks from Subject grades
        int totalMarks = 0;
        int totalPossibleMarks = 0;

        var subjectsSnapshot = await studentDoc.reference
            .collection('Student_Subjects')
            .get(GetOptions(source: Source.serverAndCache));

        for (var subjectDoc in subjectsSnapshot.docs) {
          var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};
          if (subjectData.containsKey('Subject_Grade')) {
            var subjectGradeValue = subjectData['Subject_Grade'];

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
              totalPossibleMarks += 100;
            }
          }
        }

        // Update Firebase for juniors
        Map<String, dynamic> updateData = {
          'Student_Total_Marks': totalMarks,
          'Teacher_Total_Marks': totalPossibleMarks,
        };

        if (totalMarksDoc.exists) {
          await marksRef.set(updateData, SetOptions(merge: true));
        } else {
          await marksRef.set(updateData);
        }

        return {
          'fullName': fullName,
          'studentGender': gender ?? 'Unknown',
          'studentClass': classId,
          'Student_Total_Marks': totalMarks,
          'Teacher_Total_Marks': totalPossibleMarks,
          'marksRef': marksRef,
          'studentType': 'junior'
        };
      }
    } catch (e) {
      print("Error processing student $e");
      return null;
    }
    return null;
  }

  // Extract position update logic
  Future<void> _updateStudentPositions(List<Map<String, dynamic>> classStudents, String classId) async {
    int totalClassStudents = classStudents.length;

    // Sort students by performance for position calculation
    if (classId == 'FORM 1' || classId == 'FORM 2') {
      classStudents.sort((a, b) =>
          (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0));
      studentDetails.sort((a, b) =>
          (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0));
    } else if (classId == 'FORM 3' || classId == 'FORM 4') {
      classStudents.sort((a, b) =>
          (a['Best_Six_Total_Points'] ?? 0).compareTo(b['Best_Six_Total_Points'] ?? 0));
      studentDetails.sort((a, b) =>
          (a['Best_Six_Total_Points'] ?? 0).compareTo(b['Best_Six_Total_Points'] ?? 0));
    }

    // Batch update positions
    WriteBatch batch = _firestore.batch();
    for (int i = 0; i < classStudents.length; i++) {
      int position = i + 1;
      DocumentReference marksRef = classStudents[i]['marksRef'];

      batch.set(marksRef, {
        'Student_Class_Position': position,
        'Total_Class_Students_Number': totalClassStudents,
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
    } catch (e) {
      print("Error updating positions: $e");
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

  // Enhanced search functionality with real-time filtering
  void performSearch(String searchQuery) {
    setState(() {
      _searchQuery = searchQuery.trim();
      _noSearchResults = false;
    });

    if (_searchQuery.isEmpty) {
      // Reset to original list
      setState(() {
        studentDetails = List.from(allStudentDetails);
      });
      return;
    }

    List<Map<String, dynamic>> filteredList = allStudentDetails
        .where((student) =>
        student['fullName']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    setState(() {
      studentDetails = filteredList;
      _noSearchResults = filteredList.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _hasSelectedCriteria
            ? Text(
          '$teacherSchool',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          if (!isLoading && !hasError && _hasSelectedCriteria)
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
                          _searchQuery = '';
                          _noSearchResults = false;
                          _searchController.clear();
                        });

                        DocumentSnapshot userDoc = await _firestore
                            .collection('Teachers_Details')
                            .doc(userEmail)
                            .get();

                        await _fetchStudentDetailsForClass(userDoc, classItem);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
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

            // Search status indicator
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Searching for: "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _noSearchResults = false;
                          studentDetails = List.from(allStudentDetails);
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Student list
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
                  : _noSearchResults
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  
                ),
              )
                  : studentDetails.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No students found in $selectedClass.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                            'Gender: ${student['studentGender'] ?? 'Unknown'}',
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                              else if (student['studentClass'] == 'FORM 3' || student['studentClass'] == 'FORM 4') ...[
                                Text(
                                  '${student['Best_Six_Total_Points'] ?? 0} Points',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  student['MSCE_Status'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: student['MSCE_Status'] == 'PASS'
                                        ? Colors.green
                                        : student['MSCE_Status'] == 'FAIL'
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ],
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            strokeWidth: 3,
          )
              : Text(
            hasError ? errorMessage : 'Please select Class First',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasError ? Colors.red : Colors.blueAccent,
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Search Student',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    cursorColor: Colors.blueAccent,
                    decoration: InputDecoration(
                      hintText: 'Enter first or last name',
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _searchController.text = value;
                      });
                    },
                    onSubmitted: (value) {
                      Navigator.of(context).pop();
                      performSearch(value);
                    },
                  ),
                  SizedBox(height: 10),
                  if (_searchController.text.isNotEmpty)
                    Text(
                      'Press Enter or Search to find students',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _searchController.clear();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    performSearch(_searchController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Search',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}