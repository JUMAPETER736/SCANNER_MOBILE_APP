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

      // Create/Update Firestore statistics
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
      // Get students from the Student_Details subcollection
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

      // Get the first student's document ID (student name)
      final studentName = studentsSnapshot.docs.first.id;

      // Get subjects from the first student's Student_Subjects subcollection
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

      print("Fetched subjects: $subjects");
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

      print("Total students found: ${studentsSnapshot.docs.length}");
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
          'gradeDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0},
          'totalStudents': 0,
          'averageScore': 0,
          'passRate': 0,
          'totalScore': 0,
          'totalPass': 0,
          'totalFail': 0,
        };
      }

      Map<String, int> tempGradeDistribution = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0};
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

          // Skip if Subject_Grade is missing
          if (!subjectDoc.data().containsKey('Subject_Grade')) {
            print("Skipping ${subjectDoc.id} — Subject_Grade is missing");
            continue;
          }

          final subjectGradeRaw = subjectDoc['Subject_Grade'];

          // Skip if Subject_Grade is "N/A" or null
          if (subjectGradeRaw == "N/A" || subjectGradeRaw == null) {
            print("Skipping ${subjectDoc.id} — Subject_Grade is N/A or null");
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
            final grade = _seniorsGrade(score);
            tempSubjectPerformance[subjectName]['gradeDistribution'][grade]++;
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
            final grade = _seniorsGrade(percentage);

            tempGradeDistribution[grade] = (tempGradeDistribution[grade] ?? 0) + 1;
            if (percentage >= 50) {
              totalPassed++;
            }
          } else {
            if (validSubjectCount > 0) {
              final percentage = (studentTotalMarks / (validSubjectCount * 100) * 100).round();
              final grade = _seniorsGrade(percentage);

              tempGradeDistribution[grade] = (tempGradeDistribution[grade] ?? 0) + 1;
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
          'gradeDistribution': tempGradeDistribution,
          'passRate': studentsSnapshot.docs.length > 0
              ? (totalPassed / studentsSnapshot.docs.length * 100).round()
              : 0,
          'averageAggregate': studentsSnapshot.docs.length > 0
              ? (totalAggregate / studentsSnapshot.docs.length).round()
              : 0,
          'totalClassFail': totalClassFail,
        };
      });

      print("Performance metrics calculated successfully");
      print("Subject performance keys: ${subjectPerformance.keys}");
    } catch (e) {
      print("Error calculating performance metrics: $e");
      throw Exception("Failed to calculate performance metrics: $e");
    }
  }



  Future<void> _createOrUpdateClassStatistics() async {
    try {
      final String basePath = 'Schools/${widget.schoolName}/Classes/${widget.className}/Student_Details/Class_Results_Statistics';

      // Create/Update subject statistics
      for (String subject in subjects) {
        final subjectData = subjectPerformance[subject];
        if (subjectData != null) {
          await _firestore.doc('$basePath/$subject').set({
            'Total_Students': subjectData['totalStudents'],
            'Total_Pass': subjectData['totalPass'],
            'Total_Fail': subjectData['totalFail'],
            'Pass_Rate': subjectData['passRate'],
            'Average_Score': subjectData['averageScore'],
            'Grade_Distribution': subjectData['gradeDistribution'],
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedBy': userEmail,
          }, SetOptions(merge: true));
        }
      }

      // Create/Update overall class pass rate statistics
      await _firestore.doc('$basePath/Class_Pass_Rate').set({
        'Total_Class_Students': classPerformance['totalStudents'],
        'Total_Class_Pass': classPerformance['totalStudents'] - classPerformance['totalClassFail'],
        'Total_Class_Fail': classPerformance['totalClassFail'],
        'Class_Pass_Rate': classPerformance['totalStudents'] > 0
            ? ((classPerformance['totalStudents'] - classPerformance['totalClassFail']) / classPerformance['totalStudents'] * 100).round()
            : 0,
        'Average_Aggregate_Points': classPerformance['averageAggregate'],
        'Grade_Distribution': classPerformance['gradeDistribution'],
        'Criteria': 'Students with Best_Six_Total_Points >= 54 or any Grade_Point = 9 are considered failed',
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userEmail,
      }, SetOptions(merge: true));

      print("Class statistics successfully created/updated in Firestore");

      // Show success message
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
            _buildSummaryRow('Overall Pass Rate:', '${classPerformance['passRate']}%'),
            _buildSummaryRow('Class Pass Rate (MSCE Criteria):',
                '${classPerformance['totalStudents'] > 0 ? ((classPerformance['totalStudents'] - classPerformance['totalClassFail']) / classPerformance['totalStudents'] * 100).round() : 0}%'),
            _buildSummaryRow('Students Failed (MSCE):', classPerformance['totalClassFail'].toString()),
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