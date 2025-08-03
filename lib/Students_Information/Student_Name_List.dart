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

  // Auto-refresh timer
  Timer? _refreshTimer;

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Load student data from Firestore
  Future<void> _loadStudentData() async {
    if (teacherSchool == null || selectedClass == null) return;

    try {
      var snapshot = await _firestore
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
    } catch (e) {
      debugPrint('Error loading student data: $e');
    }
  }

  /// Update total students count in Firestore
  Future<void> _updateTotalStudentsCount() async {
    if (teacherSchool == null || selectedClass == null) return;

    try {
      final DocumentReference classInfoRef = _firestore
          .collection('Schools')
          .doc(teacherSchool)
          .collection('Classes')
          .doc(selectedClass)
          .collection('Class_Info')
          .doc('Info');

      await classInfoRef.set({
        'totalStudents': _totalClassStudentsNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
        'className': selectedClass,
        'school': teacherSchool,
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
          'Name of Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text(
          'No user is logged in.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _hasSelectedCriteria
          ? Text(
        '$teacherSchool',
        style: TextStyle(),
      )
          : Text(
        'Name of Students',
        style: TextStyle(fontWeight: FontWeight.w500),
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
            'Please select Class First',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
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
            color: Colors.red.withOpacity(0.7),
          ),
          SizedBox(height: 20),
          Text(
            'No Student Found.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
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
        subtitle: Text(
          'Gender: ${student['studentGender']}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        trailing: Icon(Icons.arrow_forward, color: Colors.blueAccent),
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
                    style: TextStyle(),
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