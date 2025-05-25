import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Seniors_Class_Performance extends StatefulWidget {
  final String schoolName;
  final String className;

  const Seniors_Class_Performance({
    required this.schoolName,
    required this.className,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_Class_PerformanceState createState() => _Seniors_Class_PerformanceState();
}

class _Seniors_Class_PerformanceState extends State<Seniors_Class_Performance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> subjects = [];
  Map<String, dynamic> subjectPerformance = {};
  Map<String, dynamic> classPerformance = {
    'totalStudents': 0,
    'passRate': 0.0,
    'averageAggregate': 0.0,
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
      if (!userDoc.exists || userDoc['school'] != widget.schoolName ||
          !(userDoc['classes'] as List).contains(widget.className)) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'You do not have access to this class.';
        });
        return;
      }

      await _fetchSubjects();
      await _fetchStudentData();
      await _calculatePerformanceMetrics();
      await _createOrUpdateClassStatistics();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data: $e';
      });
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Student_Details')
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        throw Exception('No students found in this class');
      }

      final studentName = studentsSnapshot.docs.first.id;
      final subjectsSnapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('Student_Subjects')
          .get();

      List<String> fetchedSubjects = [];
      for (var doc in subjectsSnapshot.docs) {
        String subjectName = doc['Subject_Name'] as String;
        fetchedSubjects.add(subjectName);
      }

      setState(() {
        subjects = fetchedSubjects;
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      throw Exception("Failed to fetch subjects: $e");
    }
  }

  Future<void> _fetchStudentData() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Student_Details')
          .get();

      setState(() {
        classPerformance['totalStudents'] = studentsSnapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching student data: $e");
      throw Exception("Failed to fetch student data: $e");
    }
  }

  Future<void> _calculatePerformanceMetrics() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Student_Details')
          .get();

      Map<String, dynamic> tempSubjectPerformance = {};
      for (String subject in subjects) {
        tempSubjectPerformance[subject] = {
          'totalStudents': 0,
          'averageScore': 0,
          'passRate': 0,
          'totalScore': 0,
          'totalPass': 0,
          'totalFail': 0,
        };
      }

      int totalPassed = 0;
      int totalAggregate = 0;
      int totalClassFail = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        String studentName = studentDoc.id;

        final subjectsSnapshot = await _firestore
            .collection('Schools')
            .doc(widget.schoolName)
            .collection('Classes')
            .doc(widget.className)
            .collection('Student_Details')
            .doc(studentName)
            .collection('Student_Subjects')
            .get();

        List<int> points = [];
        bool hasGradeNine = false;
        int studentTotalMarks = 0;
        int validSubjectCount = 0;

        for (var subjectDoc in subjectsSnapshot.docs) {
          final subjectName = subjectDoc['Subject_Name'] as String;

          if (!subjectDoc.data().containsKey('Subject_Grade')) {
            continue;
          }

          final subjectGradeRaw = subjectDoc['Subject_Grade'];
          if (subjectGradeRaw == "N/A" || subjectGradeRaw == null) {
            continue;
          }

          int score = 0;
          if (subjectGradeRaw is String) {
            score = int.tryParse(subjectGradeRaw) ?? 0;
          } else if (subjectGradeRaw is num) {
            score = subjectGradeRaw.toInt();
          }

          int currentGradePoint = int.tryParse(_getPoints(_seniorsGrade(score))) ?? 9;
          if (currentGradePoint == 9) {
            hasGradeNine = true;
          }

          studentTotalMarks += score;
          validSubjectCount++;

          if (tempSubjectPerformance.containsKey(subjectName)) {
            tempSubjectPerformance[subjectName]['totalStudents']++;
            tempSubjectPerformance[subjectName]['totalScore'] += score;

            if (score >= 50) {
              tempSubjectPerformance[subjectName]['totalPass']++;
            } else {
              tempSubjectPerformance[subjectName]['totalFail']++;
            }
          }

          points.add(currentGradePoint);
        }

        if (points.isNotEmpty) {
          points.sort();
          int bestSixTotal = points.take(6).reduce((a, b) => a + b);
          totalAggregate += bestSixTotal;

          if (hasGradeNine || bestSixTotal >= 54) {
            totalClassFail++;
          }
        }

        try {
          final totalMarksDoc = await _firestore
              .collection('Schools')
              .doc(widget.schoolName)
              .collection('Classes')
              .doc(widget.className)
              .collection('Student_Details')
              .doc(studentName)
              .collection('TOTAL_MARKS')
              .doc('Marks')
              .get();

          if (totalMarksDoc.exists) {
            final studentTotalRaw = totalMarksDoc['Student_Total_Marks'];
            final teacherTotalRaw = totalMarksDoc['Teacher_Total_Marks'];

            int studentTotal = 0;
            if (studentTotalRaw != null) {
              if (studentTotalRaw is String) {
                studentTotal = int.tryParse(studentTotalRaw) ?? 0;
              } else if (studentTotalRaw is num) {
                studentTotal = studentTotalRaw.toInt();
              }
            }

            int teacherTotal = subjects.length * 100;
            if (teacherTotalRaw != null) {
              if (teacherTotalRaw is String) {
                teacherTotal = int.tryParse(teacherTotalRaw) ?? (subjects.length * 100);
              } else if (teacherTotalRaw is num) {
                teacherTotal = teacherTotalRaw.toInt();
              }
            }

            final percentage = teacherTotal > 0 ? (studentTotal / teacherTotal * 100).round() : 0;
            if (percentage >= 50) {
              totalPassed++;
            }
          } else {
            if (validSubjectCount > 0) {
              final percentage = (studentTotalMarks / (validSubjectCount * 100) * 100).round();
              if (percentage >= 50) {
                totalPassed++;
              }
            }
          }
        } catch (e) {
          print("Error fetching TOTAL_MARKS for student $studentName: $e");
        }
      }

      tempSubjectPerformance.forEach((subject, data) {
        if (data['totalStudents'] > 0) {
          data['averageScore'] = (data['totalScore'] / data['totalStudents']).round();
          data['passRate'] = (data['totalPass'] / data['totalStudents'] * 100).round();
        }
      });

      setState(() {
        subjectPerformance = tempSubjectPerformance;
        classPerformance = {
          'totalStudents': studentsSnapshot.docs.length,
          'passRate': studentsSnapshot.docs.length > 0
              ? (totalPassed / studentsSnapshot.docs.length * 100).round()
              : 0,
          'averageAggregate': studentsSnapshot.docs.length > 0
              ? (totalAggregate / studentsSnapshot.docs.length).round()
              : 0,
          'totalClassFail': totalClassFail,
        };
      });
    } catch (e) {
      print("Error calculating performance metrics: $e");
      throw Exception("Failed to calculate performance metrics: $e");
    }
  }

  Future<void> _createOrUpdateClassStatistics() async {
    try {
      final String basePath = 'Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details/Class_Results_Statistics';

      for (String subject in subjects) {
        final subjectData = subjectPerformance[subject];
        if (subjectData != null) {
          await _firestore.doc('$basePath/$subject').set({
            'Total_Students': subjectData['totalStudents'],
            'Total_Pass': subjectData['totalPass'],
            'Total_Fail': subjectData['totalFail'],
            'Pass_Rate': subjectData['passRate'],
            'Average_Score': subjectData['averageScore'],
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedBy': userEmail,
          }, SetOptions(merge: true));
        }
      }

      await _firestore.doc('$basePath/Class_Pass_Rate').set({
        'Total_Class_Students': classPerformance['totalStudents'],
        'Total_Class_Pass': classPerformance['totalStudents'] - classPerformance['totalClassFail'],
        'Total_Class_Fail': classPerformance['totalClassFail'],
        'Class_Pass_Rate': classPerformance['totalStudents'] > 0
            ? ((classPerformance['totalStudents'] - classPerformance['totalClassFail']) / classPerformance['totalStudents'] * 100).round()
            : 0,
        'Average_Aggregate_Points': classPerformance['averageAggregate'],
        'Criteria': 'Students with Best_Six_Total_Points >= 54 or any Grade_Point = 9 are considered failed',
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userEmail,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class statistics updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error creating/updating class statistics: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _seniorsGrade(int score) {
    if (score >= 90) return '1';
    if (score >= 80) return '2';
    if (score >= 75) return '3';
    if (score >= 70) return '4';
    if (score >= 65) return '5';
    if (score >= 60) return '6';
    if (score >= 55) return '7';
    if (score >= 50) return '8';
    return '9';
  }

  String _getPoints(String grade) {
    switch (grade) {
      case '1': return '1';
      case '2': return '2';
      case '3': return '3';
      case '4': return '4';
      case '5': return '5';
      case '6': return '6';
      case '7': return '7';
      case '8': return '8';
      default: return '9';
    }
  }

  Widget _buildSchoolHeader() {
    return Column(
      children: [
        Text(
          widget.schoolName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'SENIOR CLASS PERFORMANCE STATISTICS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'CLASS: ${widget.className}',
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
            _buildSummaryRow('Total Students:', classPerformance['totalStudents'].toString()),
            _buildSummaryRow('Overall Pass Rate:', '${classPerformance['passRate']}%'),
            _buildSummaryRow('Class Pass Rate (MSCE Criteria):',
                '${classPerformance['totalStudents'] > 0 ? ((classPerformance['totalStudents'] - classPerformance['totalClassFail']) / classPerformance['totalStudents'] * 100).round() : 0}%'),
            _buildSummaryRow('Students Failed (MSCE):', classPerformance['totalClassFail'].toString()),
            _buildSummaryRow('Average Aggregate:', classPerformance['averageAggregate'].toString()),
            SizedBox(height: 8),
            Text(
              'Note: MSCE failure criteria - Students with aggregate ≥54 points or any subject grade 9',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
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
              columnSpacing: 16,
              columns: [
                DataColumn(
                  label: Text(
                    'Subject',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Pass',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Fail',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Pass %',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Avg',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: subjects.map((subject) {
                final performance = subjectPerformance[subject] ?? {
                  'totalStudents': 0,
                  'averageScore': 0,
                  'passRate': 0,
                  'totalPass': 0,
                  'totalFail': 0,
                };
                return DataRow(
                  cells: [
                    DataCell(Text(subject)),
                    DataCell(Text(performance['totalStudents'].toString())),
                    DataCell(Text(performance['totalPass'].toString())),
                    DataCell(Text(performance['totalFail'].toString())),
                    DataCell(Text('${performance['passRate']}%')),
                    DataCell(Text(performance['averageScore'].toString())),
                  ],
                );
              }).toList(),
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
        title: Text('${widget.className} Performance'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _fetchClassData();
            },
            tooltip: 'Refresh Statistics',
          ),
        ],
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
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}