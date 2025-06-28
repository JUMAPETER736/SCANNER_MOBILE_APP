import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';

class Student_Details_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Student_Details_View({
    Key? key,
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
  }) : super(key: key);

  @override
  State<Student_Details_View> createState() => _Student_Details_ViewState();
}

class _Student_Details_ViewState extends State<Student_Details_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Information
  Map<String, dynamic>? studentPersonalInfo;
  Map<String, dynamic>? schoolInfo;

  // Loading states
  bool _isLoadingStudent = true;
  bool _isLoadingSchool = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    _fetchSchoolData();
  }

  // MARK: - Data Fetching Methods
  Future<void> _fetchStudentData() async {
    try {
      setState(() {
        _isLoadingStudent = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Exact path as specified
      final String documentPath = 'Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}/Personal_Information/Registered_Information';

      print('Fetching student data from path: $documentPath');

      // Create document reference using the exact path
      final DocumentReference studentDocRef = _firestore.doc(documentPath);

      print('Document reference created: ${studentDocRef.path}');

      // Get the document
      DocumentSnapshot studentDoc = await studentDocRef.get();

      if (studentDoc.exists && studentDoc.data() != null) {
        final data = studentDoc.data() as Map<String, dynamic>;
        print('Student data fetched successfully: $data');

        setState(() {
          studentPersonalInfo = data;
          _isLoadingStudent = false;
          _hasError = false;
        });
      } else {
        print('Student document does not exist at path: ${studentDocRef.path}');

        // Check if the parent document exists
        await _checkStudentDocumentStructure();
      }
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading student data: ${e.toString()}';
        _isLoadingStudent = false;
      });
    }
  }

  // Helper method to check document structure
  Future<void> _checkStudentDocumentStructure() async {
    try {
      // Check if Student_Details document exists
      final DocumentReference studentDetailsRef = _firestore
          .doc('Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}');

      DocumentSnapshot studentDetailsDoc = await studentDetailsRef.get();

      if (studentDetailsDoc.exists) {
        print('Student_Details document exists, checking Personal_Information collection...');

        // Check Personal_Information collection
        final QuerySnapshot personalInfoQuery = await studentDetailsRef
            .collection('Personal_Information')
            .get();

        if (personalInfoQuery.docs.isNotEmpty) {
          print('Personal_Information collection has ${personalInfoQuery.docs.length} documents');

          // Check if Registered_Information document exists
          final DocumentSnapshot registeredInfoDoc = await studentDetailsRef
              .collection('Personal_Information')
              .doc('Registered_Information')
              .get();

          if (registeredInfoDoc.exists && registeredInfoDoc.data() != null) {
            final data = registeredInfoDoc.data() as Map<String, dynamic>;
            print('Found Registered_Information: $data');

            setState(() {
              studentPersonalInfo = data;
              _isLoadingStudent = false;
              _hasError = false;
            });
          } else {
            print('Registered_Information document does not exist or is empty');
            setState(() {
              _hasError = true;
              _errorMessage = 'Student registration information not found. The document may not be properly created.';
              _isLoadingStudent = false;
            });
          }
        } else {
          print('Personal_Information collection is empty');
          setState(() {
            _hasError = true;
            _errorMessage = 'Student personal information collection is empty.';
            _isLoadingStudent = false;
          });
        }
      } else {
        print('Student_Details document does not exist');
        setState(() {
          _hasError = true;
          _errorMessage = 'Student not found in the database. Please verify the student name: "${widget.studentFullName}" exists in class "${widget.studentClass}".';
          _isLoadingStudent = false;
        });
      }
    } catch (e) {
      print('Error checking document structure: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error verifying student data structure: ${e.toString()}';
        _isLoadingStudent = false;
      });
    }
  }

  Future<void> _fetchSchoolData() async {
    try {
      setState(() {
        _isLoadingSchool = true;
      });

      print('Fetching school data from: Schools/${widget.schoolName}/School_Information/School_Details');

      final DocumentReference schoolDocRef = _firestore
          .doc('Schools/${widget.schoolName}/School_Information/School_Details');

      DocumentSnapshot schoolDoc = await schoolDocRef.get();

      if (schoolDoc.exists && schoolDoc.data() != null) {
        setState(() {
          schoolInfo = schoolDoc.data() as Map<String, dynamic>;
          _isLoadingSchool = false;
        });
        print('School data fetched successfully');
      } else {
        print('School document does not exist, using default values');
        _setDefaultSchoolInfo();
      }
    } catch (e) {
      print('Error fetching school data: $e');
      _setDefaultSchoolInfo();
    }
  }

  void _setDefaultSchoolInfo() {
    setState(() {
      schoolInfo = {
        'Telephone': 'N/A',
        'Email': 'N/A',
        'boxNumber': 0,
        'schoolLocation': 'N/A',
        'School_Fees': 'N/A',
        'School_Bank_Account': 'N/A',
        'Next_Term_Opening_Date': 'N/A',
      };
      _isLoadingSchool = false;
    });
  }

  // Method to debug and list all students in the class
  Future<void> _debugListStudents() async {
    try {
      print('=== DEBUG: Listing all students in class ${widget.studentClass} ===');

      final QuerySnapshot studentsQuery = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .get();

      print('Found ${studentsQuery.docs.length} students in class');

      for (var doc in studentsQuery.docs) {
        print('Student document ID: ${doc.id}');

        // Check if Personal_Information subcollection exists
        final QuerySnapshot personalInfoQuery = await doc.reference
            .collection('Personal_Information')
            .get();

        print('  - Personal_Information documents: ${personalInfoQuery.docs.length}');
        for (var personalDoc in personalInfoQuery.docs) {
          print('    - Document: ${personalDoc.id}');
          if (personalDoc.id == 'Registered_Information') {
            print('    - Data: ${personalDoc.data()}');
          }
        }
      }

      // Also check what we're looking for specifically
      print('\n=== Looking for specific student: ${widget.studentFullName} ===');
      final DocumentReference specificStudentRef = _firestore
          .doc('Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}');

      final DocumentSnapshot specificDoc = await specificStudentRef.get();
      print('Student document exists: ${specificDoc.exists}');

      if (specificDoc.exists) {
        final QuerySnapshot specificPersonalInfo = await specificStudentRef
            .collection('Personal_Information')
            .get();
        print('Personal_Information documents: ${specificPersonalInfo.docs.length}');

        for (var doc in specificPersonalInfo.docs) {
          print('Document: ${doc.id} - ${doc.data()}');
        }
      }
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // MARK: - Helper Methods
  String _formatAge(String? ageString) {
    if (ageString == null || ageString.isEmpty) return 'N/A';
    return '$ageString years old';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final DateFormat inputFormat = DateFormat('dd-MM-yyyy');
      final DateFormat outputFormat = DateFormat('dd MMM yyyy');
      final DateTime date = inputFormat.parse(dateString);
      return outputFormat.format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return dateString;
    }
  }

  String _formatBoxNumber(dynamic boxNumber) {
    if (boxNumber == null || boxNumber == 0) return 'N/A';
    return 'P.O. Box $boxNumber';
  }

  // Generate student ID if not present
  String _getStudentID() {
    if (studentPersonalInfo?['studentID'] != null &&
        studentPersonalInfo!['studentID'].toString().isNotEmpty) {
      return studentPersonalInfo!['studentID'].toString();
    }

    // Generate ID from available data
    final firstName = studentPersonalInfo?['firstName'] ?? '';
    final lastName = studentPersonalInfo?['lastName'] ?? '';
    final studentClass = studentPersonalInfo?['studentClass'] ?? widget.studentClass;

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      // Create ID format: FIRST3LAST3CLASS (e.g., PETJUMFORM1)
      final firstPart = firstName.length >= 3 ? firstName.substring(0, 3) : firstName;
      final lastPart = lastName.length >= 3 ? lastName.substring(0, 3) : lastName;
      final classPart = studentClass.replaceAll(' ', '');
      return '${firstPart.toUpperCase()}${lastPart.toUpperCase()}$classPart';
    }

    return 'N/A';
  }

  // MARK: - Build Methods
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
        // Debug button to help troubleshoot
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _debugListStudents,
          tooltip: 'Debug - List Students',
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _fetchStudentData();
            _fetchSchoolData();
          },
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
            _buildSchoolInfoCard(),
            const SizedBox(height: 20),
            _buildQRCodeCard(),
            const SizedBox(height: 20),
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expected path:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}/Personal_Information/Registered_Information',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
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
                  onPressed: () {
                    _fetchStudentData();
                    _fetchSchoolData();
                  },
                  child: const Text('Retry'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _debugListStudents,
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
                _buildInfoRow('Full Name', widget.studentFullName, Icons.badge),
                _buildInfoRow('First Name', studentPersonalInfo!['firstName'] ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Last Name', studentPersonalInfo!['lastName'] ?? 'N/A', Icons.person_outline),
                _buildInfoRow('Student ID', _getStudentID(), Icons.numbers),
                _buildInfoRow('Class', studentPersonalInfo!['studentClass'] ?? widget.studentClass, Icons.school),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }

      final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'N/A';
    }
  }

  Widget _buildSchoolInfoCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'School Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoadingSchool)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              else if (schoolInfo != null) ...[
                _buildInfoRow('School Name', widget.schoolName, Icons.account_balance),
                _buildInfoRow('Telephone', schoolInfo!['Telephone'] ?? 'N/A', Icons.phone),
                _buildInfoRow('Email', schoolInfo!['Email'] ?? 'N/A', Icons.email),
                _buildInfoRow('Address', _formatBoxNumber(schoolInfo!['boxNumber']), Icons.location_on),
                _buildInfoRow('Location', schoolInfo!['schoolLocation'] ?? 'N/A', Icons.place),
                _buildInfoRow('School Fees', schoolInfo!['School_Fees'] ?? 'N/A', Icons.attach_money),
                _buildInfoRow('Bank Account', schoolInfo!['School_Bank_Account'] ?? 'N/A', Icons.account_balance_wallet),
                _buildInfoRow('Next Term Opens', _formatDate(schoolInfo!['Next_Term_Opening_Date']), Icons.calendar_today),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    if (_isLoadingStudent || studentPersonalInfo == null) {
      return const SizedBox.shrink();
    }

    final String studentID = _getStudentID();
    if (studentID == 'N/A') {
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
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
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: studentID,
                      width: 180,
                      height: 180,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: $studentID',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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