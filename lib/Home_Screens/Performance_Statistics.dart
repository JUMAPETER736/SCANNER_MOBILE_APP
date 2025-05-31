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
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User is not logged in.");
      }

      final teacherSnapshot = await _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email)
          .get();

      if (!teacherSnapshot.exists) {
        throw Exception("Teacher record not found.");
      }

      final data = teacherSnapshot.data()!;
      final String schoolName = (data['school'] ?? '').toString().trim();
      final List<dynamic>? classList = data['classes'];
      final String className = (classList != null && classList.isNotEmpty)
          ? classList[0].toString().trim()
          : '';

      if (schoolName.isEmpty || className.isEmpty) {
        throw Exception("School or class information is missing.");
      }

      final String formLevel = _getFormLevel(className);

      late Widget targetPage;

      switch (formLevel) {
        case 'FORM 1':
        case 'FORM 2':
          targetPage = Juniors_Class_Performance(
            schoolName: schoolName,
            className: className,
          );
          break;
        case 'FORM 3':
        case 'FORM 4':
          targetPage = Seniors_Class_Performance(
            schoolName: schoolName,
            className: className,
          );
          break;
        default:
          throw Exception("Unrecognized class level: $className");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _checkAndNavigate();
              },
            ),
          ),
        );
      }
    }
  }

  String _getFormLevel(String className) {
    final name = className.toUpperCase();
    if (name.contains('FORM 1') || name.contains('FORM1') || name.startsWith('1')) return 'FORM 1';
    if (name.contains('FORM 2') || name.contains('FORM2') || name.startsWith('2')) return 'FORM 2';
    if (name.contains('FORM 3') || name.contains('FORM3') || name.startsWith('3')) return 'FORM 3';
    if (name.contains('FORM 4') || name.contains('FORM4') || name.startsWith('4')) return 'FORM 4';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 20),
              Text(
                'Performance data loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ] else ...[
              Icon(Icons.error, color: Colors.red, size: 40),
              SizedBox(height: 20),
              Text(
                'Failed to load data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _checkAndNavigate();
                },
                child: Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}