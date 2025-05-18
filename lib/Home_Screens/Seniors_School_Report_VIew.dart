

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class Seniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_School_Report_ViewState createState() => _Seniors_School_Report_ViewState();
}

class _Seniors_School_Report_ViewState extends State<Seniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }


  Future<void> fetchStudentData() async {
    try {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      // Define the base path for student data
      final String basePath = 'Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}';

      // Step 1: Fetch all subjects from Student_Subjects collection
      final studentSubjectsRef = _firestore.doc(basePath).collection('Student_Subjects');

      final subjectDocsSnapshot = await studentSubjectsRef.get();

      // List of all possible subjects (to ensure we include subjects even if they don't have data)
      List<String> subjectNames = [
        'AGRICULTURE',
        'BIBLE KNOWLEDGE',
        'BIOLOGY',
        'CHEMISTRY',
        'CHICHEWA',
        'COMPUTER SCIENCE',
        'ENGLISH',
        'LIFE SKILLS',
        'MATHEMATICS',
        'PHYSICS',
        'SOCIAL STUDIES'
      ];

      List<Map<String, dynamic>> subjectsData = [];

      // First, add subjects that exist in Firestore
      for (var doc in subjectDocsSnapshot.docs) {
        final subjectData = doc.data();
        final subjectName = subjectData['Subject_Name'] ?? doc.id;
        String grade = subjectData['Subject_Grade']?.toString() ?? '0';
        int score = int.tryParse(grade) ?? 0;

        subjectsData.add({
          'Subject_Name': subjectName,
          'Subject_Score': grade,
          'Subject_Grade': _getGradeLetter(score),
          'Grade_Interpretation': _getGradeInterpretation(score),
          'Teacher_Comment': _generateTeacherComment(score),
        });

        // Remove from the list of subjects to check
        subjectNames.remove(subjectName);
      }

      // Then add placeholders for subjects that don't have data
      for (var subjectName in subjectNames) {
        subjectsData.add({
          'Subject_Name': subjectName,
          'Subject_Score': 'N/A',
          'Subject_Grade': '-',
          'Grade_Interpretation': 'No data',
          'Teacher_Comment': '',
        });
      }

      // Sort subjects alphabetically
      subjectsData.sort((a, b) => a['Subject_Name'].compareTo(b['Subject_Name']));

      // Step 2: Fetch total marks
      final totalMarksRef = _firestore.doc(basePath).collection('TOTAL_MARKS').doc('Marks');

      final totalMarksDoc = await totalMarksRef.get();

      Map<String, dynamic> totalMarksData = {};
      String average = 'N/A';

      if (totalMarksDoc.exists) {
        final data = totalMarksDoc.data() ?? {};
        totalMarksData = data;

        int studentTotal = int.tryParse(data['Student_Total_Marks']?.toString() ?? '0') ?? 0;
        int teacherTotal = int.tryParse(data['Teacher_Total_Marks']?.toString() ?? '0') ?? 0;

        if (teacherTotal > 0) {
          average = '${(studentTotal / teacherTotal * 100).toStringAsFixed(1)}%';
        }

        totalMarksData['Average_Score'] = average;
      }

      setState(() {
        subjects = subjectsData;
        totalMarks = totalMarksData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _errorMessage = 'Error fetching data: ${e.toString()}';
        print('Error details: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        setState(() => _errorMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Report: ${widget.studentFullName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchStudentData,
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printDocument,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchStudentData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSchoolInfoCard(),
              SizedBox(height: 16),
              _buildSubjectsCard(),
              SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.schoolName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Student: ${widget.studentFullName}',
                style: TextStyle(fontSize: 16)),
            Text('Class: ${widget.studentClass}',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SUBJECTS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Total Subjects: ${subjects.length}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            Divider(thickness: 2),
            SizedBox(height: 10),
            ...subjects.map((subject) => _buildSubjectTile(subject)),
          ],
        ),
      ),
    );
  }


  Widget _buildSubjectTile(Map<String, dynamic> subject) {
    final bool hasData = subject['Subject_Score'] != 'N/A';
    final Color gradeColor = _getGradeColor(subject['Subject_Grade']);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject['Subject_Name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text('Score: ${subject['Subject_Score']}'),
              SizedBox(width: 16),
              Text(
                'Grade: ${subject['Subject_Grade']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
              SizedBox(width: 16),
              Text('(${subject['Grade_Interpretation']})'),
            ],
          ),
          if (hasData) ...[
            SizedBox(height: 4),
            Text(
              'Comment: ${subject['Teacher_Comment']}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          Divider(),
        ],
      ),
    );
  }


  Widget _buildSummaryCard() {
    final studentTotalMarks = totalMarks['Student_Total_Marks'] ?? 'N/A';
    final teacherTotalMarks = totalMarks['Teacher_Total_Marks'] ?? 'N/A';
    final averageScore = totalMarks['Average_Score'] ?? 'N/A';

    // Calculate overall grade based on average
    String overallGrade = '-';
    String overallInterpretation = '-';

    if (averageScore != 'N/A') {
      final percentValue = double.tryParse(averageScore.replaceAll('%', '')) ?? 0;
      overallGrade = _getGradeLetter(percentValue.toInt());
      overallInterpretation = _getGradeInterpretation(percentValue.toInt());
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACADEMIC SUMMARY',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildSummaryRow('Total Marks', '$studentTotalMarks / $teacherTotalMarks'),
            _buildSummaryRow('Average Score', averageScore),
            _buildSummaryRow('Overall Grade', '$overallGrade ($overallInterpretation)'),
            SizedBox(height: 16),
            _buildOverallCommentSection(averageScore),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOverallCommentSection(String averageScore) {
    String comment = 'No data available to generate overall comment.';

    if (averageScore != 'N/A') {
      final percentValue = double.tryParse(averageScore.replaceAll('%', '')) ?? 0;
      comment = _generateOverallComment(percentValue.toInt());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        Text('CLASS TEACHER\'S COMMENT:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(comment, style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }


  Future<void> _printDocument() async {
    final doc = pw.Document();

    final hasData = totalMarks.isNotEmpty;
    final studentTotalMarks = totalMarks['Student_Total_Marks'] ?? 'N/A';
    final teacherTotalMarks = totalMarks['Teacher_Total_Marks'] ?? 'N/A';
    final averageScore = totalMarks['Average_Score'] ?? 'N/A';

    // Calculate overall grade for PDF
    String overallGrade = '-';
    String overallInterpretation = '-';
    String overallComment = 'No data available to generate overall comment.';

    if (averageScore != 'N/A') {
      final percentValue = double.tryParse(averageScore.replaceAll('%', '')) ?? 0;
      overallGrade = _getGradeLetter(percentValue.toInt());
      overallInterpretation = _getGradeInterpretation(percentValue.toInt());
      overallComment = _generateOverallComment(percentValue.toInt());
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              widget.schoolName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'ACADEMIC REPORT CARD',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Student: ${widget.studentFullName}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Class: ${widget.studentClass}', style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'SUBJECT PERFORMANCE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Subject', 'Score', 'Grade', 'Performance', 'Teacher\'s Comment'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            data: subjects.map((subj) {
              return [
                subj['Subject_Name'],
                subj['Subject_Score'],
                subj['Subject_Grade'],
                subj['Grade_Interpretation'],
                subj['Teacher_Comment'],
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'OVERALL PERFORMANCE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Marks:'),
                    pw.Text('$studentTotalMarks / $teacherTotalMarks'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Average Score:'),
                    pw.Text(averageScore),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Overall Grade:'),
                    pw.Text('$overallGrade ($overallInterpretation)'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLASS TEACHER\'S COMMENT:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(overallComment),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('_______________________'),
                  pw.SizedBox(height: 4),
                  pw.Text('Class Teacher\'s Signature'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('_______________________'),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal\'s Signature'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Report generated on: ${DateTime.now().toString().split(' ')[0]}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  // Grade letter mapping based on score
  String _getGradeLetter(int score) {
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  // Interpretation based on grade
  String _getGradeInterpretation(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 50) return 'Pass';
    return 'Fail';
  }

  // Generate teacher comments based on score
  String _generateTeacherComment(int score) {
    if (score >= 80) return 'Excellent.';
    if (score >= 70) return 'Very good.';
    if (score >= 60) return 'Good work';
    if (score >= 50) return 'Passing grade';
    return 'Work harder';
  }

  // Generate overall comments based on average score
  String _generateOverallComment(int averageScore) {
    if (averageScore >= 80) {
      return 'Outstanding academic performance! ${widget.studentFullName}  to studies.';
    } else if (averageScore >= 70) {
      return '${widget.studentFullName} has  success.';
    } else if (averageScore >= 60) {
      return '${widget.studentFullName} ha subjects.';
    } else if (averageScore >= 50) {
      return '${widget.studentFullName} has  weaker subjects.';
    } else {
      return '${widget.studentFullName} needs   recommended.';
    }
  }

  // Get color based on grade
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.amber;
      case 'D': return Colors.orange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }
}