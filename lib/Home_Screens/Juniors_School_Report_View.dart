import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Map<String, dynamic> subjectStats = {}; // For average and total per subject
  int studentPosition = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;

  String _statusMessage = '';

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
      await calculateSubjectStatsAndPosition(teacherSchool, studentClass, studentFullName);

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
        // We expect Subject_Grade as string (score)
        double score = 0;
        if (data['Subject_Grade'] != null) {
          score = double.tryParse(data['Subject_Grade'].toString()) ?? 0;
        }

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': score,
        });
      }

      setState(() {
        subjects = subjectList;
        _statusMessage = 'Subjects fetched successfully.';
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      setState(() {
        _statusMessage = 'Failed to load subjects.';
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
          _statusMessage = 'No total marks found.';
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        _statusMessage = 'Failed to load total marks.';
      });
    }
  }

  /// Calculate average & total marks for each subject,
  /// and calculate overall student position based on total marks
  Future<void> calculateSubjectStatsAndPosition(String school, String studentClass, String studentFullName) async {
    try {
      // Fetch all students under this class
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      // Prepare data for average per subject & total marks ranking
      Map<String, List<double>> marksPerSubject = {};
      Map<String, double> totalMarksPerStudent = {};

      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        // Get total marks for this student
        final totalMarksDoc = await _firestore.doc('Schools/$school/Classes/$studentClass/Student_Details/$studentName/TOTAL_MARKS/Marks').get();
        double totalMarkValue = 0;
        if (totalMarksDoc.exists) {
          final data = totalMarksDoc.data();
          if (data != null && data['Total_Marks'] != null) {
            totalMarkValue = (data['Total_Marks'] as num).toDouble();
          }
        }
        totalMarksPerStudent[studentName] = totalMarkValue;

        // Fetch student subjects and marks for average calc
        final subjectsSnapshot = await _firestore.collection('Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects').get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? '0';
          double grade = double.tryParse(gradeStr) ?? 0;

          if (!marksPerSubject.containsKey(subjectName)) {
            marksPerSubject[subjectName] = [];
          }
          marksPerSubject[subjectName]!.add(grade);
        }
      }

      // Calculate average and total for each subject
      Map<String, Map<String, double>> stats = {};
      marksPerSubject.forEach((subject, scores) {
        double total = scores.fold(0, (prev, el) => prev + el);
        double avg = scores.isNotEmpty ? total / scores.length : 0;
        stats[subject] = {'total': total, 'average': avg};
      });

      // Calculate position of current student by sorting total marks descending
      List<MapEntry<String, double>> sortedTotals = totalMarksPerStudent.entries.toList();
      sortedTotals.sort((a, b) => b.value.compareTo(a.value)); // Descending

      int pos = 1;
      for (var entry in sortedTotals) {
        if (entry.key == studentFullName) {
          studentPosition = pos;
          break;
        }
        pos++;
      }

      setState(() {
        subjectStats = stats;
      });
    } catch (e) {
      print("Error calculating stats & position: $e");
    }
  }

  String getGrade(double score) {
    if (score >= 85) return 'A';
    if (score >= 75) return 'B';
    if (score >= 65) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  String getRemark(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Fair';
      default:
        return 'Poor';
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
            4: FlexColumnWidth(1), // Position (per subject - can be empty or future)
            5: FlexColumnWidth(2), // Average
            6: FlexColumnWidth(2), // Total
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
                _tableCell('TOTAL', isHeader: true),
              ],
            ),
            ...subjects.map((subj) {
              final subjectName = subj['subject'] ?? 'Unknown';
              final score = subj['score'] ?? 0.0;
              final grade = getGrade(score);
              final remark = getRemark(grade);

              // Get average and total for this subject if available
              final subjectStat = subjectStats[subjectName];
              final avg = subjectStat != null ? subjectStat['average'] as double : 0.0;
              final total = subjectStat != null ? subjectStat['total'] as double : 0.0;

              // POSITION per subject is tricky: We can leave blank or implement later
              final subjectPosition = '-';

              return TableRow(children: [
                _tableCell(subjectName),
                _tableCell(score.toStringAsFixed(1)),
                _tableCell(grade),
                _tableCell(remark),
                _tableCell(subjectPosition),
                _tableCell(avg.toStringAsFixed(1)),
                _tableCell(total.toStringAsFixed(1)),
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
    double totalMarkValue = 0;
    if (totalMarks.containsKey('Total_Marks')) {
      totalMarkValue = (totalMarks['Total_Marks'] as num).toDouble();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTAL MARKS: ${totalMarkValue.toStringAsFixed(1)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('POSITION IN CLASS: $studentPosition', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
