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
  Map<String, int> totalStudentsPerSubject = {}; // For total students per subject
  int studentPosition = 0;
  int totalStudents = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;

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

      print('Base Path: $basePath');

      await fetchStudentSubjects(basePath);
      await fetchTotalMarks(basePath);
      await calculate_Subject_Stats_And_Position(teacherSchool, studentClass, studentFullName);

      // Update total students count in Firestore
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

  Future<void> _updateTotalStudentsCount(String school, String studentClass) async {
    try {
      // Update the total students count in the class document
      await _firestore.collection('Schools/$school/Classes').doc(studentClass).update({
        'totalStudents': totalStudents,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Successfully updated total students count to $totalStudents');
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

      // Store total number of students
      setState(() {
        totalStudents = studentsSnapshot.docs.length;
      });

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

      // Calculate position per subject and total students per subject
      Map<String, int> positions = {};
      Map<String, int> totalsPerSubject = {};

      scoresPerStudentPerSubject.forEach((subject, studentScores) {
        // Store total students for this subject
        totalsPerSubject[subject] = studentScores.length;

        // Create a list of score entries to sort by score (not by name)
        List<MapEntry<String, int>> sortedScores = studentScores.entries.toList();
        // Sort by score in descending order
        sortedScores.sort((a, b) => b.value.compareTo(a.value));

        // Find position of current student based on sorted scores
        int position = 1;  // Start at position 1
        int lastScore = -1;
        int samePositionCount = 0;

        for (int i = 0; i < sortedScores.length; i++) {
          final studentEntry = sortedScores[i];
          final score = studentEntry.value;

          // Handle ties (same score gets same position)
          if (i > 0 && score == lastScore) {
            // Don't increment position for ties
            samePositionCount++;
          } else {
            // New score, so position is current index + 1 (accounting for ties)
            position = i + 1;
            samePositionCount = 0;
          }

          // Store the last score for tie detection
          lastScore = score;

          // If this is our target student, store their position
          if (studentEntry.key == studentFullName) {
            positions[subject] = position;
            break;
          }
        }
      });

      // Calculate overall position
      List<MapEntry<String, int>> sortedTotalMarks = totalMarksPerStudent.entries.toList();
      // Sort by total marks in descending order
      sortedTotalMarks.sort((a, b) => b.value.compareTo(a.value));

      // Find position with tie handling
      int position = 1;
      int lastTotalMark = -1;
      int studentPos = 0;

      for (int i = 0; i < sortedTotalMarks.length; i++) {
        final totalMarkEntry = sortedTotalMarks[i];
        final totalMark = totalMarkEntry.value;

        // Handle ties (same total mark gets same position)
        if (i > 0 && totalMark == lastTotalMark) {
          // Don't increment position for ties
        } else {
          // New total mark, so position is current index + 1
          position = i + 1;
        }

        // Store the last total mark for tie detection
        lastTotalMark = totalMark;

        // If this is our target student, store their position
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

  String Juniors_Remark(String Juniors_Grade) {
    switch (Juniors_Grade) {
      case 'A':
        return 'EXCELLENT';
      case 'B':
        return 'VERY GOOD';
      case 'C':
        return 'GOOD';
      case 'D':
        return 'PASS';
      default:
        return 'FAIL';
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
        trailing: Text('Position: $studentPosition out of $totalStudents'),
      ),
    );
  }

  Widget _buildReportTable() {
    int totalMarkValue = 0;
    if (totalMarks.containsKey('Total_Marks')) {
      totalMarkValue = (totalMarks['Total_Marks'] as num).round();
    }

    // Calculate teacher's total marks (sum of all maximum marks which is 100 per subject)
    int teacherTotalMarks = subjects.length * 100;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(3), // Subject
            1: FlexColumnWidth(2), // Score
            2: FlexColumnWidth(2), // Total (100%)
            3: FlexColumnWidth(1), // Grade
            4: FlexColumnWidth(3), // Remark
            5: FlexColumnWidth(2), // Position
            6: FlexColumnWidth(2), // Total Students
            7: FlexColumnWidth(2), // Average
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey.shade100),
              children: [
                _tableCell('SUBJECT', isHeader: true),
                _tableCell('SCORE', isHeader: true),
                _tableCell('TOTAL', isHeader: true),
                _tableCell('GRADE', isHeader: true),
                _tableCell('REMARK', isHeader: true),
                _tableCell('POSITION', isHeader: true),
                _tableCell('OUT OF', isHeader: true),
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

              // Get total students for this subject
              final totalStudentsForSubject = totalStudentsPerSubject[subjectName] ?? 0;

              return TableRow(children: [
                _tableCell(subjectName),
                _tableCell(score.toString()),
                _tableCell('100'), // Each subject has a maximum of 100 marks
                _tableCell(grade),
                _tableCell(remark),
                _tableCell(subjectPosition.toString()),
                _tableCell(totalStudentsForSubject.toString()),
                _tableCell(avg.toString()),
              ]);
            }).toList(),
            // Add TOTAL MARKS row at the bottom
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey.shade100),
              children: [
                _tableCell('TOTAL MARKS', isHeader: true),
                _tableCell(totalMarkValue.toString(), isHeader: true),
                _tableCell(teacherTotalMarks.toString(), isHeader: true),
                _tableCell('', isHeader: true),
                _tableCell('', isHeader: true),
                _tableCell('', isHeader: true),
                _tableCell('', isHeader: true),
                _tableCell('', isHeader: true),
              ],
            ),
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
            Text('POSITION IN CLASS: $studentPosition out of $totalStudents', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _printDocument() async {
    // Create a PDF document with proper formatting
    final doc = pw.Document();

    // Get current date for the report
    final now = DateTime.now();
    final dateStr = "${now.day}-${now.month}-${now.year}";

    // Get total mark value
    int totalMarkValue = 0;
    if (totalMarks.containsKey('Total_Marks')) {
      totalMarkValue = (totalMarks['Total_Marks'] as num).round();
    }

    // Calculate teacher's total marks (sum of all maximum marks which is 100 per subject)
    int teacherTotalMarks = subjects.length * 100;

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(schoolName ?? "School Report", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("STUDENT REPORT CARD", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("Date: $dateStr", style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Student info
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Name: ${widget.studentFullName}", style: pw.TextStyle(fontSize: 12)),
                          pw.Text("Class: ${widget.studentClass}", style: pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Position: $studentPosition out of $totalStudents", style: pw.TextStyle(fontSize: 12)),
                          pw.Text("Total Marks: $totalMarkValue", style: pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Subject table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3), // Subject
                    1: pw.FlexColumnWidth(1.5), // Score
                    2: pw.FlexColumnWidth(1.5), // Total
                    3: pw.FlexColumnWidth(1), // Grade
                    4: pw.FlexColumnWidth(2), // Remark
                    5: pw.FlexColumnWidth(1.5), // Position
                    6: pw.FlexColumnWidth(1.5), // Out of
                    7: pw.FlexColumnWidth(1.5), // Average
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _pdfTableCell('SUBJECT', isHeader: true),
                        _pdfTableCell('SCORE', isHeader: true),
                        _pdfTableCell('TOTAL', isHeader: true),
                        _pdfTableCell('GRADE', isHeader: true),
                        _pdfTableCell('REMARK', isHeader: true),
                        _pdfTableCell('POS', isHeader: true),
                        _pdfTableCell('OUT OF', isHeader: true),
                        _pdfTableCell('AVG', isHeader: true),
                      ],
                    ),
                    // Subject rows
                    ...subjects.map((subj) {
                      final subjectName = subj['subject'] ?? 'Unknown';
                      final score = subj['score'] as int? ?? 0;
                      final grade = Juniors_Grade(score);
                      final remark = Juniors_Remark(grade);
                      final subjectStat = subjectStats[subjectName];
                      final avg = subjectStat != null ? subjectStat['average'] as int : 0;
                      final subjectPosition = subjectPositions[subjectName] ?? 0;
                      final totalStudentsForSubject = totalStudentsPerSubject[subjectName] ?? 0;

                      return pw.TableRow(
                        children: [
                          _pdfTableCell(subjectName),
                          _pdfTableCell(score.toString()),
                          _pdfTableCell('100'), // Each subject has a maximum of 100 marks
                          _pdfTableCell(grade),
                          _pdfTableCell(remark),
                          _pdfTableCell(subjectPosition.toString()),
                          _pdfTableCell(totalStudentsForSubject.toString()),
                          _pdfTableCell(avg.toString()),
                        ],
                      );
                    }).toList(),
                    // TOTAL MARKS row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _pdfTableCell('TOTAL MARKS', isHeader: true),
                        _pdfTableCell(totalMarkValue.toString(), isHeader: true),
                        _pdfTableCell(teacherTotalMarks.toString(), isHeader: true),
                        _pdfTableCell('', isHeader: true),
                        _pdfTableCell('', isHeader: true),
                        _pdfTableCell('', isHeader: true),
                        _pdfTableCell('', isHeader: true),
                        _pdfTableCell('', isHeader: true),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Signature section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 0.5,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text("Class Teacher's Signature", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 0.5,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text("Principal's Signature", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Footer
                pw.Center(
                  child: pw.Text("This is an official student report generated on $dateStr",
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700
                      )
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}