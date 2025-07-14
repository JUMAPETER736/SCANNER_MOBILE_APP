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
  // Search related variables
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _noSearchResults = false;

  // Teacher and class data
  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;

  // Student data
  List<Map<String, dynamic>> allStudentDetails = [];
  List<Map<String, dynamic>> studentDetails = [];
  int _totalClassStudentsNumber = 0;

  // Current academic year and term
  String _currentAcademicYear = '';
  String _currentTerm = '';

  // Auto-refresh timer
  Timer? _refreshTimer;

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentAcademicYear = _getCurrentAcademicYear();
    _currentTerm = _getCurrentTerm();
    _checkTeacherSelection();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ========== HELPER METHODS ==========

// Get current academic year
  String _getCurrentAcademicYear() {
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;

    // Academic year runs from September 1 to August 30
    // If current month is September-December, use current year as start year
    // If current month is January-August, use previous year as start year
    if (currentMonth >= 9) {
      // September to December: current academic year starts with current year
      return '${currentYear}_${currentYear + 1}';
    } else {
      // January to August: current academic year started with previous year
      return '${currentYear - 1}_${currentYear}';
    }
  }

  // Get current term
  String _getCurrentTerm() {
    final DateTime now = DateTime.now();
    final int month = now.month;
    final int day = now.day;

    if (month >= 9 || month == 12) {
      return 'TERM_ONE';
    } else if (month >= 1 && (month < 3 || (month == 3 && day <= 20))) {
      return 'TERM_TWO';
    } else if (month >= 4 && month <= 8) {
      return 'TERM_THREE';
    } else {
      return 'TERM_ONE';
    }
  }

  // Format term name for display (remove underscores)
  String _getFormattedTerm() {
    return _currentTerm.replaceAll('_', ' ');
  }

  // ========== INITIALIZATION METHODS ==========

  /// Check if teacher has selected school and classes
  void _checkTeacherSelection() async {
    if (widget.loggedInUser != null) {
      try {
        var teacherSnapshot = await _firestore
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
            // Load initial student data
            await _loadStudentData();
          }
        }
      } catch (e) {
        debugPrint('Error checking teacher selection: $e');
      }
    }
  }

  /// Start auto-refresh timer for real-time updates
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_searchQuery.isEmpty && mounted && _hasSelectedCriteria) {
        _loadStudentData();
      }
    });
  }

  // ========== DATA LOADING METHODS ==========

  /// Debug method to check if path exists
  Future<void> _debugFirestorePath() async {
    if (teacherSchool == null || selectedClass == null) return;

    try {
      debugPrint('=== DEBUG: Checking Firestore path ===');

      // Check if school exists
      var schoolDoc = await _firestore.collection('Schools').doc(teacherSchool).get();
      debugPrint('School exists: ${schoolDoc.exists}');

      if (schoolDoc.exists) {
        // Check if academic year exists
        var academicYearDoc = await _firestore
            .collection('Schools')
            .doc(teacherSchool)
            .collection('Academic_Year')
            .doc(_currentAcademicYear)
            .get();
        debugPrint('Academic Year exists: ${academicYearDoc.exists}');

        if (academicYearDoc.exists) {
          // Check if class exists
          var classDoc = await _firestore
              .collection('Schools')
              .doc(teacherSchool)
              .collection('Academic_Year')
              .doc(_currentAcademicYear)
              .collection('Classes')
              .doc(selectedClass)
              .get();
          debugPrint('Class exists: ${classDoc.exists}');

          if (classDoc.exists) {
            // Check if term exists
            var termDoc = await _firestore
                .collection('Schools')
                .doc(teacherSchool)
                .collection('Academic_Year')
                .doc(_currentAcademicYear)
                .collection('Classes')
                .doc(selectedClass)
                .collection(_currentTerm)
                .doc('Term_Informations')
                .get();
            debugPrint('Term_Informations exists: ${termDoc.exists}');

            if (termDoc.exists) {
              // Check Class_List collection
              var classListSnapshot = await _firestore
                  .collection('Schools')
                  .doc(teacherSchool)
                  .collection('Academic_Year')
                  .doc(_currentAcademicYear)
                  .collection('Classes')
                  .doc(selectedClass)
                  .collection(_currentTerm)
                  .doc('Term_Informations')
                  .collection('Class_List')
                  .get();
              debugPrint('Class_List collection has ${classListSnapshot.docs.length} documents');

              // Print document IDs
              for (var doc in classListSnapshot.docs) {
                debugPrint('Student document ID: ${doc.id}');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in debug path: $e');
    }
  }

  /// Load student data from Firestore
  Future<void> _loadStudentData() async {
    if (teacherSchool == null || selectedClass == null) return;

    // Run debug check first
    await _debugFirestorePath();

    try {
      // Debug: Print the exact path being used
      String path = 'Schools/$teacherSchool/Academic_Year/$_currentAcademicYear/Classes/$selectedClass/$_currentTerm/Term_Informations/Class_List';
      debugPrint('Loading students from path: $path');
      debugPrint('School: $teacherSchool');
      debugPrint('Academic Year: $_currentAcademicYear');
      debugPrint('Class: $selectedClass');
      debugPrint('Term: $_currentTerm');

      // Correct path to get student documents
      var snapshot = await _firestore
          .collection('Schools')
          .doc(teacherSchool)
          .collection('Academic_Year')
          .doc(_currentAcademicYear)
          .collection('Classes')
          .doc(selectedClass)
          .collection(_currentTerm)
          .doc('Term_Informations')
          .collection('Class_List')
          .get();

      debugPrint('Number of documents found: ${snapshot.docs.length}');

      List<Map<String, dynamic>> loadedStudents = [];

      for (int index = 0; index < snapshot.docs.length; index++) {
        var studentDoc = snapshot.docs[index];
        debugPrint('Processing student document: ${studentDoc.id}');

        try {
          // Try to get personal information from the student document
          var personalInfoDoc = await studentDoc.reference
              .collection('Personal_Information')
              .doc('Student_Details')
              .get();

          if (personalInfoDoc.exists) {
            debugPrint('Personal info found for ${studentDoc.id}');
            var data = personalInfoDoc.data() as Map<String, dynamic>;
            var firstName = data['First_Name'] ?? 'N/A';
            var lastName = data['Last_Name'] ?? 'N/A';
            var studentGender = data['Student_Gender'] ?? 'N/A';
            var fullName = data['Full_Name'] ?? '$firstName $lastName';

            loadedStudents.add({
              'index': index,
              'firstName': firstName,
              'lastName': lastName,
              'fullName': fullName,
              'studentGender': studentGender,
              'docId': studentDoc.id,
            });
          } else {
            debugPrint('No personal info for ${studentDoc.id}, using document ID as name');
            // If Personal_Information doesn't exist, use the document ID as the name
            // This handles cases where the student name is the document ID itself
            var studentName = studentDoc.id;
            var nameParts = studentName.split(' ');

            loadedStudents.add({
              'index': index,
              'firstName': nameParts.isNotEmpty ? nameParts.first : studentName,
              'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
              'fullName': studentName,
              'studentGender': 'N/A',
              'docId': studentDoc.id,
            });
          }
        } catch (e) {
          debugPrint('Error loading student ${studentDoc.id}: $e');
          // Add student with minimal info if there's an error
          var studentName = studentDoc.id;
          var nameParts = studentName.split(' ');

          loadedStudents.add({
            'index': index,
            'firstName': nameParts.isNotEmpty ? nameParts.first : studentName,
            'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
            'fullName': studentName,
            'studentGender': 'N/A',
            'docId': studentDoc.id,
          });
        }
      }

      debugPrint('Total students loaded: ${loadedStudents.length}');

      // Sort students by full name
      loadedStudents.sort((a, b) => a['fullName'].compareTo(b['fullName']));

      if (mounted) {
        setState(() {
          allStudentDetails = loadedStudents;
          _totalClassStudentsNumber = loadedStudents.length;
          if (_searchQuery.isEmpty) {
            studentDetails = List.from(allStudentDetails);
          } else {
            performSearch(_searchQuery);
          }
        });
      }

      // Update total students count in Firestore
      await _updateTotalStudentsCount();
    } on FirebaseException catch (e) {
      debugPrint('Firebase error loading student data: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update total students count in Firestore
  Future<void> _updateTotalStudentsCount() async {
    if (teacherSchool == null || selectedClass == null) return;

    try {
      // Correct path to update class information
      final DocumentReference classInfoRef = _firestore
          .collection('Schools')
          .doc(teacherSchool)
          .collection('Academic_Year')
          .doc(_currentAcademicYear)
          .collection('Classes')
          .doc(selectedClass)
          .collection(_currentTerm)
          .doc('Term_Informations');

      await classInfoRef.set({
        'Total_Students': _totalClassStudentsNumber,
        'Last_Updated': FieldValue.serverTimestamp(),
        'Class_Name': selectedClass,
        'Academic_Year': _currentAcademicYear,
        'Term_Name': _currentTerm,
      }, SetOptions(merge: true));

      debugPrint('Total students count updated: $_totalClassStudentsNumber');
    } catch (e) {
      debugPrint('Error updating total students count: $e');
    }
  }

  // ========== SEARCH METHODS ==========

  /// Perform search on student list
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

  /// Clear search and reset to show all students
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _noSearchResults = false;
      studentDetails = List.from(allStudentDetails);
    });
  }

  /// Handle class selection change
  void _onClassSelected(String classItem) {
    setState(() {
      selectedClass = classItem;
      _searchQuery = '';
      _noSearchResults = false;
      _searchController.clear();
      allStudentDetails.clear();
      studentDetails.clear();
      _totalClassStudentsNumber = 0;
    });
    _loadStudentData();
  }

  // ========== UI BUILDING METHODS ==========

  @override
  Widget build(BuildContext context) {
    if (widget.loggedInUser == null) {
      return _buildNoUserScaffold();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Build scaffold for when no user is logged in
  Widget _buildNoUserScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Students List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 20),
            Text(
              'No user is logged in.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _hasSelectedCriteria
          ? Text(
        '${_getFormattedTerm()} $selectedClass ',
        style: TextStyle(fontWeight: FontWeight.bold),
      )
          : Text(
        'Students List',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      actions: _hasSelectedCriteria
          ? [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () => _showSearchDialog(context),
        ),

      ]
          : [],
    );
  }

  /// Build main body
  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: _hasSelectedCriteria ? _buildMainContent() : _buildNoSelectionContent(),
    );
  }

  /// Build content when no class is selected
  Widget _buildNoSelectionContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: Colors.blueAccent.withOpacity(0.7),
          ),
          SizedBox(height: 20),
          Text(
            'Please select a class first',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'School: ${teacherSchool ?? 'Not selected'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content with class selection and student list
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildClassSelector(),
        _buildSearchInfo(),
        SizedBox(height: 8),
        Expanded(child: _buildStudentList()),
      ],
    );
  }

  /// Build class selector buttons
  Widget _buildClassSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
      child: Row(
        children: (teacherClasses ?? []).map((classItem) {
          final isSelected = classItem == selectedClass;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            child: ElevatedButton(
              onPressed: () => _onClassSelected(classItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                classItem,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build search information display
  Widget _buildSearchInfo() {
    if (_searchQuery.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Searching for: "$_searchQuery" (${studentDetails.length} found)',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearSearch,
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
    );
  }

  /// Build student list
  Widget _buildStudentList() {
    return FutureBuilder(
      future: allStudentDetails.isEmpty ? _loadStudentData() : null,
      builder: (context, snapshot) {
        if (_isSearching ||
            (allStudentDetails.isEmpty && snapshot.connectionState == ConnectionState.waiting)) {
          return _buildLoadingIndicator();
        }

        if (studentDetails.isEmpty && allStudentDetails.isEmpty) {
          return _buildNoStudentsFound();
        }

        if (_noSearchResults) {
          return _buildNoSearchResults();
        }

        return _buildStudentListView();
      },
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading students...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build no students found message
  Widget _buildNoStudentsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.orange.withOpacity(0.7),
          ),
          SizedBox(height: 20),
          Text(
            'No students found in this class.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Class: $selectedClass',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Build no search results message
  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.red.withOpacity(0.7),
          ),
          SizedBox(height: 20),
          Text(
            'No students found for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: _clearSearch,
            child: Text(
              'Clear Search',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build student list view
  Widget _buildStudentListView() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: studentDetails.length,
        separatorBuilder: (context, index) => SizedBox(height: 6),
        itemBuilder: (context, index) => _buildStudentCard(studentDetails[index]),
      ),
    );
  }

  /// Build individual student card
  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            '${student['index'] + 1}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gender: ${student['studentGender']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            Text(
              'Student ID: ${student['docId']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Colors.blueAccent,
            size: 18),
        onTap: () => _navigateToStudentSubjects(student),
      ),
    );
  }

  /// Navigate to student subjects page
  void _navigateToStudentSubjects(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Student_Subjects(
          studentName: student['fullName'],
          studentClass: selectedClass!,
        ),
      ),
    );
  }

  // ========== DIALOG METHODS ==========

  /// Show search dialog
  void _showSearchDialog(BuildContext context) {
    TextEditingController localSearchController =
    TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
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
                    autofocus: true,
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
                    onSubmitted: (value) {
                      Navigator.of(context).pop();
                      _searchController.text = value.trim();
                      performSearch(value);
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Total students: $_totalClassStudentsNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _searchController.text = localSearchController.text.trim();
                    performSearch(localSearchController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.bold),
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