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

      final teacherDoc = await _firestore.collection('Teachers_Details').doc(
          currentUser.email).get();
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
    if (upper.contains('FORM 1') || upper.contains('FORM1') ||
        upper.startsWith('1')) return 'FORM 1';
    if (upper.contains('FORM 2') || upper.contains('FORM2') ||
        upper.startsWith('2')) return 'FORM 2';
    if (upper.contains('FORM 3') || upper.contains('FORM3') ||
        upper.startsWith('3')) return 'FORM 3';
    if (upper.contains('FORM 4') || upper.contains('FORM4') ||
        upper.startsWith('4')) return 'FORM 4';
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
  }


