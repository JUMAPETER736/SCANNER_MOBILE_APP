import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  Map<String, dynamic> subjectStats = {}; // For average per subject
  Map<String, int> subjectPositions = {}; // For position per subject
  int studentPosition = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;

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

      print('Base Path: $basePath');

      await fetchStudentSubjects(basePath);
      await fetchTotalMarks(basePath);
      await calculate_Subject_Stats_And_Position(teacherSchool, studentClass, studentFullName);

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

  Future<void> fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore.collection('$basePath/Student_Subjects').get();

      List<Map<String, dynamic>> subjectList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Convert Subject_Grade to int
        int score = 0;
        if (data['Subject_Grade'] != null) {
          // First convert to double, then to int
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
      setState(() {
        // Error state handling
      });
    }
  }

  Future<void> fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore.doc('$basePath/TOTAL_MARKS/Marks').get();

      if (doc.exists) {
        setState(() {
          totalMarks = doc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          // Handle no total marks found
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        // Error state handling
      });
    }
  }

  Future<void> calculate_Subject_Stats_And_Position(
      String school, String studentClass, String studentFullName) async {
    try {
      // Fetch all students under this class
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      // Prepare data for average per subject, total marks ranking, and subject positions
      Map<String, List<int>> marksPerSubject = {};
      Map<String, Map<String, int>> scoresPerStudentPerSubject = {};
      Map<String, int> totalMarksPerStudent = {};

      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        // Get total marks for this student
        final totalMarksDoc = await _firestore.doc('Schools/$school/Classes/$studentClass/Student_Details/$studentName/TOTAL_MARKS/Marks').get();
        int totalMarkValue = 0;
        if (totalMarksDoc.exists) {
          final data = totalMarksDoc.data();
          if (data != null && data['Total_Marks'] != null) {
            totalMarkValue = (data['Total_Marks'] as num).round();
          }
        }
        totalMarksPerStudent[studentName] = totalMarkValue;

        // Fetch student subjects and marks
        final subjectsSnapshot = await _firestore.collection('Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects').get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? '0';
          int grade = double.tryParse(gradeStr)?.round() ?? 0;

          // Store for average calculation
          if (!marksPerSubject.containsKey(subjectName)) {
            marksPerSubject[subjectName] = [];
          }
          marksPerSubject[subjectName]!.add(grade);

          // Store for position calculation
          if (!scoresPerStudentPerSubject.containsKey(subjectName)) {
            scoresPerStudentPerSubject[subjectName] = {};
          }
          scoresPerStudentPerSubject[subjectName]![studentName] = grade;
        }
      }

      // Calculate average for each subject
      Map<String, int> averages = {};
      marksPerSubject.forEach((subject, scores) {
        int total = scores.fold(0, (prev, el) => prev + el);
        int avg = scores.isNotEmpty ? (total / scores.length).round() : 0;
        averages[subject] = avg;
      });

      // Calculate position per subject
      Map<String, int> positions = {};
      scoresPerStudentPerSubject.forEach((subject, studentScores) {
        // Sort students by score for this subject (descending)
        List<MapEntry<String, int>> sortedScores = studentScores.entries.toList();
        sortedScores.sort((a, b) => b.value.compareTo(a.value));

        // Find position of current student
        int subjectPosition = 0;
        for (int i = 0; i < sortedScores.length; i++) {
          if (sortedScores[i].key == studentFullName) {
            // Position is 1-based
            subjectPosition = i + 1;
            break;
          }
        }

        positions[subject] = subjectPosition;
      });

      // Calculate overall position of current student by sorting total marks descending
      List<MapEntry<String, int>> sortedTotals = totalMarksPerStudent.entries.toList();
      sortedTotals.sort((a, b) => b.value.compareTo(a.value)); // Descending

      int pos = 0;
      for (int i = 0; i < sortedTotals.length; i++) {
        if (sortedTotals[i].key == studentFullName) {
          pos = i + 1; // Position is 1-based
          break;
        }
      }

      setState(() {
        subjectStats = averages.map((key, value) => MapEntry(key, {'average': value}));
        subjectPositions = positions;
        studentPosition = pos;
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

  String Juniors_Remark(String Juniors_Grade) {
    switch (Juniors_Grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Pass';
      default:
        return 'Fail';
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
        title: Text('School Report: ${widget.studentFullName}'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchStudentData),
          IconButton(icon: Icon(Icons.print), onPressed: _printDocument),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSchoolInfoCard(),
              SizedBox(height: 16),
              _buildReportTable(),
              SizedBox(height: 16),
              _buildSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    return Card(
      child: ListTile(
        title: Text('Class: ${widget.studentClass}'),
        subtitle: Text('Student: ${widget.studentFullName}'),
        trailing: Text('Position: $studentPosition'),
      ),
    );
  }

  Widget _buildReportTable() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(3), // Subject
            1: FlexColumnWidth(2), // Score
            2: FlexColumnWidth(1), // Grade
            3: FlexColumnWidth(3), // Remark
            4: FlexColumnWidth(2), // Position (per subject)
            5: FlexColumnWidth(2), // Average
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey.shade100),
              children: [
                _tableCell('SUBJECT', isHeader: true),
                _tableCell('SCORE', isHeader: true),
                _tableCell('GRADE', isHeader: true),
                _tableCell('REMARK', isHeader: true),
                _tableCell('POSITION', isHeader: true),
                _tableCell('AVERAGE', isHeader: true),
              ],
            ),
            ...subjects.map((subj) {
              final subjectName = subj['subject'] ?? 'Unknown';
              final score = subj['score'] as int? ?? 0;
              final grade = Juniors_Grade(score);
              final remark = Juniors_Remark(grade);

              // Get average for this subject if available
              final subjectStat = subjectStats[subjectName];
              final avg = subjectStat != null ? subjectStat['average'] as int : 0;

              // Get position for this subject
              final subjectPosition = subjectPositions[subjectName] ?? 0;

              return TableRow(children: [
                _tableCell(subjectName),
                _tableCell(score.toString()),
                _tableCell(grade),
                _tableCell(remark),
                _tableCell(subjectPosition.toString()),
                _tableCell(avg.toString()),
              ]);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    int totalMarkValue = 0;
    if (totalMarks.containsKey('Total_Marks')) {
      totalMarkValue = (totalMarks['Total_Marks'] as num).round();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTAL MARKS: $totalMarkValue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('POSITION IN CLASS: $studentPosition', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _printDocument() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text("School Report for - ${widget.studentFullName}"),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}