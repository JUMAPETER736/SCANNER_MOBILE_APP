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
    'gradeDistribution': {
      '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0
    },
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
      // Verify teacher access
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

      // Fetch all data
      await _fetchSubjects();
      await _fetchStudentData();
      await _calculatePerformanceMetrics();

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
      // Get subjects from any student's record (assuming all students take same subjects)
      final studentsSnapshot = await _firestore
          .collection('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details')
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        throw Exception('No students found in this class');
      }

      final studentId = studentsSnapshot.docs.first.id;
      final subjectsSnapshot = await _firestore
          .collection('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details/$studentId/Student_Subjects')
          .get();

      setState(() {
        subjects = subjectsSnapshot.docs.map((doc) => doc['Subject_Name'] as String).toList();
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      throw Exception("Failed to fetch subjects");
    }
  }

  Future<void> _fetchStudentData() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details')
          .get();

      setState(() {
        classPerformance['totalStudents'] = studentsSnapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching student data: $e");
      throw Exception("Failed to fetch student data");
    }
  }

  Future<void> _calculatePerformanceMetrics() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details')
          .get();

      // Initialize subject performance tracking
      Map<String, dynamic> tempSubjectPerformance = {};
      for (String subject in subjects) {
        tempSubjectPerformance[subject] = {
          'gradeDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0},
          'totalStudents': 0,
          'averageScore': 0,
          'passRate': 0,
          'totalScore': 0,
        };
      }

      // Initialize class performance tracking
      Map<String, int> tempGradeDistribution = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0};
      int totalPassed = 0;
      int totalAggregate = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        // Process subject grades
        final subjectsSnapshot = await _firestore
            .collection('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details/${studentDoc.id}/Student_Subjects')
            .get();

        List<int> points = [];
        for (var subjectDoc in subjectsSnapshot.docs) {
          final subjectName = subjectDoc['Subject_Name'] as String;
          final score = (subjectDoc['Subject_Grade'] as num?)?.toInt() ?? 0;
          final grade = _seniorsGrade(score);

          // Update subject performance
          if (tempSubjectPerformance.containsKey(subjectName)) {
            tempSubjectPerformance[subjectName]['gradeDistribution'][grade]++;
            tempSubjectPerformance[subjectName]['totalStudents']++;
            tempSubjectPerformance[subjectName]['totalScore'] += score;

            if (score >= 50) {
              tempSubjectPerformance[subjectName]['passRate']++;
            }
          }

          points.add(int.tryParse(_getPoints(grade)) ?? 9);
        }

        // Calculate aggregate (best 6 subjects)
        points.sort();
        int aggregate = points.take(6).reduce((a, b) => a + b);
        totalAggregate += aggregate;

        // Process overall performance from TOTAL_MARKS
        final totalMarksDoc = await _firestore
            .doc('Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details/${studentDoc.id}/TOTAL_MARKS/Marks')
            .get();

        if (totalMarksDoc.exists) {
          final studentTotal = (totalMarksDoc['Student_Total_Marks'] as num?)?.toInt() ?? 0;
          final teacherTotal = (totalMarksDoc['Teacher_Total_Marks'] as num?)?.toInt() ?? (subjects.length * 100);
          final percentage = (studentTotal / teacherTotal * 100).round();
          final grade = _seniorsGrade(percentage);

          tempGradeDistribution[grade] = (tempGradeDistribution[grade] ?? 0) + 1;
          if (percentage >= 50) {
            totalPassed++;
          }
        }
      }

      // Calculate averages and pass rates for subjects
      tempSubjectPerformance.forEach((subject, data) {
        if (data['totalStudents'] > 0) {
          data['averageScore'] = (data['totalScore'] / data['totalStudents']).round();
          data['passRate'] = (data['passRate'] / data['totalStudents'] * 100).round();
        }
      });

      // Update class performance
      setState(() {
        subjectPerformance = tempSubjectPerformance;
        classPerformance = {
          'totalStudents': studentsSnapshot.docs.length,
          'gradeDistribution': tempGradeDistribution,
          'passRate': studentsSnapshot.docs.length > 0
              ? (totalPassed / studentsSnapshot.docs.length * 100).round()
              : 0,
          'averageAggregate': studentsSnapshot.docs.length > 0
              ? (totalAggregate / studentsSnapshot.docs.length).round()
              : 0,
        };
      });
    } catch (e) {
      print("Error calculating performance metrics: $e");
      throw Exception("Failed to calculate performance metrics");
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

  String _getGradeDescription(String grade) {
    switch (grade) {
      case '1': return 'Distinction (90-100)';
      case '2': return 'Distinction (80-89)';
      case '3': return 'Strong Credit (75-79)';
      case '4': return 'Strong Credit (70-74)';
      case '5': return 'Credit (65-69)';
      case '6': return 'Weak Credit (60-64)';
      case '7': return 'Pass (55-59)';
      case '8': return 'Weak Pass (50-54)';
      case '9': return 'Fail (0-49)';
      default: return 'Unknown';
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
            _buildSummaryRow('Pass Rate:', '${classPerformance['passRate']}%'),
            _buildSummaryRow('Average Aggregate:', classPerformance['averageAggregate'].toString()),
            SizedBox(height: 8),
            Text(
              'Grade Distribution:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((grade) {
              return _buildSummaryRow(
                _getGradeDescription(grade),
                (classPerformance['gradeDistribution'][grade] ?? 0).toString(),
              );
            }).toList(),
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
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGradeDistributionChart() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRADE DISTRIBUTION',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: ['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((grade) {
                    int count = classPerformance['gradeDistribution'][grade] ?? 0;
                    double heightFactor = classPerformance['totalStudents'] > 0
                        ? count / classPerformance['totalStudents'] * 150
                        : 0;
                    return Container(
                      width: 30,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: heightFactor,
                            color: grade == '1' || grade == '2' ? Colors.green :
                            grade == '3' || grade == '4' ? Colors.lightGreen :
                            grade == '5' || grade == '6' ? Colors.blue :
                            grade == '7' || grade == '8' ? Colors.orange :
                            Colors.red,
                            alignment: Alignment.center,
                            child: Text(
                              count.toString(),
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(grade, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem(Colors.green, 'Distinction (1-2)'),
              _buildLegendItem(Colors.lightGreen, 'Strong Credit (3-4)'),
              _buildLegendItem(Colors.blue, 'Credit (5-6)'),
              _buildLegendItem(Colors.orange, 'Pass (7-8)'),
              _buildLegendItem(Colors.red, 'Fail (9)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10)),
      ],
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
                    'Avg',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Pass %',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((grade) {
                  return DataColumn(
                    label: Text(
                      grade,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ],
              rows: subjects.map((subject) {
                final performance = subjectPerformance[subject] ?? {
                  'gradeDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0},
                  'averageScore': 0,
                  'passRate': 0,
                };
                return DataRow(
                  cells: [
                    DataCell(Text(subject)),
                    DataCell(Text(performance['averageScore'].toString())),
                    DataCell(Text('${performance['passRate']}%')),
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((grade) {
                      return DataCell(Text(performance['gradeDistribution'][grade].toString()));
                    }).toList(),
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
              _buildGradeDistributionChart(),
              _buildSubjectPerformanceTable(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}