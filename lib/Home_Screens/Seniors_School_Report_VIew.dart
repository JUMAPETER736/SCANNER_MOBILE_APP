import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Seniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_School_Report_ViewState createState() =>
      _Seniors_School_Report_ViewState();
}

class _Seniors_School_Report_ViewState extends State<Seniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? studentInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      // Reference to the specific student document
      final studentDoc = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentFullName)
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (!studentDoc.exists) {
        print('❌ Error: Personal information for ${widget.studentFullName} not found.');
        setState(() {
          studentInfo = {}; // Clear previous data if needed
          isLoading = false;
        });
        return;
      }

      final studentData = studentDoc.data()!;
      print('📋 Student Information for ${widget.studentFullName}: $studentData');
      print('🏫 School Name: ${widget.schoolName}'); // Print the school name

      setState(() {
        studentInfo = {
          'schoolName': widget.schoolName, // Include the school name
          'createdBy': studentData['createdBy'] ?? 'N/A',
          'firstName': studentData['firstName'] ?? 'N/A',
          'lastName': studentData['lastName'] ?? 'N/A',
          'studentAge': studentData['studentAge'] ?? 'N/A',
          'studentClass': studentData['studentClass'] ?? 'N/A',
          'studentGender': studentData['studentGender'] ?? 'N/A',
          'studentID': studentData['studentID'] ?? 'N/A',
          'timestamp': studentData['timestamp']?.toDate().toString() ?? 'N/A',
        };
        isLoading = false;
      });
    } catch (e, stacktrace) {
      print('❗ Exception while fetching student data: $e');
      print(stacktrace);
      setState(() {
        isLoading = false; // Set loading to false on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Senior Student Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School: ${widget.schoolName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${studentInfo?['firstName'] ?? 'N/A'} ${studentInfo?['lastName'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Class: ${widget.studentClass}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Info
            buildCardSection(
              title: 'Personal Information:',
              children: [
                Text('School Name: ${studentInfo?['schoolName'] ?? 'N/A'}'),
                Text('Created By: ${studentInfo?['createdBy'] ?? 'N/A'}'),
                Text('First Name: ${studentInfo?['firstName'] ?? 'N/A'}'),
                Text('Last Name: ${studentInfo?['lastName'] ?? 'N/A'}'),
                Text('Age: ${studentInfo?['studentAge'] ?? 'N/A'}'),
                Text('Gender: ${studentInfo?['studentGender'] ?? 'N/A'}'),
                Text('Student ID: ${studentInfo?['studentID'] ?? 'N/A'}'),
                Text('Timestamp: ${studentInfo?['timestamp'] ?? 'N/A'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCardSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}