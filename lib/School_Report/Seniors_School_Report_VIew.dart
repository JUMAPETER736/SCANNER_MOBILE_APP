import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Seniors_School_Report_PDF.dart';

class Seniors_School_Report_View extends StatefulWidget {
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Report_View({
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_School_Report_ViewState createState() => _Seniors_School_Report_ViewState();
}

class _Seniors_School_Report_ViewState extends State<Seniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  Map<String, dynamic> subjectStats = {};
  Map<String, int> subjectPositions = {};
  Map<String, int> totalStudentsPerSubject = {};
  int studentPosition = 0;
  int Total_Class_Students_Number = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;
  String? schoolPhone;
  String? schoolEmail;
  int studentTotalMarks = 0;
  int teacherTotalMarks = 0;
  int aggregatePoints = 0;
  int aggregatePosition = 0;
  String averageGradeLetter = '';
  String msceStatus = '';
  String msceMessage = '';
  int boxNumber = 0;
  String schoolLocation = 'N/A';
  String? formTeacherRemarks;
  String? headTeacherRemarks;
  String? schoolFees;
  String? schoolBankAccount;
  String? nextTermOpeningDate;

  @override
  void initState() {
    super.initState();
    _fetchStudentDataWithTimeout();
  }

  String getCurrentTerm() {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentDay = now.day;

    if ((currentMonth == 9 && currentDay >= 1) ||
        (currentMonth >= 10 && currentMonth <= 12)) {
      return 'ONE';
    } else if ((currentMonth == 1 && currentDay >= 2) ||
        (currentMonth >= 2 && currentMonth <= 3) ||
        (currentMonth == 4 && currentDay <= 20)) {
      return 'TWO';
    } else if ((currentMonth == 4 && currentDay >= 25) ||
        (currentMonth >= 5 && currentMonth <= 7)) {
      return 'THREE';
    } else {
      return 'ONE';
    }
  }

  String getAcademicYear() {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    if (currentMonth >= 9) {
      return '$currentYear/${currentYear + 1}';
    } else {
      return '${currentYear - 1}/$currentYear';
    }
  }

  Future<void> _fetchStudentDataWithTimeout() async {
    try {
      await _fetchStudentData().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Request timed out. Please check your connection.';
          });
        },
      );
    } catch (e) {
      setState(() {
<<<<<<< HEAD

=======
        isLoading = false;
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
        hasError = true;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchStudentData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'No user is currently logged in.';
        });
      }
      return;
    }

    userEmail = user.email;

    try {
      final userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
<<<<<<< HEAD

=======
            isLoading = false;
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
            hasError = true;
            errorMessage = 'User details not found.';
          });
        }
        return;
      }

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Please select a School and Classes before accessing reports.';
          });
        }
        return;
      }

      schoolName = teacherSchool;
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 3' && studentClass != 'FORM 4') {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Only students in FORM 3 or FORM 4 can access this report.';
          });
        }
        return;
      }

      final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

      await Future.wait([
        _fetchSchoolInfo(teacherSchool),
        fetchStudentSubjects(basePath),
        fetchTotalMarks(basePath),
        _updateTotalStudentsCount(teacherSchool, studentClass),
        _fetchSubjectStats(teacherSchool, studentClass),
        _fetchSeniorStudentRemarks(basePath),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'An error occurred while fetching data.';
        });
      }
    }
  }

  Future<void> _fetchSchoolInfo(String school) async {
    try {
      DocumentSnapshot schoolInfoDoc = await _firestore
          .collection('Schools')
          .doc(school)
          .collection('School_Information')
          .doc('School_Details')
          .get();

      setState(() {
        schoolPhone = schoolInfoDoc['Telephone'] ?? 'N/A';
        schoolEmail = schoolInfoDoc['Email'] ?? 'N/A';
        boxNumber = schoolInfoDoc['boxNumber'] ?? 0;
        schoolLocation = schoolInfoDoc['schoolLocation'] ?? 'N/A';
        schoolFees = schoolInfoDoc['School_Fees'] ?? 'N/A';
        schoolBankAccount = schoolInfoDoc['School_Bank_Account'] ?? 'N/A';
        nextTermOpeningDate = schoolInfoDoc['Next_Term_Opening_Date'] ?? 'N/A';
      });
    } catch (e) {
      print("Error fetching school info: $e");
      setState(() {
        schoolPhone = 'N/A';
        schoolEmail = 'N/A';
        boxNumber = 0;
        schoolLocation = 'N/A';
        schoolFees = 'N/A';
        schoolBankAccount = 'N/A';
        nextTermOpeningDate = 'N/A';
      });
    }
  }

  Future<void> _fetchSubjectStats(String school, String studentClass) async {
    try {
      final subjectStatsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Class_Performance/Subject_Performance/Subjects')
          .get();

      Map<String, dynamic> stats = {};

      for (var doc in subjectStatsSnapshot.docs) {
        final data = doc.data();
        final subjectName = data['Subject_Name'] ?? doc.id;

        stats[subjectName] = {
          'average': (data['Subject_Average'] as num?)?.toDouble() ?? 0.0,
          'totalStudents': (data['Total_Students'] as num?)?.toInt() ?? 0,
          'totalPass': (data['Total_Pass'] as num?)?.toInt() ?? 0,
          'totalFail': (data['Total_Fail'] as num?)?.toInt() ?? 0,
          'passRate': (data['Pass_Rate'] as num?)?.toDouble() ?? 0.0,
        };
      }

      if (stats.isEmpty) {
        final oldStatsDoc = await _firestore
            .doc('Schools/$school/Classes/$studentClass/Class_Statistics/subject_averages')
            .get();

        if (oldStatsDoc.exists) {
          final data = oldStatsDoc.data() as Map<String, dynamic>;
          for (var entry in data.entries) {
            if (entry.value is Map<String, dynamic>) {
              stats[entry.key] = {
                'average': (entry.value['average'] as num?)?.toDouble() ?? 0.0,
                'totalStudents': (entry.value['totalStudents'] as num?)?.toInt() ?? 0,
                'totalPass': (entry.value['totalPass'] as num?)?.toInt() ?? 0,
                'totalFail': (entry.value['totalFail'] as num?)?.toInt() ?? 0,
                'passRate': (entry.value['passRate'] as num?)?.toDouble() ?? 0.0,
              };
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          subjectStats = stats;
        });
      }
    } catch (e) {
      print("Error fetching subject statistics: $e");
    }
  }

  Future<void> _updateTotalStudentsCount(String school, String studentClass) async {
    try {
      final classInfoDoc = await _firestore
          .collection('Schools')
          .doc(school)
          .collection('Classes')
          .doc(studentClass)
          .collection('Class_Info')
          .doc('Info')
          .get();

      if (classInfoDoc.exists) {
        final classData = classInfoDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            Total_Class_Students_Number = classData['totalStudents'] ?? 0;
          });
        }
      } else {
        final studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(school)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .get();

        Total_Class_Students_Number = studentsSnapshot.docs.length;

        await _firestore
            .collection('Schools')
            .doc(school)
            .collection('Classes')
            .doc(studentClass)
            .collection('Class_Info')
            .doc('Info')
            .set({
          'totalStudents': Total_Class_Students_Number,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            // UI will update with correct count
          });
        }
      }
    } catch (e) {
      print('Error updating total students count: $e');
    }
  }

  Future<void> fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get(GetOptions(source: Source.serverAndCache));

      List<Map<String, dynamic>> subjectList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        int score = 0;
        bool hasGrade = true;

        if (data['Subject_Grade'] == 'N/A' || data['Subject_Grade'] == null) {
          hasGrade = false;
        } else {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }

        int subjectPosition = (data['Subject_Position'] as num?)?.toInt() ?? 0;
        int totalStudentsInSubject = (data['Total_Students_Subject'] as num?)?.toInt() ?? 0;
        String gradeLetter = hasGrade ? Seniors_Grade(score) : '';

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': hasGrade ? score : null,
          'position': subjectPosition,
          'totalStudents': totalStudentsInSubject,
          'gradeLetter': gradeLetter,
          'hasGrade': hasGrade,
        });
      }

      setState(() {
        subjects = subjectList;
      });
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  Future<void> fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Marks')
          .get(GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        int safeParse(dynamic value) {
          if (value == null) return 0;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
          return 0;
        }

        setState(() {
          totalMarks = data;
          studentTotalMarks = safeParse(data['preterTotal_Marks']);
          teacherTotalMarks = safeParse(data['Teacher_Total_Marks']) == 0
              ? (subjects.where((s) => s['hasGrade'] == true).length * 100)
              : safeParse(data['Teacher_Total_Marks']);
          studentPosition = safeParse(data['Student_Class_Position']);
          aggregatePoints = safeParse(data['Best_Six_Total_Points']);
          aggregatePosition = safeParse(data['Aggregate_Position']);
          if (data['Total_Class_Students_Number'] != null) {
            Total_Class_Students_Number = safeParse(data['Total_Class_Students_Number']);
          }
          averageGradeLetter = data['Average_Grade_Letter']?.toString() ?? '';
          msceStatus = data['MSCE_Status']?.toString() ?? '';
          msceMessage = data['MSCE_Message']?.toString() ?? '';
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        studentTotalMarks = 0;
        teacherTotalMarks = subjects.where((s) => s['hasGrade'] == true).length * 100;
        studentPosition = 0;
        averageGradeLetter = '';
        msceStatus = '';
        msceMessage = '';
        aggregatePoints = 0;
        aggregatePosition = 0;
        formTeacherRemarks = '';
        headTeacherRemarks = '';
      });
    }
  }

  Future<void> _fetchSeniorStudentRemarks(String basePath) async {
    try {
      final remarksDoc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Results_Remarks')
          .get();

      if (remarksDoc.exists) {
        final remarksData = remarksDoc.data() as Map<String, dynamic>;

        setState(() {
          formTeacherRemarks = remarksData['Form_Teacher_Remark']?.toString() ?? 'N/A';
          headTeacherRemarks = remarksData['Head_Teacher_Remark']?.toString() ?? 'N/A';
        });
      } else {
        setState(() {
          formTeacherRemarks = 'N/A';
          headTeacherRemarks = 'N/A';
        });
      }
    } catch (e) {
      print("Error fetching student remarks: $e");
      setState(() {
        formTeacherRemarks = 'N/A';
        headTeacherRemarks = 'N/A';
      });
    }
  }

  String Seniors_Grade(int Seniors_Score) {
    if (Seniors_Score >= 90) return '1';
    if (Seniors_Score >= 80) return '2';
    if (Seniors_Score >= 75) return '3';
    if (Seniors_Score >= 70) return '4';
    if (Seniors_Score >= 65) return '5';
    if (Seniors_Score >= 60) return '6';
    if (Seniors_Score >= 55) return '7';
    if (Seniors_Score >= 50) return '8';
    return '9';
  }

  String getRemark(String Seniors_Grade) {
    switch (Seniors_Grade) {
      case '1': return 'Distinction';
      case '2': return 'Distinction';
      case '3': return 'Strong Credit';
      case '4': return 'Strong Credit';
      case '5': return 'Credit';
      case '6': return 'Weak Credit';
      case '7': return 'Pass';
      case '8': return 'Weak Pass';
      default: return 'Fail';
    }
  }

  String getPoints(String Seniors_Grade) {
    switch (Seniors_Grade) {
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

  double _getResponsiveFontSize(BuildContext context, {required double baseSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 360; // Based on standard mobile width
    return baseSize * scaleFactor.clamp(0.8, 1.2);
  }

  double _getResponsivePadding(BuildContext context, {required double basePadding}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 360;
    return basePadding * scaleFactor.clamp(0.8, 1.2);
  }

  Widget _buildSchoolHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsivePadding(context, basePadding: 8),
        horizontal: _getResponsivePadding(context, basePadding: 16),
      ),
      child: Column(
        children: [
          Text(
            (schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase(),
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Tel: ${schoolPhone ?? 'N/A'}',
            style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Email: ${schoolEmail ?? 'N/A'}',
            style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 10)),
          Text(
            'P.O. BOX ${boxNumber ?? 0}, ${schoolLocation?.toUpperCase() ?? 'N/A'}',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, baseSize: 16),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
          Text(
            '${getAcademicYear()} ${widget.studentClass} END OF TERM ${getCurrentTerm()} STUDENT\'S PROGRESS REPORT',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, baseSize: 16),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(context, basePadding: 16),
        vertical: _getResponsivePadding(context, basePadding: 8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSmallScreen)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NAME: ${widget.studentFullName}',
                      style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}',
                            style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                          ),
                        ),
                        SizedBox(width: _getResponsivePadding(context, basePadding: 10)),
                        Expanded(
                          child: Text(
                            'OUT OF: ${Total_Class_Students_Number > 0 ? Total_Class_Students_Number : (subjects.isNotEmpty ? subjects.first['totalStudents'] ?? 'N/A' : 'N/A')}',
                            style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
                    Text(
                      'CLASS: ${widget.studentClass}',
                      style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'NAME OF STUDENT: ${widget.studentFullName}',
                        style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}',
                              style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                            ),
                          ),
                          SizedBox(width: _getResponsivePadding(context, basePadding: 10)),
                          Expanded(
                            child: Text(
                              'OUT OF: ${Total_Class_Students_Number > 0 ? Total_Class_Students_Number : (subjects.isNotEmpty ? subjects.first['totalStudents'] ?? 'N/A' : 'N/A')}',
                              style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'CLASS: ${widget.studentClass}',
                        style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportTable(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_getResponsivePadding(context, basePadding: 16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidths = constraints.maxWidth < 400
              ? {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(0.8),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(2),
          }
              : {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.5),
            6: FlexColumnWidth(3),
          };

          return Table(
            border: TableBorder.all(),
            columnWidths: columnWidths,
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _tableCell(context, 'SUBJECT', isHeader: true),
                  _tableCell(context, 'MARKS %', isHeader: true),
                  _tableCell(context, 'POINTS', isHeader: true),
                  _tableCell(context, 'CLASS AVG', isHeader: true),
                  _tableCell(context, 'POS', isHeader: true),
                  _tableCell(context, 'OUT OF', isHeader: true),
                  _tableCell(context, 'COMMENTS', isHeader: true),
                ],
              ),
              ...subjects.map((subj) {
                final subjectName = subj['subject'] ?? 'Unknown';
                final hasGrade = subj['hasGrade'] as bool? ?? true;
                final score = subj['score'] as int? ?? 0;
                final grade = hasGrade ? (subj['gradeLetter']?.toString().isNotEmpty == true
                    ? subj['gradeLetter']
                    : Seniors_Grade(score)) : '';
                final remark = hasGrade ? getRemark(grade) : 'Doesn\'t take';
                final points = hasGrade ? getPoints(grade) : '';
                final subjectStat = subjectStats[subjectName];
                final avg = subjectStat != null ? (subjectStat['average'] as double).round() : 0;
                final subjectPosition = subj['position'] as int? ?? 0;
                final totalStudentsForSubject = subj['totalStudents'] as int? ?? 0;

                return TableRow(
                  children: [
                    _tableCell(context, subjectName),
                    _tableCell(context, hasGrade ? score.toString() : ''),
                    _tableCell(context, points),
                    _tableCell(context, hasGrade && avg > 0 ? avg.toString() : ''),
                    _tableCell(context, hasGrade && subjectPosition > 0 ? subjectPosition.toString() : ''),
                    _tableCell(context, hasGrade && totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : ''),
                    _tableCell(context, remark),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _tableCell(BuildContext context, String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(_getResponsivePadding(context, basePadding: 4)),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: _getResponsiveFontSize(context, baseSize: isHeader ? 14 : 12),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAggregateSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(context, basePadding: 16),
        vertical: _getResponsivePadding(context, basePadding: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '(Best 6 subjects)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AGGREGATE POINTS: $aggregatePoints',
                style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
              ),
            ],
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESULT: $msceStatus',
                style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
              ),
            ],
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
        ],
      ),
    );
  }

  Widget _buildGradingKey(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(context, basePadding: 16),
        vertical: _getResponsivePadding(context, basePadding: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MSCE GRADING KEY FOR ${(schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 16),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidths = constraints.maxWidth < 400
                  ? {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(0.8),
                2: FlexColumnWidth(0.8),
                3: FlexColumnWidth(0.8),
                4: FlexColumnWidth(0.8),
                5: FlexColumnWidth(0.8),
                6: FlexColumnWidth(0.8),
                7: FlexColumnWidth(0.8),
                8: FlexColumnWidth(0.8),
                9: FlexColumnWidth(0.8),
              }
                  : {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
                7: FlexColumnWidth(1),
                8: FlexColumnWidth(1),
                9: FlexColumnWidth(1),
              };

              return Table(
                border: TableBorder.all(),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    children: [
                      _tableCell(context, 'Mark Range', isHeader: true),
                      _tableCell(context, '100-90', isHeader: true),
                      _tableCell(context, '89-80', isHeader: true),
                      _tableCell(context, '79-75', isHeader: true),
                      _tableCell(context, '74-70', isHeader: true),
                      _tableCell(context, '69-65', isHeader: true),
                      _tableCell(context, '64-60', isHeader: true),
                      _tableCell(context, '59-55', isHeader: true),
                      _tableCell(context, '54-50', isHeader: true),
                      _tableCell(context, '0-49', isHeader: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableCell(context, 'Points', isHeader: true),
                      _tableCell(context, '1', isHeader: true),
                      _tableCell(context, '2', isHeader: true),
                      _tableCell(context, '3', isHeader: true),
                      _tableCell(context, '4', isHeader: true),
                      _tableCell(context, '5', isHeader: true),
                      _tableCell(context, '6', isHeader: true),
                      _tableCell(context, '7', isHeader: true),
                      _tableCell(context, '8', isHeader: true),
                      _tableCell(context, '9', isHeader: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableCell(context, 'Interpretation', isHeader: true),
                      _tableCell(context, 'Distinction', isHeader: true),
                      _tableCell(context, 'Distinction', isHeader: true),
                      _tableCell(context, 'Strong Credit', isHeader: true),
                      _tableCell(context, 'Strong Credit', isHeader: true),
                      _tableCell(context, 'Credit', isHeader: true),
                      _tableCell(context, 'Weak Credit', isHeader: true),
                      _tableCell(context, 'Pass', isHeader: true),
                      _tableCell(context, 'Weak Pass', isHeader: true),
                      _tableCell(context, 'Fail', isHeader: true),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
        ],
      ),
    );
  }

  Widget _buildRemarksSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(context, basePadding: 16),
        vertical: _getResponsivePadding(context, basePadding: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form Teacher\'s Remarks: ${formTeacherRemarks ?? 'N/A'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Text(
            'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Text(
            'School Fees: ${schoolFees ?? 'N/A'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Text(
            'School Bank Account: ${schoolBankAccount ?? 'N/A'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
          Text(
            'Next Term Opening Date: ${nextTermOpeningDate ?? 'N/A'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, baseSize: 14),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
        ],
      ),
    );
  }

  Future<void> _printDocument() async {
    try {
      final pdfGenerator = Seniors_School_Report_PDF(
        schoolName: schoolName,
        schoolPhone: schoolPhone,
        schoolEmail: schoolEmail,
        formTeacherRemarks: formTeacherRemarks,
        headTeacherRemarks: headTeacherRemarks,
        studentFullName: widget.studentFullName,
        studentClass: widget.studentClass,
        subjects: subjects,
        subjectStats: subjectStats,
        subjectPositions: subjectPositions,
        totalStudentsPerSubject: totalStudentsPerSubject,
        aggregatePoints: aggregatePoints,
        aggregatePosition: aggregatePosition,
        schoolFees: schoolFees,
        schoolBankAccount: schoolBankAccount,
        nextTermOpeningDate: nextTermOpeningDate,
        Total_Class_Students_Number: Total_Class_Students_Number,
        studentTotalMarks: studentTotalMarks,
        teacherTotalMarks: teacherTotalMarks,
        studentPosition: studentPosition,
        boxNumber: boxNumber,
        schoolLocation: schoolLocation,
      );

      await pdfGenerator.generateAndPrint();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
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
      appBar: AppBar(
        title: Text(
          'Progress Report',
          style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 20)),
        ),
<<<<<<< HEAD
        backgroundColor: Colors.grey[500],
=======
        backgroundColor: Colors.grey[300],
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
        actions: [
          IconButton(
            icon: Icon(Icons.print, size: _getResponsiveFontSize(context, baseSize: 24)),
            onPressed: _printDocument,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
            Text(
              'Loading student report...',
              style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 16)),
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
              size: _getResponsiveFontSize(context, baseSize: 64),
              color: Colors.red,
            ),
            SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
            Text(
              'Error Loading Report',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: _getResponsivePadding(context, basePadding: 8)),
            Text(
              errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: _getResponsiveFontSize(context, baseSize: 14),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: _getResponsivePadding(context, basePadding: 16)),
            ElevatedButton(
              onPressed: _fetchStudentData,
              child: Text(
                'Try Again',
                style: TextStyle(fontSize: _getResponsiveFontSize(context, baseSize: 14)),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_getResponsivePadding(context, basePadding: 8)),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSchoolHeader(context),
              _buildStudentInfo(context),
              _buildReportTable(context),
              _buildAggregateSection(context),
              _buildGradingKey(context),
              _buildRemarksSection(context),
              SizedBox(height: _getResponsivePadding(context, basePadding: 20)),
            ],
          ),
        ),
      ),
    );
  }
}