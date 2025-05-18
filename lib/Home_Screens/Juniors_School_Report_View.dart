import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class Juniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Report_View({
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() => _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> studentInfo = {};
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  bool isLoading = true;
  String? _errorMessage;

  static const List<String> JuniorsSubjects = [
    'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY',
    'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'HISTORY',
    'HOME ECONOMICS', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS',
    'SOCIAL STUDIES',
  ];

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

      final schoolName = widget.schoolName.trim();
      final studentClass = widget.studentClass.trim().toUpperCase();
      final studentFullName = widget.studentFullName.trim();

      // 1. Fetch or create personal information
      final personalInfoRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Personal_Information')
          .doc('Registered_Information');

      DocumentSnapshot personalInfoSnapshot = await personalInfoRef.get();

      if (!personalInfoSnapshot.exists) {
        await personalInfoRef.set({
          'firstName': studentFullName.split(' ').first,
          'lastName': studentFullName.split(' ').last,
          'class': studentClass,

        });
      }

      // 2. Fetch or create total marks
      final totalMarksRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('TOTAL_MARKS')
          .doc('Marks');

      DocumentSnapshot totalMarksSnapshot = await totalMarksRef.get();

      if (!totalMarksSnapshot.exists) {
        await totalMarksRef.set({
          'Student_Total_Marks': '0',
          'Teacher_Total_Marks': '0',
          'Position': 'N/A',
          'Total_Students': '0',

        });
      }

      // 3. Process subjects
      final subjectsRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Student_Subjects');

      QuerySnapshot subjectsSnapshot = await subjectsRef.get();
      List<Map<String, dynamic>> subjectsData = [];

      if (subjectsSnapshot.docs.isEmpty) {
        // Create default subjects if none exist
        for (String subject in JuniorsSubjects) {
          await subjectsRef.add({
            'Subject_Name': subject,
            'Subject_Grade': '0',

          });
        }
      }

      // Get class students for position calculation
      QuerySnapshot classStudentsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .get();

      // Process all subjects
      for (var subjectDoc in (await subjectsRef.get()).docs) {
        Map<String, dynamic> subjectData = subjectDoc.data() as Map<String, dynamic>;
        String subjectName = subjectData['Subject_Name']?.toString() ?? 'Unknown';
        int subjectMark = int.tryParse(subjectData['Subject_Grade']?.toString() ?? '0') ?? 0;

        // Calculate class average and position
        List<int> allMarks = [];
        for (var studentDoc in classStudentsSnapshot.docs) {
          QuerySnapshot studentSubjects = await _firestore
              .collection('Schools')
              .doc(schoolName)
              .collection('Classes')
              .doc(studentClass)
              .collection('Student_Details')
              .doc(studentDoc.id)
              .collection('Student_Subjects')
              .where('Subject_Name', isEqualTo: subjectName)
              .get();

          if (studentSubjects.docs.isNotEmpty) {
            int mark = int.tryParse(studentSubjects.docs.first['Subject_Grade']?.toString() ?? '0') ?? 0;
            allMarks.add(mark);
          }
        }

        double classAverage = allMarks.isNotEmpty ? allMarks.reduce((a, b) => a + b) / allMarks.length : 0;
        allMarks.sort((b, a) => a.compareTo(b));
        int position = allMarks.indexOf(subjectMark) + 1;

        subjectsData.add({
          'Subject_Name': subjectName,
          'Subject_Score': subjectMark.toString(),
          'Subject_Grade': _getGradeLetter(subjectMark),
          'Grade_Interpretation': _getGradeInterpretation(subjectMark),
          'Class_Average': classAverage.toStringAsFixed(1),
          'Position': position.toString(),
          'Teacher_Comment': _generateTeacherComment(subjectMark),
        });
      }

      // Update totals
      int studentTotal = subjectsData.fold(0, (sum, subject) => sum + int.parse(subject['Subject_Score']));
      int teacherTotal = subjectsData.length * 100; // Assuming max 100 per subject

      await totalMarksRef.update({
        'Student_Total_Marks': studentTotal.toString(),
        'Teacher_Total_Marks': teacherTotal.toString(),
        'Average_Score': '${(studentTotal / teacherTotal * 100).toStringAsFixed(1)}%',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get updated totals
      DocumentSnapshot updatedTotalMarks = await totalMarksRef.get();

      setState(() {
        studentInfo = personalInfoSnapshot.data() as Map<String, dynamic>? ?? {};
        subjects = subjectsData;
        totalMarks = updatedTotalMarks.data() as Map<String, dynamic>? ?? {};
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // ... (keep your existing grade calculation methods: _generateTeacherComment, _getGradeLetter, _getGradeInterpretation)

  Future<void> _printDocument() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(widget.schoolName, style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text('Student: ${widget.studentFullName}'),
              pw.Text('Class: ${widget.studentClass}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['SUBJECT', 'MARK', 'GRADE', 'INTERPRETATION', 'AVG', 'POS', 'COMMENT'],
                  ...subjects.map((s) => [
                    s['Subject_Name'],
                    s['Subject_Score'],
                    s['Subject_Grade'],
                    s['Grade_Interpretation'],
                    s['Class_Average'],
                    s['Position'],
                    s['Teacher_Comment'],
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('TOTAL MARKS: ${totalMarks['Student_Total_Marks']} / ${totalMarks['Teacher_Total_Marks']}'),
              pw.Text('AVERAGE: ${totalMarks['Average_Score']}'),
              pw.Text('CLASS POSITION: ${totalMarks['Position']} OUT OF: ${totalMarks['Total_Students']}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
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
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(widget.schoolName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Student: ${widget.studentFullName}'),
                      Text('Class: ${widget.studentClass}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACADEMIC PERFORMANCE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('SUBJECT')),
                            DataColumn(label: Text('MARK'), numeric: true),
                            DataColumn(label: Text('GRADE')),
                            DataColumn(label: Text('INTERPRETATION')),
                            DataColumn(label: Text('AVG'), numeric: true),
                            DataColumn(label: Text('POS'), numeric: true),
                            DataColumn(label: Text('COMMENT')),
                          ],
                          rows: subjects.map((subject) => DataRow(
                            cells: [
                              DataCell(Text(subject['Subject_Name'])),
                              DataCell(Text(subject['Subject_Score'])),
                              DataCell(Text(subject['Subject_Grade'])),
                              DataCell(Text(subject['Grade_Interpretation'])),
                              DataCell(Text(subject['Class_Average'])),
                              DataCell(Text(subject['Position'])),
                              DataCell(Text(subject['Teacher_Comment'])),
                            ],
                          )).toList(),
                        ),
                      ),
                      SizedBox(height: 20),
                      if (totalMarks.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL MARKS: ${totalMarks['Student_Total_Marks']} / ${totalMarks['Teacher_Total_Marks']}'),
                            Text('AVERAGE: ${totalMarks['Average_Score']}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CLASS POSITION: ${totalMarks['Position']}'),
                            Text('OUT OF: ${totalMarks['Total_Students']}'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


String _getGradeLetter(int mark) {
  if (mark >= 90) return 'A+';
  if (mark >= 80) return 'A';
  if (mark >= 70) return 'B';
  if (mark >= 60) return 'C';
  if (mark >= 50) return 'D';
  if (mark >= 40) return 'E';
  return 'F';
}

String _getGradeInterpretation(int mark) {
  if (mark >= 90) return 'Excellent';
  if (mark >= 80) return 'Very Good';
  if (mark >= 70) return 'Good';
  if (mark >= 60) return 'Average';
  if (mark >= 50) return 'Fair';
  if (mark >= 40) return 'Poor';
  return 'Fail';
}

String _generateTeacherComment(int mark) {
  if (mark >= 90) return 'Outstanding performance!';
  if (mark >= 80) return 'Keep up the great work!';
  if (mark >= 70) return 'Well done!';
  if (mark >= 60) return 'Satisfactory effort.';
  if (mark >= 50) return 'Needs improvement.';
  if (mark >= 40) return 'Struggling; needs support.';
  return 'Serious improvement needed.';
}
