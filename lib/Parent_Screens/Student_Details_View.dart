import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Log_In_And_Register_Screens/Login_Page.dart';

class Student_Details_View extends StatefulWidget {
  final String? schoolName;
  final String? className;
  final String? studentClass;
  final String? studentName;

  const Student_Details_View({
    Key? key,
    this.schoolName,
    this.className,
    this.studentClass,
    this.studentName,
  }) : super(key: key);

  @override
  State<Student_Details_View> createState() => _Student_Details_ViewState();
}

class _Student_Details_ViewState extends State<Student_Details_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Information
  Map<String, dynamic>? studentPersonalInfo;

  // Parent login data
  String? parentStudentName;
  String? parentStudentClass;
  String? parentFirstName;
  String? parentLastName;
  Map<String, dynamic>? parentStudentDetails;

  // Loading states
  bool _isLoadingStudent = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _actualPath;

  @override
  void initState() {
    super.initState();
    _loadParentDataAndFetchStudent();
  }

  // Load parent data first, then fetch student details
  Future<void> _loadParentDataAndFetchStudent() async {
    setState(() {
      _isLoadingStudent = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load parent data from ParentDataManager
      await ParentDataManager().loadFromPreferences();

      parentStudentName = ParentDataManager().studentName;
      parentStudentClass = ParentDataManager().studentClass;
      parentFirstName = ParentDataManager().firstName;
      parentLastName = ParentDataManager().lastName;
      parentStudentDetails = ParentDataManager().studentDetails;

      print('=== PARENT LOGIN DATA ===');
      print('Student Name: $parentStudentName');
      print('Student Class: $parentStudentClass');
      print('First Name: $parentFirstName');
      print('Last Name: $parentLastName');

      // Use parent data if available, otherwise fall back to widget parameters
      final String effectiveStudentName = parentStudentName ?? widget.studentName ?? '';
      final String effectiveStudentClass = parentStudentClass ?? widget.studentClass ?? '';

      if (effectiveStudentName.isEmpty) {
        throw Exception('No student name available from parent login or widget parameters');
      }

      // If we already have student details from parent login, use them
      if (parentStudentDetails != null && parentStudentDetails!.isNotEmpty) {
        print('Using cached parent student details');
        setState(() {
          studentPersonalInfo = parentStudentDetails;
          _isLoadingStudent = false;
        });
      } else {
        // Fetch student personal information only
        await _fetchStudentPersonalInfo(effectiveStudentName, effectiveStudentClass);
      }

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading parent data: $e';
        _isLoadingStudent = false;
      });
      print('Error loading parent data: $e');
    }
  }

  // Fetch only student personal information
  Future<void> _fetchStudentPersonalInfo(String studentName, String studentClass) async {
    try {
      print('=== FETCHING STUDENT PERSONAL INFO ===');
      print('Student: "$studentName"');
      print('Class: "$studentClass"');

      // Try the most common school first
      final String schoolName = 'Bwaila Secondary School';
      final String basePath = 'Schools/$schoolName/Classes/$studentClass/Student_Details/$studentName';

      print('Base path: $basePath');

      // Check if the main student document exists first
      final DocumentSnapshot mainStudentDoc = await _firestore.doc(basePath).get();

      if (!mainStudentDoc.exists) {
        throw Exception('Student document not found at: $basePath');
      }

      // Fetch Personal Information only
      final String personalInfoPath = '$basePath/Personal_Information/Registered_Information';
      final DocumentSnapshot personalInfoDoc = await _firestore.doc(personalInfoPath).get();

      if (!personalInfoDoc.exists) {
        throw Exception('Personal information not found at: $personalInfoPath');
      }

      // Process the fetched personal data only
      Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;

      setState(() {
        studentPersonalInfo = personalData;
        _actualPath = personalInfoPath;
        _isLoadingStudent = false;
      });

      print('✅ Student personal information loaded successfully!');
      print('Personal Info keys: ${personalData.keys.toList()}');

    } catch (e) {
      // If exact path fails, try to debug what's available
      await _debugAvailableData(studentName, studentClass);

      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading student data: $e';
        _isLoadingStudent = false;
      });
      print('Error fetching student data: $e');
    }
  }

  // Debug method to check what data exists
  Future<void> _debugAvailableData(String studentName, String studentClass) async {
    try {
      print('=== DEBUGGING AVAILABLE DATA ===');

      final String schoolName = 'Bwaila Secondary School';

      // Check if school exists
      final DocumentSnapshot schoolDoc = await _firestore
          .doc('Schools/$schoolName')
          .get();

      if (!schoolDoc.exists) {
        print('❌ School not found: $schoolName');
        return;
      }

      print('✅ School exists: $schoolName');

      // Check if class exists
      final DocumentSnapshot classDoc = await _firestore
          .doc('Schools/$schoolName/Classes/$studentClass')
          .get();

      if (!classDoc.exists) {
        print('❌ Class not found: $studentClass');

        // List available classes
        final QuerySnapshot classesSnapshot = await _firestore
            .collection('Schools/$schoolName/Classes')
            .get();

        if (classesSnapshot.docs.isNotEmpty) {
          print('Available classes:');
          for (var doc in classesSnapshot.docs) {
            print('  - ${doc.id}');
          }
        }
        return;
      }

      print('✅ Class exists: $studentClass');

      // Check available students
      final QuerySnapshot studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$studentClass/Student_Details')
          .get();

      if (studentsSnapshot.docs.isNotEmpty) {
        print('Available students in class:');
        for (var doc in studentsSnapshot.docs) {
          print('  - "${doc.id}"');
        }

        // Check for similar names
        final String targetName = studentName.toLowerCase().trim();
        final List<String> similarNames = studentsSnapshot.docs
            .where((doc) => doc.id.toLowerCase().trim() == targetName)
            .map((doc) => doc.id)
            .toList();

        if (similarNames.isNotEmpty) {
          print('Exact matches found: $similarNames');
        } else {
          print('❌ No exact match for: "$studentName"');
        }
      } else {
        print('❌ No students found in class');
      }

    } catch (e) {
      print('Error in debug: $e');
    }
  }

  // Helper method to get effective student class
  String _getEffectiveStudentClass() {
    return parentStudentClass ?? widget.studentClass ?? 'Unknown Class';
  }

  // Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final List<String> formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy'];

      for (String format in formats) {
        try {
          final DateTime date = DateFormat(format).parse(dateString);
          return DateFormat('dd MMM yyyy').format(date);
        } catch (e) {
          continue;
        }
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to format age
  String _formatAge(dynamic ageValue) {
    if (ageValue == null) return 'N/A';

    String ageString = ageValue.toString();
    if (ageString.isEmpty) return 'N/A';

    final int? age = int.tryParse(ageString);
    if (age != null) {
      return '$age years old';
    }

    return ageString.contains('years') ? ageString : '$ageString years old';
  }

  // Helper method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'N/A';
      }

      final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return timestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Student Information',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF1E40AF),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadParentDataAndFetchStudent,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    if (_isLoadingStudent) {
      return _buildLoadingWidget();
    }

    if (studentPersonalInfo == null) {
      return _buildNoDataWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 30),
        _buildInfoList(),
      ],
    );
  }

  Widget _buildInfoList() {
    final List<Map<String, dynamic>> infoItems = [
      {
        'label': 'First Name',
        'value': studentPersonalInfo!['firstName'] ?? parentFirstName ?? 'N/A',
      },
      {
        'label': 'Last Name',
        'value': studentPersonalInfo!['lastName'] ?? parentLastName ?? 'N/A',
      },
      {
        'label': 'Student ID',
        'value': studentPersonalInfo!['studentID'] ?? 'N/A',
      },
      {
        'label': 'Class',
        'value': studentPersonalInfo!['studentClass'] ?? _getEffectiveStudentClass(),
      },
      {
        'label': 'Gender',
        'value': studentPersonalInfo!['studentGender'] ?? 'N/A',
      },
      {
        'label': 'Date of Birth',
        'value': _formatDate(studentPersonalInfo!['studentDOB']),
      },
      {
        'label': 'Age',
        'value': _formatAge(studentPersonalInfo!['studentAge']),
      },
    ];

    return Column(
      children: infoItems.map((item) => _buildInfoRow(item['label'], item['value'])).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1E40AF),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading student information...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: Color(0xFF1E40AF),
          ),
          SizedBox(height: 24),
          Text(
            'No Information Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Student registration information is not available at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1E40AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFF1E40AF),
          ),
          const SizedBox(height: 24),
          const Text(
            'Unable to Load Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E40AF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _loadParentDataAndFetchStudent,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}