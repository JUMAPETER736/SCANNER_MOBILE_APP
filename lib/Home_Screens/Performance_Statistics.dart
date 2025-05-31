import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../School_Report/Juniors_Class_Performance.dart';
import '../School_Report/Seniors_Class_Performance.dart';

class Performance_Statistics extends StatefulWidget {
  const Performance_Statistics({Key? key}) : super(key: key);

  @override
  _Performance_StatisticsState createState() => _Performance_StatisticsState();
}

class _Performance_StatisticsState extends State<Performance_Statistics> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? schoolName;
  List<String> teacherClasses = [];
  String? selectedClass;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  Future<void> loadTeacherData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in.");

      final teacherDoc = await _firestore.collection('Teachers_Details').doc(currentUser.email).get();
      if (!teacherDoc.exists) throw Exception("Teacher record not found.");

      final school = (teacherDoc['school'] ?? '').toString().trim();
      final classes = teacherDoc['classes'] as List?;

      if (school.isEmpty || classes == null || classes.isEmpty) {
        throw Exception("Missing school or class information.");
      }

      setState(() {
        schoolName = school;
        teacherClasses = classes.map((c) => c.toString().trim()).toList();
        selectedClass = teacherClasses.first; // Set first class as default
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String extractFormLevel(String className) {
    final upper = className.toUpperCase();
    if (upper.contains('FORM 1') || upper.contains('FORM1') || upper.startsWith('1')) return 'FORM 1';
    if (upper.contains('FORM 2') || upper.contains('FORM2') || upper.startsWith('2')) return 'FORM 2';
    if (upper.contains('FORM 3') || upper.contains('FORM3') || upper.startsWith('3')) return 'FORM 3';
    if (upper.contains('FORM 4') || upper.contains('FORM4') || upper.startsWith('4')) return 'FORM 4';
    return 'UNKNOWN';
  }

  void navigateToPerformancePage(String className) {
    if (schoolName == null) return;

    final formLevel = extractFormLevel(className);
    Widget destinationPage;

    if (formLevel == 'FORM 1' || formLevel == 'FORM 2') {
      destinationPage = Juniors_Class_Performance(
        schoolName: schoolName!,
        className: className,
      );
    } else if (formLevel == 'FORM 3' || formLevel == 'FORM 4') {
      destinationPage = Seniors_Class_Performance(
        schoolName: schoolName!,
        className: className,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unrecognized class level: $className')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  Widget buildHorizontalClassSelector() {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: teacherClasses.length,
        itemBuilder: (context, index) {
          String className = teacherClasses[index];
          bool isSelected = className == selectedClass;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedClass = className;
              });
              // Auto-navigate when class is selected
              navigateToPerformancePage(className);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [Colors.redAccent, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.redAccent.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: isSelected ? 2 : 1,
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  className,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading performance data...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Performance Statistics'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RESULT STATISTICS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      schoolName ?? 'School Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom class selector
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: buildHorizontalClassSelector(),
            ),
          ],
        ),
      ),
    );
  }
}