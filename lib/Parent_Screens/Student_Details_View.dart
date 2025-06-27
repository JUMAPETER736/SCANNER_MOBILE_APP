

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';

class Student_Details_View extends StatefulWidget {
  final String studentName; // Pass the student's full name
  final String studentClass; // Pass the student's class

  const Student_Details_View({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  State<Student_Details_View> createState() => _Student_Details_ViewState();
}

class _Student_Details_ViewState extends State<Student_Details_View> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  User? _loggedInUser;
  String? _schoolName;
  bool _isLoading = true;

  // Student data
  String _firstName = '';
  String _lastName = '';
  String _studentClass = '';
  String _dateOfBirth = '';
  String _age = '';
  String _gender = '';
  String _studentID = '';
  String _createdBy = '';
  DateTime? _timestamp;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // MARK: - Initialization
  Future<void> _initializeData() async {
    try {
      _getCurrentUser();
      await _getSchoolName();
      await _fetchStudentDetails();
    } catch (e) {
      _showErrorMessage('Error loading student details: $e');
    }
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _loggedInUser = user;
    }
  }

  Future<void> _getSchoolName() async {
    try {
      final teacherEmail = _loggedInUser?.email;
      if (teacherEmail == null) {
        throw Exception('No logged in user found');
      }

      final teacherDetails = await _firestore
          .collection('Teachers_Details')
          .doc(teacherEmail)
          .get();

      if (!teacherDetails.exists) {
        throw Exception('Teacher details not found');
      }

      _schoolName = teacherDetails['school'] as String;
    } catch (e) {
      throw Exception('Error getting school name: $e');
    }
  }

  // MARK: - Data Fetching
  Future<void> _fetchStudentDetails() async {
    if (_schoolName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch student's personal information
      final personalInfoDoc = await _firestore
          .collection('Schools')
          .doc(_schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (personalInfoDoc.exists) {
        final data = personalInfoDoc.data() as Map<String, dynamic>;

        setState(() {
          _firstName = data['firstName'] ?? 'N/A';
          _lastName = data['lastName'] ?? 'N/A';
          _studentClass = data['studentClass'] ?? 'N/A';
          _dateOfBirth = data['studentDOB'] ?? 'N/A';
          _age = data['studentAge'] ?? 'N/A';
          _gender = data['studentGender'] ?? 'N/A';
          _studentID = data['studentID'] ?? 'N/A';
          _createdBy = data['createdBy'] ?? 'N/A';

          if (data['timestamp'] != null) {
            _timestamp = (data['timestamp'] as Timestamp).toDate();
          }

          _isLoading = false;
        });
      } else {
        throw Exception('Student details not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Error fetching student details: $e');
    }
  }

  // MARK: - UI Helper Methods
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent,
        ),
      );
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
          children: [
            _buildStudentCard(),
            const SizedBox(height: 24),
            _buildQRCodeCard(),
            const SizedBox(height: 24),
            _buildAdditionalInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                '${_firstName.isNotEmpty ? _firstName[0] : ''}${_lastName.isNotEmpty ? _lastName[0] : ''}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Name
            Text(
              '$_firstName $_lastName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Student ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID: $_studentID',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student Details Grid
            _buildDetailsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDetailItem('Class', _studentClass, Icons.school)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem('Gender', _gender, Icons.person)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem('Age', '$_age years', Icons.cake)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem('DOB', _dateOfBirth, Icons.calendar_today)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
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
          Icon(
            icon,
            size: 24,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Student QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: _studentID,
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan for quick access',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Registered By', _createdBy),
            const SizedBox(height: 12),
            _buildInfoRow('Registration Date', _formatDate(_timestamp)),
            const SizedBox(height: 12),
            _buildInfoRow('School', _schoolName ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}