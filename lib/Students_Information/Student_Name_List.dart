import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Students_Information/Student_Subjects.dart';
import 'dart:async';

class Student_Name_List extends StatefulWidget {
  final User? loggedInUser;

  const Student_Name_List({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _Student_Name_ListState createState() => _Student_Name_ListState();
}

class _Student_Name_ListState extends State<Student_Name_List> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;
  bool _noSearchResults = false;
  bool _isSearching = false;
  Timer? _refreshTimer;
  List<Map<String, dynamic>> allStudentDetails = [];
  List<Map<String, dynamic>> studentDetails = [];

  @override
  void initState() {
    super.initState();
    _checkTeacherSelection();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_searchQuery.isEmpty && mounted) {
        setState(() {
          // This will trigger a rebuild and refresh the StreamBuilder
        });
      }
    });
  }

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
            teacherClasses = List<String>.from(classes);
            selectedClass = classes[0];
            _hasSelectedCriteria = true;
          });
        }
      }
    }
  }

  void performSearch(String searchQuery) {
    setState(() {
      _searchQuery = searchQuery.trim();
      _isSearching = true;
      _noSearchResults = false;
    });

    if (_searchQuery.isEmpty) {
      setState(() {
        studentDetails = List.from(allStudentDetails);
        _isSearching = false;
        _noSearchResults = false;
      });
      return;
    }

    List<Map<String, dynamic>> filteredList = allStudentDetails
        .where((student) =>
    student['fullName']
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()) ||
        student['firstName']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
        student['lastName']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    setState(() {
      studentDetails = filteredList;
      _noSearchResults = filteredList.isEmpty && _searchQuery.isNotEmpty;
      _isSearching = false;
    });
  }

  Future<void> _loadStudentData() async {
    if (teacherSchool == null || selectedClass == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('Schools')
        .doc(teacherSchool)
        .collection('Classes')
        .doc(selectedClass)
        .collection('Student_Details')
        .get();

    List<Map<String, dynamic>> loadedStudents = [];

    for (int index = 0; index < snapshot.docs.length; index++) {
      var studentDoc = snapshot.docs[index];
      var registeredInfoDoc = await studentDoc.reference
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (registeredInfoDoc.exists) {
        var data = registeredInfoDoc.data() as Map<String, dynamic>;
        var firstName = data['firstName'] ?? 'N/A';
        var lastName = data['lastName'] ?? 'N/A';
        var studentGender = data['studentGender'] ?? 'N/A';
        var fullName = '$lastName $firstName';

        loadedStudents.add({
          'index': index,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'studentGender': studentGender,
          'docId': studentDoc.id,
        });
      }
    }

    setState(() {
      allStudentDetails = loadedStudents;
      if (_searchQuery.isEmpty) {
        studentDetails = List.from(allStudentDetails);
      } else {
        performSearch(_searchQuery);
      }
    });
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
          '$teacherSchool',
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
                      onPressed: () {
                        setState(() {
                          selectedClass = classItem;
                          _searchQuery = '';
                          _noSearchResults = false;
                          _searchController.clear();
                          allStudentDetails.clear();
                          studentDetails.clear();
                        });
                        _loadStudentData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.grey[300],
                        foregroundColor:
                        isSelected ? Colors.white : Colors.black,
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

            // Show search query info when searching
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

            SizedBox(height: 8),
            Expanded(
              child: FutureBuilder(
                future: allStudentDetails.isEmpty ? _loadStudentData() : null,
                builder: (context, snapshot) {
                  if (_isSearching || (allStudentDetails.isEmpty && snapshot.connectionState == ConnectionState.waiting)) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    );
                  }


                  // Show no students message
                  if (studentDetails.isEmpty && allStudentDetails.isEmpty) {
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

                  return RefreshIndicator(
                    onRefresh: () async {
                      await _loadStudentData();
                    },
                    child: ListView.separated(
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: studentDetails.length,
                      separatorBuilder: (context, index) => SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        var student = studentDetails[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 12.0),
                            leading: Text(
                              '${student['index'] + 1}.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            title: Text(
                              student['fullName'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            subtitle: Text(
                              'Gender: ${student['studentGender']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward,
                                color: Colors.blueAccent),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Student_Subjects(
                                    studentName: student['fullName'],
                                    studentClass: selectedClass!,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
                    performSearch(localSearchController.text);
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