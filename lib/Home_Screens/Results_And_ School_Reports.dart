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
  List<Map<String, dynamic>> allStudentDetails = [];

  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(Duration(milliseconds: 10));
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
              errorMessage = 'Please select a School and Classes before accessing reports.';
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

  // Helper method to sort students based on their class
  List<Map<String, dynamic>> _sortStudents(List<Map<String, dynamic>> students, String classId) {
    List<Map<String, dynamic>> sortedStudents = List.from(students);

    if (classId == 'FORM 1' || classId == 'FORM 2') {
      // For juniors: higher marks first (descending order)
      sortedStudents.sort((a, b) =>
          (b['Student_Total_Marks'] ?? 0).compareTo(a['Student_Total_Marks'] ?? 0));
    } else if (classId == 'FORM 3' || classId == 'FORM 4') {
      // For seniors: lower points first (ascending order)
      sortedStudents.sort((a, b) =>
          (a['Best_Six_Total_Points'] ?? 0).compareTo(b['Best_Six_Total_Points'] ?? 0));
    }

    return sortedStudents;
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

      List<Future<Map<String, dynamic>?>> studentFutures = [];

      for (var studentDoc in studentsSnapshot.docs) {
        studentFutures.add(_fetchStudentData(studentDoc, classId));
      }

      List<Map<String, dynamic>?> processedStudents = await Future.wait(studentFutures);

      for (var student in processedStudents) {
        if (student != null) {
          tempStudentDetails.add(student);
        }
      }

      // Sort students based on class type
      List<Map<String, dynamic>> sortedStudents = _sortStudents(tempStudentDetails, classId);

      setState(() {
        studentDetails = sortedStudents;
        allStudentDetails = sortedStudents;
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

  Future<Map<String, dynamic>?> _fetchStudentData(
      QueryDocumentSnapshot studentDoc, String classId) async {
    try {
      String studentName = studentDoc.id;

      // Fetch gender information
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

      // Fetch existing marks/points data
      DocumentSnapshot totalMarksDoc = await studentDoc.reference
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get(GetOptions(source: Source.serverAndCache));

      if (!totalMarksDoc.exists) {
        print("No marks data found for student: $studentName");
        return null;
      }

      var marksData = totalMarksDoc.data() as Map<String, dynamic>? ?? {};

      if (classId == 'FORM 3' || classId == 'FORM 4') {
        // Fetch existing senior student data
        return {
          'fullName': studentName,
          'studentGender': gender ?? 'Unknown',
          'studentClass': classId,
          'Best_Six_Total_Points': marksData['Best_Six_Total_Points'] ?? 0,
          'MSCE_Status': marksData['MSCE_Status'] ?? 'Unknown',
          'MSCE_Message': marksData['MSCE_Message'] ?? '',
          'Student_Class_Position': marksData['Student_Class_Position'] ?? 0,
          'Total_Class_Students_Number': marksData['Total_Class_Students_Number'] ?? 0,
          'marksRef': totalMarksDoc.reference,
          'studentType': 'senior'
        };
      } else if (classId == 'FORM 1' || classId == 'FORM 2') {
        // Fetch existing junior student data
        return {
          'fullName': studentName,
          'studentGender': gender ?? 'Unknown',
          'studentClass': classId,
          'Student_Total_Marks': marksData['Student_Total_Marks'] ?? 0,
          'Teacher_Total_Marks': marksData['Teacher_Total_Marks'] ?? 0,
          'JCE_Status': marksData['JCE_Status'] ?? 'Unknown',
          'Student_Class_Position': marksData['Student_Class_Position'] ?? 0,
          'Total_Class_Students_Number': marksData['Total_Class_Students_Number'] ?? 0,
          'marksRef': totalMarksDoc.reference,
          'studentType': 'junior'
        };
      }
    } catch (e) {
      print("Error fetching student data for ${studentDoc.id}: $e");
      return null;
    }
    return null;
  }

  void performSearch(String searchQuery) {
    setState(() {
      _searchQuery = searchQuery.trim();
      _noSearchResults = false;
    });

    if (_searchQuery.isEmpty) {
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

    // Maintain sorting after search
    List<Map<String, dynamic>> sortedFilteredList = _sortStudents(filteredList, selectedClass!);

    setState(() {
      studentDetails = sortedFilteredList;
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
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No students found for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : studentDetails.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No students found in $selectedClass',
                      style: TextStyle(
                        fontSize: 18,
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
                      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
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
                              if (student['studentClass'] == 'FORM 1' || student['studentClass'] == 'FORM 2') ...[
                                Text(
                                  '${student['Student_Total_Marks']} / ${student['Teacher_Total_Marks']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student['JCE_Status'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: student['JCE_Status'] == 'PASS'
                                        ? Colors.green
                                        : student['JCE_Status'] == 'FAIL'
                                        ? Colors.red
                                        : Colors.red,
                                  ),
                                ),
                              ] else if (student['studentClass'] == 'FORM 3' || student['studentClass'] == 'FORM 4') ...[
                                Text(
                                  '${student['Best_Six_Total_Points'] ?? 0} Points',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student['MSCE_Status'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: student['MSCE_Status'] == 'PASS'
                                        ? Colors.green
                                        : student['MSCE_Status'] == 'STATEMENT'
                                        ? Colors.red
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 10),
                          const Icon(
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
                        }
                        else if (studentClass == 'FORM 3' || studentClass == 'FORM 4') {
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
    TextEditingController localSearchController = TextEditingController(
        text: _searchController.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setState) {
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
                    controller: localSearchController,
                    cursorColor: Colors.blueAccent,
                    decoration: InputDecoration(
                      hintText: 'Enter first or last name',
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
                        borderSide: BorderSide(color: Colors.blueAccent,
                            width: 2),
                      ),
                    ),
                    onSubmitted: (value) {
                      Navigator.of(context).pop();
                      _searchController.text = value.trim();
                      performSearch(value.trim());
                    },
                  ),
                  SizedBox(height: 10),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    localSearchController.clear();
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
                    _searchController.text = localSearchController.text.trim();
                    performSearch(localSearchController.text.trim());
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