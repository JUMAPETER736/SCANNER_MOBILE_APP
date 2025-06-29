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

  // Helper method to get effective student name
  String _getEffectiveStudentName() {
    return parentStudentName ?? widget.studentName ?? 'Unknown Student';
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

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Student Registration Information',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadParentDataAndFetchStudent,
          tooltip: 'Refresh Data',
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _showDebugInfo,
          tooltip: 'Debug Info',
        ),
      ],
    );
  }

  // Show debug information
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent Login Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Student Name: ${parentStudentName ?? "N/A"}'),
              Text('Student Class: ${parentStudentClass ?? "N/A"}'),
              Text('First Name: ${parentFirstName ?? "N/A"}'),
              Text('Last Name: ${parentLastName ?? "N/A"}'),
              const SizedBox(height: 10),
              const Text('Widget Parameters:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('School: ${widget.schoolName ?? "N/A"}'),
              Text('Class: ${widget.studentClass ?? "N/A"}'),
              Text('Student: ${widget.studentName ?? "N/A"}'),
              const SizedBox(height: 10),
              if (_actualPath != null) ...[
                const Text('Successful Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_actualPath!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 10),
              ],
              if (studentPersonalInfo != null) ...[
                const Text('Personal Info Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(studentPersonalInfo!.keys.join(', ')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlueAccent.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildStudentPersonalInfoCard(),
          ],
        ),
      ),
    );
  }



  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _loadParentDataAndFetchStudent,
                  child: const Text('Retry'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showDebugInfo,
                  child: const Text('Debug'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Main student personal information card
  Widget _buildStudentPersonalInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Student Registration Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoadingStudent)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                )
              else if (studentPersonalInfo != null) ...[
                _buildInfoRow('First Name', studentPersonalInfo!['firstName'] ?? parentFirstName ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Last Name', studentPersonalInfo!['lastName'] ?? parentLastName ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Student ID', studentPersonalInfo!['studentID'] ?? 'N/A', Icons.numbers),
                _buildInfoRow('Class', studentPersonalInfo!['studentClass'] ?? _getEffectiveStudentClass(), Icons.school),
                _buildInfoRow('Gender', studentPersonalInfo!['studentGender'] ?? 'N/A', Icons.wc),
                _buildInfoRow('Date of Birth', _formatDate(studentPersonalInfo!['studentDOB']), Icons.cake),
                _buildInfoRow('Age', _formatAge(studentPersonalInfo!['studentAge']), Icons.timeline),
                if (studentPersonalInfo!['timestamp'] != null)
                  _buildInfoRow('Registered', _formatTimestamp(studentPersonalInfo!['timestamp']), Icons.access_time),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No student registration information available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}