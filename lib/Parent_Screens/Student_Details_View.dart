import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Log_In_And_Register_Screens/Login_Page.dart';

class Student_Details_View extends StatefulWidget {
  const Student_Details_View({Key? key,
    required String schoolName,
    required String className,
    required String studentClass,
    required String studentName}) : super(key: key);

  @override
  State<Student_Details_View> createState() => _Student_Details_ViewState();
}

class _Student_Details_ViewState extends State<Student_Details_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Information
  Map<String, dynamic>? studentPersonalInfo;

  // Parent login data from ParentDataManager
  String? schoolName;
  String? studentName;
  String? studentClass;
  String? firstName;
  String? lastName;
  Map<String, dynamic>? studentDetails;

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

      schoolName = ParentDataManager().schoolName;
      studentName = ParentDataManager().studentName;
      studentClass = ParentDataManager().studentClass;
      firstName = ParentDataManager().firstName;
      lastName = ParentDataManager().lastName;
      studentDetails = ParentDataManager().studentDetails;

      print('=== PARENT LOGIN DATA ===');
      print('School Name: $schoolName');
      print('Student Name: $studentName');
      print('Student Class: $studentClass');
      print('First Name: $firstName');
      print('Last Name: $lastName');

      // Validate required data
      if (schoolName == null || schoolName!.isEmpty) {
        throw Exception('School name not available from parent login data');
      }

      if (studentName == null || studentName!.isEmpty) {
        throw Exception('Student name not available from parent login data');
      }

      if (studentClass == null || studentClass!.isEmpty) {
        throw Exception('Student class not available from parent login data');
      }

      // If we already have student details from parent login, use them
      if (studentDetails != null && studentDetails!.isNotEmpty) {
        print('Using cached parent student details');
        setState(() {
          studentPersonalInfo = studentDetails;
          _isLoadingStudent = false;
        });
      } else {
        // Fetch student personal information from Firestore
        await _fetchStudentPersonalInfo();
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

  // Fetch student personal information using ParentDataManager data
  Future<void> _fetchStudentPersonalInfo() async {
    try {
      print('=== FETCHING STUDENT PERSONAL INFO ===');
      print('School: "$schoolName"');
      print('Student: "$studentName"');
      print('Class: "$studentClass"');

      // Try different path strategies based on how the data was saved during login
      List<String> possiblePaths = [
        'Schools/$schoolName/Classes/$studentClass/Student_Details/$studentName',
      ];

      // Also try with different name variations if the original fails
      if (firstName != null && lastName != null) {
        possiblePaths.addAll([
          'Schools/$schoolName/Classes/$studentClass/Student_Details/$firstName $lastName',
          'Schools/$schoolName/Classes/$studentClass/Student_Details/${firstName!.toUpperCase()} ${lastName!.toUpperCase()}',
        ]);
      }

      Map<String, dynamic>? personalData;
      String? successfulPath;

      // Try each possible path
      for (String basePath in possiblePaths) {
        try {
          print('Trying path: $basePath');

          final DocumentSnapshot mainStudentDoc = await _firestore.doc(basePath).get();

          if (mainStudentDoc.exists) {
            print('✅ Found student document at: $basePath');

            // Fetch Personal Information
            final String personalInfoPath = '$basePath/Personal_Information/Registered_Information';
            final DocumentSnapshot personalInfoDoc = await _firestore.doc(personalInfoPath).get();

            if (personalInfoDoc.exists) {
              personalData = personalInfoDoc.data() as Map<String, dynamic>;
              successfulPath = personalInfoPath;
              print('✅ Found personal information at: $personalInfoPath');
              break; // Success - exit the loop
            } else {
              print('⚠️ Student document exists but no personal information at: $personalInfoPath');
            }
          } else {
            print('❌ No document found at: $basePath');
          }
        } catch (e) {
          print('❌ Error trying path $basePath: $e');
          continue; // Try next path
        }
      }

      if (personalData != null && successfulPath != null) {
        // Save the fetched data back to ParentDataManager for future use
        ParentDataManager().setParentData(
          schoolName: schoolName!,
          studentName: studentName!,
          studentClass: studentClass!,
          firstName: firstName,
          lastName: lastName,
          studentDetails: personalData,
        );
        await ParentDataManager().saveToPreferences();

        setState(() {
          studentPersonalInfo = personalData;
          _actualPath = successfulPath;
          _isLoadingStudent = false;
        });

        print('✅ Student personal information loaded and cached successfully!');
        print('Personal Info keys: ${personalData.keys.toList()}');
      } else {
        throw Exception('Student personal information not found in any expected location');
      }

    } catch (e) {
      print('❌ All direct paths failed, trying comprehensive search...');

      // If direct paths fail, try comprehensive search
      Map<String, dynamic>? searchResult = await _comprehensiveStudentSearch();

      if (searchResult != null) {
        setState(() {
          studentPersonalInfo = searchResult;
          _isLoadingStudent = false;
        });
        print('✅ Student found via comprehensive search!');
      } else {
        // If comprehensive search also fails, try to debug what's available
        await _debugAvailableData();

        setState(() {
          _hasError = true;
          _errorMessage = 'Error loading student data: $e';
          _isLoadingStudent = false;
        });
        print('Error fetching student data: $e');
      }
    }
  }

  // Comprehensive search method when direct paths fail
  Future<Map<String, dynamic>?> _comprehensiveStudentSearch() async {
    try {
      print('🔍 Starting comprehensive student search...');

      QuerySnapshot allStudents = await _firestore
          .collection('Schools/$schoolName/Classes/$studentClass/Student_Details')
          .get();

      print('📊 Found ${allStudents.docs.length} students in class');

      // Prepare search terms
      List<String> searchTerms = [studentName!.toUpperCase()];
      if (firstName != null && lastName != null) {
        searchTerms.addAll([
          '$firstName $lastName'.toUpperCase(),
          '$lastName $firstName'.toUpperCase(),
          firstName!.toUpperCase(),
          lastName!.toUpperCase(),
        ]);
      }

      for (var studentDoc in allStudents.docs) {
        String docId = studentDoc.id;
        print('🔍 Checking student: $docId');

        try {
          DocumentSnapshot personalInfo = await studentDoc.reference
              .collection('Personal_Information')
              .doc('Registered_Information')
              .get();

          if (personalInfo.exists) {
            var data = personalInfo.data() as Map<String, dynamic>;

            // Get names from the data
            String? dbFirstName = data['firstName']?.toString().toUpperCase();
            String? dbLastName = data['lastName']?.toString().toUpperCase();
            String? dbFullName = data['studentName']?.toString().toUpperCase();
            String docIdUpper = docId.toUpperCase();

            print('   👤 Comparing with - First: $dbFirstName, Last: $dbLastName, Full: $dbFullName, DocID: $docIdUpper');

            // Check if any search term matches
            for (String searchTerm in searchTerms) {
              bool isMatch = false;

              // Check various matching scenarios
              if (dbFirstName != null && dbLastName != null) {
                String dbFullNameCombined = '$dbFirstName $dbLastName';
                if (dbFullNameCombined == searchTerm ||
                    '$dbLastName $dbFirstName' == searchTerm) {
                  isMatch = true;
                }
              }

              if (!isMatch && dbFullName != null && dbFullName.contains(searchTerm)) {
                isMatch = true;
              }

              if (!isMatch && docIdUpper.contains(searchTerm)) {
                isMatch = true;
              }

              if (isMatch) {
                print('   ✅ MATCH FOUND for search term: $searchTerm');

                // Save the successful path info for debugging
                _actualPath = 'Schools/$schoolName/Classes/$studentClass/Student_Details/$docId/Personal_Information/Registered_Information';

                // Update ParentDataManager with the correct information
                ParentDataManager().setParentData(
                  schoolName: schoolName!,
                  studentName: docId, // Use the actual document ID
                  studentClass: studentClass!,
                  firstName: dbFirstName?.toLowerCase().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' '),
                  lastName: dbLastName?.toLowerCase().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' '),
                  studentDetails: data,
                );
                await ParentDataManager().saveToPreferences();

                return data;
              }
            }
          }
        } catch (e) {
          print('   ❌ Error checking student $docId: $e');
          continue;
        }
      }

      print('❌ No matching student found in comprehensive search');
      return null;

    } catch (e) {
      print('❌ Error in comprehensive search: $e');
      return null;
    }
  }

  // Debug method to check what data exists using ParentDataManager data
  Future<void> _debugAvailableData() async {
    try {
      print('=== DEBUGGING AVAILABLE DATA ===');

      if (schoolName == null || schoolName!.isEmpty) {
        print('❌ No school name available from ParentDataManager');
        return;
      }

      // Check if school exists
      final DocumentSnapshot schoolDoc = await _firestore
          .doc('Schools/$schoolName')
          .get();

      if (!schoolDoc.exists) {
        print('❌ School not found: $schoolName');

        // List available schools
        final QuerySnapshot schoolsSnapshot = await _firestore
            .collection('Schools')
            .get();

        if (schoolsSnapshot.docs.isNotEmpty) {
          print('Available schools:');
          for (var doc in schoolsSnapshot.docs) {
            print('  - ${doc.id}');
          }
        }
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
        final String targetName = studentName!.toLowerCase().trim();
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

// Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      // Updated format order - put dd-MM-yyyy first since that's your data format
      final List<String> formats = ['dd-MM-yyyy', 'yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy'];

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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoadingStudent
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : _hasError
          ? _buildErrorWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentPersonalInfoCard(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Student Details',
        style: const TextStyle(
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

      ],
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

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentPersonalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Registration Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Text(
                      schoolName ?? 'Unknown School',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (studentPersonalInfo != null) ...[
            _buildInfoRow('First Name', studentPersonalInfo!['firstName'] ?? firstName ?? 'N/A', Icons.person_outline),
            _buildInfoRow('Last Name', studentPersonalInfo!['lastName'] ?? lastName ?? 'N/A', Icons.person_outline),
            _buildInfoRow('Student ID', studentPersonalInfo!['studentID'] ?? 'N/A', Icons.numbers),
            _buildInfoRow('Class', studentPersonalInfo!['studentClass'] ?? studentClass ?? 'N/A', Icons.school),
            _buildInfoRow('Gender', studentPersonalInfo!['studentGender'] ?? 'N/A', Icons.wc),
            _buildInfoRow('Date of Birth', _formatDate(studentPersonalInfo!['studentDOB']), Icons.cake),
            _buildInfoRow('Age', _formatAge(studentPersonalInfo!['studentAge']), Icons.timeline),
            if (studentPersonalInfo!['timestamp'] != null)
              _buildInfoRow('Registered', _formatTimestamp(studentPersonalInfo!['timestamp']), Icons.access_time),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No student registration information available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}