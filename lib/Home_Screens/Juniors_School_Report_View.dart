import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class Juniors_School_Report_View extends StatefulWidget {
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Report_View({
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() => _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  Map<String, dynamic> subjectStats = {};
  Map<String, int> subjectPositions = {};
  Map<String, int> totalStudentsPerSubject = {};
  int studentPosition = 0;
  int totalStudents = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;
  String? schoolAddress;
  String? schoolPhone;
  String? schoolEmail;
  String? schoolAccount;
  String? nextTermDate;
  String? formTeacherRemarks;
  String? headTeacherRemarks;
  int studentTotalMarks = 0;
  int teacherTotalMarks = 0;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
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

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Classes before accessing reports.';
        });
        return;
      }

      schoolName = teacherSchool;
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 1' && studentClass != 'FORM 2') {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Only students in FORM 1 or FORM 2 can access this report.';
        });
        return;
      }

      final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

      await _fetchSchoolInfo(teacherSchool);
      await fetchStudentSubjects(basePath);
      await fetchTotalMarks(basePath);
      await calculate_Subject_Stats_And_Position(teacherSchool, studentClass, studentFullName);
      await _updateTotalStudentsCount(teacherSchool, studentClass);

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

  Future<void> _fetchSchoolInfo(String school) async {
    try {
      DocumentSnapshot schoolDoc = await _firestore.collection('Schools').doc(school).get();
      if (schoolDoc.exists) {
        setState(() {
          schoolAddress = schoolDoc['address'] ?? 'P.O. BOX 43, LIKUNI.';
          schoolPhone = schoolDoc['phone'] ?? '(+265) 0 997 974 545 or (+265) 0 888 084 670';
          schoolEmail = schoolDoc['email'] ?? 'info.likunigirls196@gmail.com/likunigirls196@gmail.com';
          schoolAccount = schoolDoc['account'] ?? 'Centenary Bank of Malawi, Old Town Branch, Current Account, Likuni Girls Secondary School, Ace. No. 9043689270025';
          nextTermDate = schoolDoc['nextTermDate'] ?? 'Monday, 06th January, 2025';
          formTeacherRemarks = schoolDoc['formTeacherRemarks'] ?? 'She is disciplined and mature, encourage her to continue portraying good behaviour';
          headTeacherRemarks = schoolDoc['headTeacherRemarks'] ?? 'Continue working hard and encourage her to maintain scoring above pass mark in all the subjects';
        });
      }
    } catch (e) {
      print("Error fetching school info: $e");
    }
  }

  Future<void> _updateTotalStudentsCount(String school, String studentClass) async {
    try {
      await _firestore.collection('Schools/$school/Classes').doc(studentClass).update({
        'totalStudents': totalStudents,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating total students count: $e');
    }
  }

  Future<void> fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore.collection('$basePath/Student_Subjects').get();
      List<Map<String, dynamic>> subjectList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        int score = 0;
        if (data['Subject_Grade'] != null) {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': score,
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
      final doc = await _firestore.doc('$basePath/TOTAL_MARKS/Marks').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          totalMarks = data;
          studentTotalMarks = (data['Total_Marks'] as num?)?.toInt() ?? 0;
          teacherTotalMarks = (data['Teacher_Total_Marks'] as num?)?.toInt() ?? (subjects.length * 100);
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
    }
  }

  Future<void> calculate_Subject_Stats_And_Position(
      String school, String studentClass, String studentFullName) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      setState(() {
        totalStudents = studentsSnapshot.docs.length;
      });

      Map<String, List<int>> marksPerSubject = {};
      Map<String, Map<String, int>> scoresPerStudentPerSubject = {};
      Map<String, int> totalMarksPerStudent = {};

      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        final totalMarksDoc = await _firestore.doc('Schools/$school/Classes/$studentClass/Student_Details/$studentName/TOTAL_MARKS/Marks').get();
        int totalMarkValue = 0;
        if (totalMarksDoc.exists) {
          final data = totalMarksDoc.data();
          if (data != null && data['Total_Marks'] != null) {
            totalMarkValue = (data['Total_Marks'] as num).round();
          }
        }
        totalMarksPerStudent[studentName] = totalMarkValue;

        final subjectsSnapshot = await _firestore.collection('Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects').get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? '0';
          int grade = double.tryParse(gradeStr)?.round() ?? 0;

          if (!marksPerSubject.containsKey(subjectName)) {
            marksPerSubject[subjectName] = [];
          }
          marksPerSubject[subjectName]!.add(grade);

          if (!scoresPerStudentPerSubject.containsKey(subjectName)) {
            scoresPerStudentPerSubject[subjectName] = {};
          }
          scoresPerStudentPerSubject[subjectName]![studentName] = grade;
        }
      }

      Map<String, int> averages = {};
      marksPerSubject.forEach((subject, scores) {
        int total = scores.fold(0, (prev, el) => prev + el);
        int avg = scores.isNotEmpty ? (total / scores.length).round() : 0;
        averages[subject] = avg;
      });

      Map<String, int> positions = {};
      Map<String, int> totalsPerSubject = {};

      scoresPerStudentPerSubject.forEach((subject, studentScores) {
        totalsPerSubject[subject] = studentScores.length;

        List<MapEntry<String, int>> sortedScores = studentScores.entries.toList();
        sortedScores.sort((a, b) => b.value.compareTo(a.value));

        int position = 1;
        int lastScore = -1;

        for (int i = 0; i < sortedScores.length; i++) {
          final studentEntry = sortedScores[i];
          final score = studentEntry.value;

          if (i > 0 && score == lastScore) {
            // Same position for same score
          } else {
            position = i + 1;
          }

          lastScore = score;

          if (studentEntry.key == studentFullName) {
            positions[subject] = position;
            break;
          }
        }
      });

      List<MapEntry<String, int>> sortedTotalMarks = totalMarksPerStudent.entries.toList();
      sortedTotalMarks.sort((a, b) => b.value.compareTo(a.value));

      int position = 1;
      int lastTotalMark = -1;
      int studentPos = 0;

      for (int i = 0; i < sortedTotalMarks.length; i++) {
        final totalMarkEntry = sortedTotalMarks[i];
        final totalMark = totalMarkEntry.value;

        if (i > 0 && totalMark == lastTotalMark) {
          // Same position for same total marks
        } else {
          position = i + 1;
        }

        lastTotalMark = totalMark;

        if (totalMarkEntry.key == studentFullName) {
          studentPos = position;
          break;
        }
      }

      setState(() {
        subjectStats = averages.map((key, value) => MapEntry(key, {'average': value}));
        subjectPositions = positions;
        totalStudentsPerSubject = totalsPerSubject;
        studentPosition = studentPos;
      });
    } catch (e) {
      print("Error calculating stats & position: $e");
    }
  }

  String Juniors_Grade(int Juniors_Score) {
    if (Juniors_Score >= 85) return 'A';
    if (Juniors_Score >= 75) return 'B';
    if (Juniors_Score >= 65) return 'C';
    if (Juniors_Score >= 50) return 'D';
    return 'F';
  }

  String getRemark(String Juniors_Grade) {
    switch (Juniors_Grade) {
      case 'A': return 'EXCELLENT';
      case 'B': return 'VERY GOOD';
      case 'C': return 'GOOD';
      case 'D': return 'PASS';
      default: return 'FAIL';
    }
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
        title: Text('${widget.studentClass} Progress Report'),
        actions: [
          IconButton(icon: Icon(Icons.print), onPressed: _printDocument),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              _buildSchoolHeader(),
              _buildStudentInfo(),
              _buildReportTable(),
              _buildGradingKey(),
              _buildRemarksSection(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolHeader() {
    return Column(
      children: [
        Text(
          schoolName ?? 'LIKUNI GIRLS\' SECONDARY SCHOOL',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          schoolAddress ?? 'P.O. BOX 43, LIKUNI.',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Text(
          'Tel: ${schoolPhone ?? '(+265) 0 997 974 545 or (+265) 0 888 084 670'}',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Text(
          'Email: ${schoolEmail ?? 'info.likunigirls196@gmail.com/likunigirls196@gmail.com'}',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          '${DateFormat('yyyy').format(DateTime.now())}/${DateFormat('yy').format(DateTime.now().add(Duration(days: 365)))} '
              '${widget.studentClass} END OF TERM ONE STUDENT\'S PROGRESS REPORT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('NAME OF STUDENT: ${widget.studentFullName}'),
          Text('CLASS: ${widget.studentClass}'),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(),
        columnWidths: {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.5),
          6: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: [
              _tableCell('SUBJECT', isHeader: true),
              _tableCell('MARKS %', isHeader: true),
              _tableCell('GRADE', isHeader: true),
              _tableCell('CLASS AVERAGE', isHeader: true),
              _tableCell('POSITION', isHeader: true),
              _tableCell('OUT OF', isHeader: true),
              _tableCell('TEACHERS\' COMMENTS', isHeader: true),
            ],
          ),
          ...subjects.map((subj) {
            final subjectName = subj['subject'] ?? 'Unknown';
            final score = subj['score'] as int? ?? 0;
            final grade = Juniors_Grade(score);
            final remark = getRemark(grade);
            final subjectStat = subjectStats[subjectName];
            final avg = subjectStat != null ? subjectStat['average'] as int : 0;
            final subjectPosition = subjectPositions[subjectName] ?? 0;
            final totalStudentsForSubject = totalStudentsPerSubject[subjectName] ?? 0;

            return TableRow(
              children: [
                _tableCell(subjectName),
                _tableCell(score.toString()),
                _tableCell(grade),
                _tableCell(avg.toString()),
                _tableCell(subjectPosition.toString()),
                _tableCell(totalStudentsForSubject.toString()),
                _tableCell(remark),
              ],
            );
          }).toList(),
          // TOTAL MARKS row
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: [
              _tableCell('TOTAL MARKS', isHeader: true),
              _tableCell(studentTotalMarks.toString(), isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
      ),
    );
  }

  Widget _buildGradingKey() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JCE GRADING KEY',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Table(
            border: TableBorder.all(),
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _tableCell('Mark Range', isHeader: true),
                  _tableCell('Grade', isHeader: true),
                  _tableCell('Interpretation', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('85-100', isHeader: true),
                  _tableCell('A', isHeader: true),
                  _tableCell('EXCELLENT', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('75-84', isHeader: true),
                  _tableCell('B', isHeader: true),
                  _tableCell('VERY GOOD', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('65-74', isHeader: true),
                  _tableCell('C', isHeader: true),
                  _tableCell('GOOD', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('50-64', isHeader: true),
                  _tableCell('D', isHeader: true),
                  _tableCell('PASS', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('0-49', isHeader: true),
                  _tableCell('F', isHeader: true),
                  _tableCell('FAIL', isHeader: true),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Form Teachers\' Remarks: ${formTeacherRemarks ?? 'She is disciplined and mature, encourage her to continue portraying good behaviour'}',
              style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 8),
          Text('Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'Continue working hard and encourage her to maintain scoring above pass mark in all the subjects'}',
              style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fees for next term', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('School account: ${schoolAccount ?? 'Centenary Bank of Malawi, Old Town Branch, Current Account, Likuni Girls Secondary School, Ace. No. 9043689270025'}'),
          SizedBox(height: 8),
          Text('Next term begins on ${nextTermDate ?? 'Monday, 06th January, 2025'}',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _printDocument() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // School Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName ?? 'LIKUNI GIRLS\' SECONDARY SCHOOL',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      schoolAddress ?? 'P.O. BOX 43, LIKUNI.',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Tel: ${schoolPhone ?? '(+265) 0 997 974 545 or (+265) 0 888 084 670'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Email: ${schoolEmail ?? 'info.likunigirls196@gmail.com/likunigirls196@gmail.com'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      '${DateFormat('yyyy').format(DateTime.now())}/${DateFormat('yy').format(DateTime.now().add(Duration(days: 365)))} '
                          '${widget.studentClass} END OF TERM ONE STUDENT\'S PROGRESS REPORT',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Student Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NAME OF STUDENT: ${widget.studentFullName}'),
                  pw.Text('CLASS: ${widget.studentClass}'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Report Table
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['SUBJECT', 'MARKS %', 'GRADE', 'CLASS AVERAGE', 'POSITION', 'OUT OF', 'TEACHERS\' COMMENTS'],
                data: subjects.map((subj) {
                  final subjectName = subj['subject'] ?? 'Unknown';
                  final score = subj['score'] as int? ?? 0;
                  final grade = Juniors_Grade(score);
                  final remark = getRemark(grade);
                  final subjectStat = subjectStats[subjectName];
                  final avg = subjectStat != null ? subjectStat['average'] as int : 0;
                  final subjectPosition = subjectPositions[subjectName] ?? 0;
                  final totalStudentsForSubject = totalStudentsPerSubject[subjectName] ?? 0;

                  return [
                    subjectName,
                    score.toString(),
                    grade,
                    avg.toString(),
                    subjectPosition.toString(),
                    totalStudentsForSubject.toString(),
                    remark,
                  ];
                }).toList(),
              ),

              // TOTAL MARKS row
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['TOTAL MARKS', '', '', '', '', '', ''],
                data: [
                  [studentTotalMarks.toString(), '', '', '', '', '', '']
                ],
              ),

              pw.SizedBox(height: 20),

              // Grading Key
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'JCE GRADING KEY',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    headers: ['Mark Range', 'Grade', 'Interpretation'],
                    data: [
                      ['85-100', 'A', 'EXCELLENT'],
                      ['75-84', 'B', 'VERY GOOD'],
                      ['65-74', 'C', 'GOOD'],
                      ['50-64', 'D', 'PASS'],
                      ['0-49', 'F', 'FAIL'],
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Remarks Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Form Teachers\' Remarks: ${formTeacherRemarks ?? 'She is disciplined and mature, encourage her to continue portraying good behaviour'}',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'Continue working hard and encourage her to maintain scoring above pass mark in all the subjects'}',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Fees for next term', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('School account: ${schoolAccount ?? 'Centenary Bank of Malawi, Old Town Branch, Current Account, Likuni Girls Secondary School, Ace. No. 9043689270025'}'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Next term begins on ${nextTermDate ?? 'Monday, 06th January, 2025'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}