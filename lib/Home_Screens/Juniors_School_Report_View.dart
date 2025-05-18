import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic>? studentInfo;
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic>? totalMarks;
  bool isLoading = true;
  String? _errorMessage;

  // List of FORM 2 Subjects
  static const List<String> JuniorsSubjects = [
    'AGRICULTURE',
    'BIBLE KNOWLEDGE',
    'BIOLOGY',
    'CHEMISTRY',
    'CHICHEWA',
    'COMPUTER SCIENCE',
    'ENGLISH',
    'HISTORY',
    'HOME ECONOMICS',
    'LIFE SKILLS',
    'MATHEMATICS',
    'PHYSICS',
    'SOCIAL STUDIES',
  ];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      fetchStudentData();
      _initialized = true;
    }
  }

  Future<void> fetchStudentData() async {
    try {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      final String schoolName = widget.schoolName.trim();
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName.trim();

      // 1. Fetch personal information
      DocumentSnapshot personalInfoSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      Map<String, dynamic>? personalInfo = personalInfoSnapshot.exists
          ? personalInfoSnapshot.data() as Map<String, dynamic>
          : null;

      // 2. Fetch total marks
      DocumentSnapshot totalMarksSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get();

      Map<String, dynamic>? studentTotalMarks = totalMarksSnapshot.exists
          ? totalMarksSnapshot.data() as Map<String, dynamic>
          : null;

      // Make sure we have the expected fields in the total marks
      if (studentTotalMarks != null) {
        // Add computed fields if they don't exist
        if (!studentTotalMarks.containsKey('Total_Score')) {
          studentTotalMarks['Total_Score'] = studentTotalMarks['Student_Total_Marks'] ?? '0';
        }

        // Calculate average if needed
        if (!studentTotalMarks.containsKey('Average_Score')) {
          int studentTotal = int.tryParse(studentTotalMarks['Student_Total_Marks'] ?? '0') ?? 0;
          int teacherTotal = int.tryParse(studentTotalMarks['Teacher_Total_Marks'] ?? '0') ?? 0;
          double averagePercentage = teacherTotal > 0 ? (studentTotal / teacherTotal) * 100 : 0;
          studentTotalMarks['Average_Score'] = averagePercentage.toStringAsFixed(1) + '%';
        }
      }

      // 3. Fetch all subject documents
      QuerySnapshot subjectsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Student_Subjects')
          .get();

      List<Map<String, dynamic>> subjectsData = [];

      // Process each subject
      for (var subjectDoc in subjectsSnapshot.docs) {
        Map<String, dynamic> subjectData = subjectDoc.data() as Map<String, dynamic>;
        String subjectName = (subjectData['Subject_Name'] ?? '').toString();
        String subjectMarkStr = (subjectData['Subject_Grade'] ?? '0').toString();
        int subjectMark = int.tryParse(subjectMarkStr) ?? 0;

        // Fetch all students in class to calculate average and position
        QuerySnapshot classStudentsSnapshot = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .get();

        List<int> allMarks = [];

        // Get marks for this subject from all students
        for (var studentDoc in classStudentsSnapshot.docs) {
          QuerySnapshot studentSubjectSnapshot = await _firestore
              .collection('Schools')
              .doc(schoolName)
              .collection('Classes')
              .doc(studentClass)
              .collection('Student_Details')
              .doc(studentDoc.id)
              .collection('Student_Subjects')
              .where('Subject_Name', isEqualTo: subjectName)
              .limit(1)
              .get();

          if (studentSubjectSnapshot.docs.isNotEmpty) {
            String markStr = (studentSubjectSnapshot.docs.first.data() as Map<String, dynamic>)['Subject_Grade']?.toString() ?? '0';
            int mark = int.tryParse(markStr) ?? 0;
            allMarks.add(mark);
          }
        }

        // Calculate class average
        double classAverage = allMarks.isNotEmpty
            ? allMarks.reduce((a, b) => a + b) / allMarks.length
            : 0;

        // Sort marks to find position
        allMarks.sort((b, a) => a.compareTo(b)); // descending order
        int position = allMarks.indexOf(subjectMark) + 1;

        // Add enriched subject data
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

      // Update state with fetched data
      setState(() {
        studentInfo = personalInfo;
        subjects = subjectsData;
        totalMarks = studentTotalMarks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _errorMessage = 'Error fetching data: ${e.toString()}';
      });
    }
  }

  String _generateTeacherComment(int score) {
    if (score >= 85) return 'Excellent Work';
    if (score >= 70) return 'Good Effort';
    if (score >= 60) return 'Keep Improving';
    if (score >= 50) return 'Needs Support';
    return 'Work Harder';
  }

  String _getGradeLetter(int score) {
    if (score >= 85) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  String _getGradeInterpretation(int score) {
    if (score >= 85) return 'EXCELLENT';
    if (score >= 70) return 'GOOD';
    if (score >= 60) return 'CREDIT';
    if (score >= 50) return 'PASS';
    return 'FAIL';
  }

  Future<void> _printDocument() async {
    // TODO: Implement PDF generation and printing functionality
    // You can use the printing package here
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if there is one
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        setState(() {
          _errorMessage = null; // Clear the error after showing
        });
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
          : studentInfo == null
          ? Center(child: Text('No student information found'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.schoolName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Student: ${widget.studentFullName}',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Class: ${widget.studentClass}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Subjects Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACADEMIC PERFORMANCE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Table header
                    Table(
                      border: TableBorder.all(),
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: [
                            tableCellHeader('SUBJECT'),
                            tableCellHeader('MARK'),
                            tableCellHeader('GRADE'),
                            tableCellHeader('INTERPRETATION'),
                            tableCellHeader('AVG'),
                            tableCellHeader('POS'),
                            tableCellHeader('COMMENT'),
                          ],
                        ),
                        ...subjects.map((subject) => TableRow(
                          children: [
                            tableCell(subject['Subject_Name']),
                            tableCell(subject['Subject_Score']),
                            tableCell(subject['Subject_Grade']),
                            tableCell(subject['Grade_Interpretation']),
                            tableCell(subject['Class_Average']),
                            tableCell(subject['Position']),
                            tableCell(subject['Teacher_Comment']),
                          ],
                        )).toList(),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Total marks and position
                    if (totalMarks != null)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL MARKS: ${totalMarks!['Student_Total_Marks'] ?? 'N/A'} / ${totalMarks!['Teacher_Total_Marks'] ?? 'N/A'}'),
                              Text('AVERAGE: ${totalMarks!['Average_Score'] ?? 'N/A'}'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CLASS POSITION: ${totalMarks!['Position'] ?? 'N/A'}'),
                              Text('OUT OF: ${totalMarks!['Total_Students'] ?? 'N/A'}'),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tableCellHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}