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

  @override
  void initState() {
    super.initState();
    checkAndNavigate();
  }

  Future<void> checkAndNavigate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in.");

      final teacherDoc = await _firestore.collection('Teachers_Details').doc(currentUser.email).get();
      if (!teacherDoc.exists) throw Exception("Teacher record not found.");

      final schoolName = (teacherDoc['school'] ?? '').toString().trim();
      final classes = teacherDoc['classes'] as List?;
      final className = (classes != null && classes.isNotEmpty) ? classes[0].toString().trim() : '';

      if (schoolName.isEmpty || className.isEmpty) {
        throw Exception("Missing school or class info.");
      }

      final formLevel = extractFormLevel(className);

      Widget destinationPage;
      if (formLevel == 'FORM 1' || formLevel == 'FORM 2') {

        destinationPage = Seniors_Class_Performance(
            schoolName: schoolName, className: className);

      } else if (formLevel == 'FORM 3' || formLevel == 'FORM 4') {

        destinationPage = Seniors_Class_Performance(
            schoolName: schoolName, className: className);

      } else {
        throw Exception("Unrecognized class level.");
      }

      // Navigate immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking performance data...'),
          ],
        ),
      ),
    );
  }
}
