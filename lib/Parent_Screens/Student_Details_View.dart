import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';

class Student_Details_View extends StatefulWidget {
  final String schoolName;
  final String className;
  final String studentClass;
  final String studentName;

  const Student_Details_View({
    Key? key,
    required this.schoolName,
    required this.className,
    required this.studentClass,
    required this.studentName,
  }) : super(key: key);

  @override
  State<Student_Details_View> createState() => _Student_Details_ViewState();
}

class _Student_Details_ViewState extends State<Student_Details_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Information
  Map<String, dynamic>? studentPersonalInfo;
  Map<String, dynamic>? studentSubjects;
  Map<String, dynamic>? studentMarks;
  Map<String, dynamic>? studentRemarks;

  // Loading states
  bool _isLoadingStudent = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _actualPath;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  // Fetch student data using the exact path structure from the save method
  Future<void> _fetchStudentData() async {
    setState(() {
      _isLoadingStudent = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Clean and normalize the input parameters exactly as in save method
      final String cleanSchoolName = widget.schoolName.trim();
      final String cleanStudentClass = widget.studentClass.trim();
      final String cleanStudentName = widget.studentName.trim();

      print('=== FETCHING STUDENT DATA ===');
      print('School: "$cleanSchoolName"');
      print('Class: "$cleanStudentClass"');
      print('Student: "$cleanStudentName"');

      // Use the exact path structure from the save method
      final String basePath = 'Schools/$cleanSchoolName/Classes/$cleanStudentClass/Student_Details/$cleanStudentName';

      print('Base path: $basePath');

      // Check if the main student document exists first
      final DocumentSnapshot mainStudentDoc = await _firestore.doc(basePath).get();

      if (!mainStudentDoc.exists) {
        throw Exception('Student document not found at: $basePath');
      }

      // Fetch Personal Information (exactly as saved)
      final String personalInfoPath = '$basePath/Personal_Information/Registered_Information';
      final DocumentSnapshot personalInfoDoc = await _firestore.doc(personalInfoPath).get();

      if (!personalInfoDoc.exists) {
        throw Exception('Personal information not found at: $personalInfoPath');
      }

      // Fetch Student Subjects
      final QuerySnapshot subjectsSnapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get();

      // Fetch Total Marks
      final DocumentSnapshot totalMarksDoc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Marks')
          .get();

      // Fetch Results Remarks
      final DocumentSnapshot remarksDoc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Results_Remarks')
          .get();

      // Process the fetched data
      Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;

      Map<String, dynamic> subjectsData = {};
      for (var doc in subjectsSnapshot.docs) {
        subjectsData[doc.id] = doc.data();
      }

      Map<String, dynamic> marksData = {};
      if (totalMarksDoc.exists) {
        marksData = totalMarksDoc.data() as Map<String, dynamic>;
      }

      Map<String, dynamic> remarksData = {};
      if (remarksDoc.exists) {
        remarksData = remarksDoc.data() as Map<String, dynamic>;
      }

      setState(() {
        studentPersonalInfo = personalData;
        studentSubjects = subjectsData;
        studentMarks = marksData;
        studentRemarks = remarksData;
        _actualPath = personalInfoPath;
        _isLoadingStudent = false;
      });

      print('✅ Student data loaded successfully!');
      print('Personal Info keys: ${personalData.keys.toList()}');
      print('Number of subjects: ${subjectsData.length}');

    } catch (e) {
      // If exact path fails, try to debug what's available
      await _debugAvailableData();

      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading student data: $e';
        _isLoadingStudent = false;
      });
      print('Error fetching student data: $e');
    }
  }

  // Debug method to check what data exists
  Future<void> _debugAvailableData() async {
    try {
      print('=== DEBUGGING AVAILABLE DATA ===');

      final String cleanSchoolName = widget.schoolName.trim();
      final String cleanStudentClass = widget.studentClass.trim();

      // Check if school exists
      final DocumentSnapshot schoolDoc = await _firestore
          .doc('Schools/$cleanSchoolName')
          .get();

      if (!schoolDoc.exists) {
        print('❌ School not found: $cleanSchoolName');
        return;
      }

      print('✅ School exists: $cleanSchoolName');

      // Check if class exists
      final DocumentSnapshot classDoc = await _firestore
          .doc('Schools/$cleanSchoolName/Classes/$cleanStudentClass')
          .get();

      if (!classDoc.exists) {
        print('❌ Class not found: $cleanStudentClass');

        // List available classes
        final QuerySnapshot classesSnapshot = await _firestore
            .collection('Schools/$cleanSchoolName/Classes')
            .get();

        if (classesSnapshot.docs.isNotEmpty) {
          print('Available classes:');
          for (var doc in classesSnapshot.docs) {
            print('  - ${doc.id}');
          }
        }
        return;
      }

      print('✅ Class exists: $cleanStudentClass');

      // Check available students
      final QuerySnapshot studentsSnapshot = await _firestore
          .collection('Schools/$cleanSchoolName/Classes/$cleanStudentClass/Student_Details')
          .get();

      if (studentsSnapshot.docs.isNotEmpty) {
        print('Available students in class:');
        for (var doc in studentsSnapshot.docs) {
          print('  - "${doc.id}"');
        }

        // Check for similar names
        final String targetName = widget.studentName.toLowerCase().trim();
        final List<String> similarNames = studentsSnapshot.docs
            .where((doc) => doc.id.toLowerCase().trim() == targetName)
            .map((doc) => doc.id)
            .toList();

        if (similarNames.isNotEmpty) {
          print('Exact matches found: $similarNames');
        } else {
          print('❌ No exact match for: "${widget.studentName}"');
        }
      } else {
        print('❌ No students found in class');
      }

    } catch (e) {
      print('Error in debug: $e');
    }
  }

  // Helper method to get student ID safely
  String _getStudentID() {
    return studentPersonalInfo?['studentID'] ?? 'N/A';
  }

  // Helper method to format date (same as original)
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

  // Helper method to format age (same as original)
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

  // Helper method to format timestamp (same as original)
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
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Student Details',
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
          onPressed: _fetchStudentData,
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
              Text('School: ${widget.schoolName}'),
              Text('Class: ${widget.studentClass}'),
              Text('Student: ${widget.studentName}'),
              const SizedBox(height: 10),
              if (_actualPath != null) ...[
                const Text('Successful Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_actualPath!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 10),
              ],
              if (studentPersonalInfo != null) ...[
                const Text('Personal Info Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(studentPersonalInfo!.keys.join(', ')),
                const SizedBox(height: 10),
              ],
              if (studentSubjects != null) ...[
                const Text('Subjects:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${studentSubjects!.length} subjects found'),
                Text(studentSubjects!.keys.join(', ')),
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
            _buildStudentPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildSubjectsCard(),
            const SizedBox(height: 20),
            _buildMarksCard(),
            const SizedBox(height: 20),
            _buildQRCodeCard(),
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
                  onPressed: _fetchStudentData,
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
                    'Personal Information',
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
                _buildInfoRow('Full Name', widget.studentName, Icons.badge),
                _buildInfoRow('First Name', studentPersonalInfo!['firstName'] ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Last Name', studentPersonalInfo!['lastName'] ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Student ID', studentPersonalInfo!['studentID'] ?? 'N/A', Icons.numbers),
                _buildInfoRow('Class', studentPersonalInfo!['studentClass'] ?? widget.studentClass, Icons.school),
                _buildInfoRow('Gender', studentPersonalInfo!['studentGender'] ?? 'N/A', Icons.wc),
                _buildInfoRow('Date of Birth', _formatDate(studentPersonalInfo!['studentDOB']), Icons.cake),
                _buildInfoRow('Age', _formatAge(studentPersonalInfo!['studentAge']), Icons.timeline),
                if (studentPersonalInfo!['createdBy'] != null)
                  _buildInfoRow('Created By', studentPersonalInfo!['createdBy'] ?? 'N/A', Icons.person_add),
                if (studentPersonalInfo!['timestamp'] != null)
                  _buildInfoRow('Registered', _formatTimestamp(studentPersonalInfo!['timestamp']), Icons.access_time),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No student data available',
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

  Widget _buildSubjectsCard() {
    if (_isLoadingStudent || studentSubjects == null || studentSubjects!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.white],
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
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.subject,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Subjects (${studentSubjects!.length})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: studentSubjects!.entries.map((entry) {
                  final subject = entry.value as Map<String, dynamic>;
                  final subjectName = subject['Subject_Name'] ?? entry.key;
                  final grade = subject['Subject_Grade'] ?? 'N/A';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Grade: $grade',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarksCard() {
    if (_isLoadingStudent || (studentMarks == null || studentMarks!.isEmpty) && (studentRemarks == null || studentRemarks!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
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
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.grade,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Academic Performance',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (studentMarks != null) ...[
                _buildInfoRow('Aggregate Grade', studentMarks!['Aggregate_Grade'] ?? 'N/A', Icons.star),
                _buildInfoRow('Best Six Total Points', studentMarks!['Best_Six_Total_Points']?.toString() ?? '0', Icons.trending_up),
                _buildInfoRow('Student Total Marks', studentMarks!['Student_Total_Marks'] ?? '0', Icons.calculate),
                _buildInfoRow('Teacher Total Marks', studentMarks!['Teacher_Total_Marks'] ?? '0', Icons.assignment_turned_in),
              ],
              if (studentRemarks != null) ...[
                const SizedBox(height: 16),
                _buildInfoRow('Form Teacher Remark', studentRemarks!['Form_Teacher_Remark'] ?? 'N/A', Icons.comment),
                _buildInfoRow('Head Teacher Remark', studentRemarks!['Head_Teacher_Remark'] ?? 'N/A', Icons.school),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    if (_isLoadingStudent || studentPersonalInfo == null) return const SizedBox.shrink();

    final String studentID = _getStudentID();
    if (studentID == 'N/A' || studentID.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Student QR Code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: studentID,
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Student ID: $studentID',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan this QR code for quick student identification',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}