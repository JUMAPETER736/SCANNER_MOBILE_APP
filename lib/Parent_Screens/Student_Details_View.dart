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
      });

      DocumentSnapshot studentDoc = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentFullName)
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (studentDoc.exists) {
        setState(() {
          studentPersonalInfo = studentDoc.data() as Map<String, dynamic>;
          _isLoadingStudent = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Student information not found';
          _isLoadingStudent = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading student data: $e';
        _isLoadingStudent = false;
      });
    }
  }

  Future<void> _fetchSchoolData() async {
    try {
      setState(() {
        _isLoadingSchool = true;
      });

      DocumentSnapshot schoolDoc = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('School_Information')
          .doc('School_Details')
          .get();

      if (schoolDoc.exists) {
        setState(() {
          schoolInfo = schoolDoc.data() as Map<String, dynamic>;
          _isLoadingSchool = false;
        });
      } else {
        // Set default values if school info doesn't exist
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
    } catch (e) {
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
      print('Error fetching school data: $e');
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
      return dateString;
    }
  }

  String _formatBoxNumber(dynamic boxNumber) {
    if (boxNumber == null || boxNumber == 0) return 'N/A';
    return 'P.O. Box $boxNumber';
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
            const SizedBox(height: 20),
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
                _buildInfoRow('Student ID', studentPersonalInfo!['studentID'] ?? 'N/A', Icons.numbers),
                _buildInfoRow('Class', studentPersonalInfo!['studentClass'] ?? 'N/A', Icons.school),
                _buildInfoRow('Gender', studentPersonalInfo!['studentGender'] ?? 'N/A', Icons.wc),
                _buildInfoRow('Date of Birth', _formatDate(studentPersonalInfo!['studentDOB']), Icons.cake),
                _buildInfoRow('Age', _formatAge(studentPersonalInfo!['studentAge']), Icons.timeline),
                _buildInfoRow('Created By', studentPersonalInfo!['createdBy'] ?? 'N/A', Icons.person_add),
              ],
            ],
          ),
        ),
      ),
    );
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

    final String? studentID = studentPersonalInfo!['studentID'];
    if (studentID == null || studentID.isEmpty) {
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