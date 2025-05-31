import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../School_Report/Juniors_Class_Performance.dart';
import '../School_Report/Seniors_Class_Performance.dart';

class Performance_Statistics extends StatefulWidget {
  const Performance_Statistics({Key? key}) : super(key: key);

  @override
  State<Performance_Statistics> createState() => _Performance_StatisticsState();
}

class _Performance_StatisticsState extends State<Performance_Statistics> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Execute after first frame to avoid delays during build
    Future.microtask(_checkAndNavigate);
  }

  Future<void> _checkAndNavigate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User is not logged in.");
      }

      final doc = await _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email)
          .get();

      final data = doc.data();
      if (data == null) throw Exception("Teacher record not found.");

      final schoolName = data['school'] ?? '';
      final classList = data['classes'] as List<dynamic>?;

      if (schoolName == '' || classList == null || classList.isEmpty) {
        throw Exception("School or class information is missing.");
      }

      final className = classList.first.toString().toUpperCase();
      final formLevel = _getFormLevel(className);

      late Widget targetPage;

      if (formLevel == 'FORM 1' || formLevel == 'FORM 2') {
        targetPage = Juniors_Class_Performance(
          schoolName: schoolName,
          className: className,
        );
      } else if (formLevel == 'FORM 3' || formLevel == 'FORM 4') {
        targetPage = Seniors_Class_Performance(
          schoolName: schoolName,
          className: className,
        );
      } else {
        throw Exception("Unrecognized class level: $className");
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              setState(() => _isLoading = true);
              _checkAndNavigate();
            },
          ),
        ),
      );
    }
  }

  String _getFormLevel(String className) {
    if (className.contains('FORM 1') || className.contains('FORM1') || className.startsWith('1')) return 'FORM 1';
    if (className.contains('FORM 2') || className.contains('FORM2') || className.startsWith('2')) return 'FORM 2';
    if (className.contains('FORM 3') || className.contains('FORM3') || className.startsWith('3')) return 'FORM 3';
    if (className.contains('FORM 4') || className.contains('FORM4') || className.startsWith('4')) return 'FORM 4';
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Performance Statistics'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
            SizedBox(height: 20),
            Text('Loading performance data...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 20),
            const Text('Failed to load data', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _checkAndNavigate();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
