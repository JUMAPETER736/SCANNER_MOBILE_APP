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

      late Widget targetPage;

      if (className == 'FORM 1' || className == 'FORM 2') {
        targetPage = Juniors_Class_Performance(
          schoolName: schoolName,
          className: className,
        );
      } else if (className == 'FORM 3' || className == 'FORM 4') {
        targetPage = Seniors_Class_Performance(
          schoolName: schoolName,
          className: className,
        );
      } else {
        throw Exception("Unrecognized class name: $className");
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
