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
  List<String> teacherClasses = [];
  String selectedClass = '';
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
    selectedClass = widget.className;
    _fetchTeacherClasses();
  }

  Future<void> _fetchTeacherClasses() async {
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
      if (!userDoc.exists || userDoc['school'] != widget.schoolName) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'You do not have access to this school.';
        });
        return;
      }

      List<String> classes = List<String>.from(userDoc['classes'] ?? []);
      setState(() {
        teacherClasses = classes;
      });

      await _fetchClassData();
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data: $e';
      });
    }
  }

  Future<void> _onClassSelected(String className) async {
    if (className != selectedClass) {
      setState(() {
        selectedClass = className;
        isLoading = true;
        subjects = [];
        subjectPerformance = {};
        classPerformance = {
          'totalStudents': 0,
          'classPassRate': 0,
        };
      });
      await _fetchClassData();
    }
  }

  Future<void> _fetchClassData() async {
    try {
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
          .doc(selectedClass)
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
          .doc(selectedClass)
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
          .doc(selectedClass)
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
          .doc(selectedClass)
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
            .doc(selectedClass)
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
      final String basePath = 'Schools/${widget.schoolName}/Classes/$selectedClass';

      // Save Class Summary
      await _firestore.doc('$basePath/Class_Performance/Class_Summary').set({
        'Total_Students': classPerformance['totalStudents'],
        'Class_Pass_Rate': classPerformance['classPassRate'],
        'Total_Class_Passed': classPerformance['totalStudents'] - classPerformance['totalClassFail'],
        'Total_Class_Failed': classPerformance['totalClassFail'],
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userEmail,
      }, SetOptions(merge: true));

      // Save Subject Performance
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Class performance data saved successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error saving class performance data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error saving performance data: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.blue[600]!, Colors.cyan[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  widget.schoolName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'RESULTS STATISTICS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Select Class',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teacherClasses.length,
              itemBuilder: (context, index) {
                final className = teacherClasses[index];
                final isSelected = className == selectedClass;

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Material(
                    elevation: isSelected ? 8 : 3,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _onClassSelected(className),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [Colors.indigo[600]!, Colors.blue[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.white, Colors.grey[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            className,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.analytics, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'CLASS SUMMARY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Students',
                        classPerformance['totalStudents'].toString(),
                        Icons.people_rounded,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Pass Rate',
                        '${classPerformance['classPassRate']}%',
                        Icons.trending_up_rounded,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Passed',
                        totalPassed.toString(),
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Failed',
                        classPerformance['totalClassFail'].toString(),
                        Icons.cancel_rounded,
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

  Widget _buildSummaryCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color[600], size: 28),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.indigo[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.subject_rounded, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'SUBJECT PERFORMANCE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
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
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? Colors.white : Colors.grey[25],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.8,
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
                                    fontWeight: FontWeight.w600,
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      performance['totalPass'].toString(),
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
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
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      performance['totalFail'].toString(),
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontWeight: FontWeight.bold,
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
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${performance['passRate']}%',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
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
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      'PERFORMANCE ANALYTICS',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        letterSpacing: 0.5,
      ),
    ),
    elevation: 0,
    backgroundColor: Colors.indigo[600],
    foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _fetchClassData();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              strokeWidth: 6,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Performance Data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
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
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red[400],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage ?? 'An unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchClassData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            _buildClassSelector(),
            _buildClassSummary(),
            _buildSubjectPerformanceTable(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}