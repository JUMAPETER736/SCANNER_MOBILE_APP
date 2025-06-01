import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<String> subjects = [];
  Map<String, dynamic> subjectPerformance = {};
  Map<String, dynamic> classPerformance = {
    'totalStudents': 0,
    'classPassRate': 0,
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
      await _saveClassPerformanceData();

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
          'passRate': 0,
          'totalPass': 0,
          'totalFail': 0,
        };
      }

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

          if (tempSubjectPerformance.containsKey(subjectName)) {
            tempSubjectPerformance[subjectName]['totalStudents']++;

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

          if (hasGradeNine || bestSixTotal >= 54) {
            totalClassFail++;
          }
        }
      }

      tempSubjectPerformance.forEach((subject, data) {
        if (data['totalStudents'] > 0) {
          data['passRate'] = (data['totalPass'] / data['totalStudents'] * 100).round();
        }
      });

      setState(() {
        subjectPerformance = tempSubjectPerformance;
        classPerformance = {
          'totalStudents': studentsSnapshot.docs.length,
          'classPassRate': studentsSnapshot.docs.length > 0
              ? ((studentsSnapshot.docs.length - totalClassFail) / studentsSnapshot.docs.length * 100).round()
              : 0,
          'totalClassFail': totalClassFail,
        };
      });
    } catch (e) {
      print("Error calculating performance metrics: $e");
      throw Exception("Failed to calculate performance metrics: $e");
    }
  }

  Future<void> _saveClassPerformanceData() async {
    try {
      final String basePath = 'Schools/${widget.schoolName}/Classes/${widget.className}';

      // Save Class Summary
      await _firestore.doc('$basePath/Class_Performance/Class_Summary').set({
        'Total_Students': classPerformance['totalStudents'],
        'Class_Pass_Rate': classPerformance['classPassRate'],
        'Total_Class_Passed': classPerformance['totalStudents'] - classPerformance['totalClassFail'],
        'Total_Class_Failed': classPerformance['totalClassFail'],
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userEmail,
      }, SetOptions(merge: true));

      // Save Subject Performance - Fixed to save each subject separately
      for (String subject in subjects) {
        final subjectData = subjectPerformance[subject];
        if (subjectData != null) {
          await _firestore.doc('$basePath/Class_Performance/Subject_Performance/Subject_Perfomance/$subject').set({
            'Total_Students': subjectData['totalStudents'],
            'Total_Pass': subjectData['totalPass'],
            'Total_Fail': subjectData['totalFail'],
            'Pass_Rate': subjectData['passRate'],
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedBy': userEmail,
          }, SetOptions(merge: true));
        }
      }

    } catch (e) {
      print("Error saving class performance data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving performance data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.schoolName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'RESULTS STATISTICS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CLASS: ${widget.className}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSummary() {
    final totalPassed = classPerformance['totalStudents'] - classPerformance['totalClassFail'];

    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: Colors.green[700], size: 24),
                    SizedBox(width: 8),
                    Text(
                      'CLASS SUMMARY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Students',
                        classPerformance['totalStudents'].toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Class Pass Rate',
                        '${classPerformance['classPassRate']}%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Passed',
                        totalPassed.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Failed',
                        classPerformance['totalClassFail'].toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceTable() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject, color: Colors.blue[700], size: 24),
                    SizedBox(width: 8),
                    Text(
                      'SUBJECT PERFORMANCE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Subject',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Pass',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Fail',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Pass %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Data Rows
                      ...subjects.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subject = entry.value;
                        final performance = subjectPerformance[subject] ?? {
                          'totalStudents': 0,
                          'passRate': 0,
                          'totalPass': 0,
                          'totalFail': 0,
                        };

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  performance['totalStudents'].toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      performance['totalPass'].toString(),
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      performance['totalFail'].toString(),
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${performance['passRate']}%',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'END OF TERM PERFORMANCE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),

              ),
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _fetchClassData();
              },
              tooltip: 'Refresh Performance Data',
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            SizedBox(height: 16),
            Text(
              'Loading performance data...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchClassData();
              },
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchClassData,
        color: Colors.blue[600],
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 8),
              _buildClassSummary(),
              _buildSubjectPerformanceTable(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}