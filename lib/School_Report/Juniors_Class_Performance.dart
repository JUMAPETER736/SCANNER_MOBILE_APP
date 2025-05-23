import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Juniors_Class_Performance extends StatefulWidget {
  final String schoolName;
  final String className;

  const Juniors_Class_Performance({
    required this.schoolName,
    required this.className,
    Key? key,
  }) : super(key: key);
  @override
  _Juniors_Class_PerformanceState createState() => _Juniors_Class_PerformanceState();
}

class _Juniors_Class_PerformanceState extends State<Juniors_Class_Performance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? schoolName;
  String? className;
  List<String> subjects = [];
  Map<String, dynamic> subjectPerformance = {};
  Map<String, dynamic> classPerformance = {
    'totalStudents': 0,
    'passed': 0,
    'failed': 0,
    'passRate': 0.0,
  };
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
      return;
    }

    userEmail = user.email;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

      if (!userDoc.exists) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'User details not found.';
        });
        return;
      }

      schoolName = userDoc['school'];
      className = userDoc['classes'].isNotEmpty ? userDoc['classes'][0] : null;

      if (schoolName == null || className == null) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Class before accessing reports.';
        });
        return;
      }

      await _fetchSubjects();
      await _calculateSubjectPerformance();
      await _calculateClassPerformance();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data.';
      });
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$className/Subjects')
          .get();

      setState(() {
        subjects = snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      throw Exception("Failed to fetch subjects");
    }
  }

  Future<void> _calculateSubjectPerformance() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$className/Student_Details')
          .get();

      Map<String, dynamic> performanceData = {};

      for (String subject in subjects) {
        int passed = 0;
        int failed = 0;
        double totalScore = 0;
        int studentCount = 0;

        for (var studentDoc in studentsSnapshot.docs) {
          final subjectDoc = await _firestore
              .doc('Schools/$schoolName/Classes/$className/Student_Details/${studentDoc.id}/Student_Subjects/$subject')
              .get();

          if (subjectDoc.exists) {
            final score = (subjectDoc['Subject_Grade'] as num?)?.toDouble() ?? 0;
            totalScore += score;
            studentCount++;

            if (score >= 50) {
              passed++;
            } else {
              failed++;
            }
          }
        }

        performanceData[subject] = {
          'passed': passed,
          'failed': failed,
          'totalStudents': studentCount,
          'averageScore': studentCount > 0 ? (totalScore / studentCount).round() : 0,
          'passRate': studentCount > 0 ? (passed / studentCount * 100).round() : 0,
        };
      }

      setState(() {
        subjectPerformance = performanceData;
      });
    } catch (e) {
      print("Error calculating subject performance: $e");
      throw Exception("Failed to calculate subject performance");
    }
  }

  Future<void> _calculateClassPerformance() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$className/Student_Details')
          .get();

      int totalPassed = 0;
      int totalFailed = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        final totalMarksDoc = await _firestore
            .doc('Schools/$schoolName/Classes/$className/Student_Details/${studentDoc.id}/TOTAL_MARKS/Marks')
            .get();

        if (totalMarksDoc.exists) {
          final studentTotal = (totalMarksDoc['Student_Total_Marks'] as num?)?.toInt() ?? 0;
          final teacherTotal = (totalMarksDoc['Teacher_Total_Marks'] as num?)?.toInt() ?? (subjects.length * 100);
          final percentage = (studentTotal / teacherTotal * 100);

          if (percentage >= 50) {
            totalPassed++;
          } else {
            totalFailed++;
          }
        }
      }

      setState(() {
        classPerformance = {
          'totalStudents': studentsSnapshot.docs.length,
          'passed': totalPassed,
          'failed': totalFailed,
          'passRate': studentsSnapshot.docs.length > 0
              ? (totalPassed / studentsSnapshot.docs.length * 100).round()
              : 0,
        };
      });
    } catch (e) {
      print("Error calculating class performance: $e");
      throw Exception("Failed to calculate class performance");
    }
  }

  Widget _buildSchoolHeader() {
    return Column(
      children: [
        Text(
          schoolName ?? 'UNKNOWN SECONDARY SCHOOL',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'CLASS PERFORMANCE STATISTICS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'CLASS: ${className ?? 'N/A'}',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildClassSummary() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLASS SUMMARY',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Students:'),
                Text(classPerformance['totalStudents'].toString()),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Students Passed:'),
                Text('${classPerformance['passed']} (${classPerformance['passRate']}%)'),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Students Failed:'),
                Text(classPerformance['failed'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformanceTable() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUBJECT PERFORMANCE',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Avg Score'), numeric: true),
                DataColumn(label: Text('Passed'), numeric: true),
                DataColumn(label: Text('Failed'), numeric: true),
                DataColumn(label: Text('Total'), numeric: true),
                DataColumn(label: Text('Pass Rate'), numeric: true),
              ],
              rows: subjects.map((subject) {
                final performance = subjectPerformance[subject] ?? {
                  'passed': 0,
                  'failed': 0,
                  'totalStudents': 0,
                  'averageScore': 0,
                  'passRate': 0,
                };
                return DataRow(cells: [
                  DataCell(Text(subject)),
                  DataCell(Text(performance['averageScore'].toString())),
                  DataCell(Text(performance['passed'].toString())),
                  DataCell(Text(performance['failed'].toString())),
                  DataCell(Text(performance['totalStudents'].toString())),
                  DataCell(Text('${performance['passRate']}%')),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassFailChart() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASS/FAIL DISTRIBUTION',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: classPerformance['passed'],
                  child: Container(
                    color: Colors.green,
                    alignment: Alignment.center,
                    child: Text(
                      'Passed\n${classPerformance['passed']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: classPerformance['failed'],
                  child: Container(
                    color: Colors.red,
                    alignment: Alignment.center,
                    child: Text(
                      'Failed\n${classPerformance['failed']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Juniors Class Performance'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text(errorMessage ?? 'An error occurred'))
          : RefreshIndicator(
        onRefresh: _fetchClassData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSchoolHeader(),
              _buildClassSummary(),
              _buildSubjectPerformanceTable(),
              _buildPassFailChart(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}