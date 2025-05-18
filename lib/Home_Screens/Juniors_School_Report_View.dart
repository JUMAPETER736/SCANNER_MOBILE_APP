

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add these for printing and PDF
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

      _initialized = true;
    }
  }


  Future<void> fetchStudentData() async {
    try {
      final String schoolName = widget.schoolName.trim();
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName.trim();

      // Fetch personal info
      final studentDoc = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      // Fetch current student subjects
      final subjectsSnap = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Student_Subjects')
          .get();

      final currentStudentSubjects = subjectsSnap.docs.map((doc) => doc.data()).toList();

      // Create enriched subjects
      List<Map<String, dynamic>> enrichedSubjects = [];

      for (var subject in currentStudentSubjects) {
        String subjectName = (subject['Subject_Name'] ?? '').toString();
        int subjectMark = int.tryParse(subject['Subject_Grade']?.toString() ?? '') ?? 0;

        // Fetch all students in class
        final studentsSnap = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .get();

        List<int> allMarks = [];

        for (var student in studentsSnap.docs) {
          final subjDoc = await _firestore
              .collection('Schools')
              .doc(schoolName)
              .collection('Classes')
              .doc(studentClass)
              .collection('Student_Details')
              .doc(student.id)
              .collection('Student_Subjects')
              .where('Subject_Name', isEqualTo: subjectName)
              .limit(1)
              .get();

          if (subjDoc.docs.isNotEmpty) {
            final markStr = subjDoc.docs.first.data()['Subject_Grade'];
            final mark = int.tryParse(markStr?.toString() ?? '');
            if (mark != null) {
              allMarks.add(mark);
            }
          }
        }

        // Calculate class average
        double avg = allMarks.isNotEmpty
            ? allMarks.reduce((a, b) => a + b) / allMarks.length
            : 0;

        // Sort descending to get position
        allMarks.sort((b, a) => a.compareTo(b)); // descending
        int position = allMarks.indexOf(subjectMark) + 1;

        // Generate teacher comment
        String comment = '';
        if (subjectMark >= 85) {
          comment = 'Excellent Work';
        } else if (subjectMark >= 70) {
          comment = 'Good Effort';
        } else if (subjectMark >= 60) {
          comment = 'Keep Improving';
        } else if (subjectMark >= 50) {
          comment = 'Needs Support';
        } else {
          comment = 'Work Harder';
        }

        enrichedSubjects.add({
          'Subject_Name': subjectName,
          'Subject_Score': subjectMark.toString(),
          'Subject_Grade': _getGradeLetter(subjectMark),
          'Grade_Interpretation': _getGradeInterpretation(subjectMark),
          'Class_Average': avg.toStringAsFixed(1),
          'Position': position.toString(),
          'Teacher_Comment': comment,
        });
      }

      setState(() {
        studentInfo = studentDoc.data() ?? {};
        subjects = enrichedSubjects;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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


  Future<void> _printReportAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                widget.schoolName.toUpperCase(),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("P.O. BOX 43, ${widget.schoolName.split(" ").first.toUpperCase()}"),
              pw.SizedBox(height: 8),
              pw.Text(
                "2024/25 END OF TERM ONE STUDENT'S PROGRESS REPORT",
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.Text(
                "NAME OF STUDENT: ${(studentInfo?['firstName'] ?? '').toString().toUpperCase()} ${(studentInfo?['lastName'] ?? '').toString().toUpperCase()}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("CLASS: ${studentInfo?['studentClass'] ?? 'N/A'}"),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  "SUBJECT",
                  "SCORE",
                  "GRADE",
                  "INTERPRETATION",
                  "CLASS AVG",
                  "POSITION",
                  "TEACHERS' COMMENTS"
                ],
                data: [
                  for (final subject in subjects)
                    [
                      subject['Subject_Name'] ?? "-",
                      subject['Subject_Score']?.toString() ?? "-",
                      subject['Subject_Grade'] ?? "-",
                      subject['Grade_Interpretation'] ?? "-",
                      subject['Class_Average']?.toString() ?? "-",
                      subject['Position']?.toString() ?? "-",
                      subject['Teacher_Comment'] ?? "-",
                    ]
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                      child: pw.Text("AGGREGATE POINTS: ${(totalMarks?['Aggregate_Grade'] ?? 'N/A').toString()}")),
                  pw.Expanded(
                      child: pw.Text("POSITION: ${(totalMarks?['Best_Six_Total_Points'] ?? 'N/A').toString()}")),
                  pw.Expanded(
                      child: pw.Text("OUT OF: ${(totalMarks?['Student_Total_Marks'] ?? 'N/A').toString()}")),
                  pw.Expanded(child: pw.Text("END RESULT: ${(totalMarks?['End_Result'] ?? 'JCE').toString()}")),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text("JCE GRADING KEY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ["Mark Range per 100", "Grade", "Interpretation"],
                data: [
                  ["85 - 100", "A", "EXCELLENT"],
                  ["70 - 84", "B", "GOOD"],
                  ["60 - 69", "C", "CREDIT"],
                  ["50 - 59", "D", "PASS"],
                  ["0 - 49", "F", "FAIL"],
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Form Teacher's Remarks: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Text(totalMarks?['Form_Teacher_Remarks'] ?? "N/A")),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Head Teacher's Remarks: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Text(totalMarks?['Head_Teacher_Remarks'] ?? "N/A")),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text("Fees for next term : ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(totalMarks?['Fees'] ?? 'MK ###,###.##'),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text("Next term begins on : ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(totalMarks?['Next_Term_Begins'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(''),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _printReportAsPdf,
            icon: const Icon(Icons.print, color: Colors.black),
            tooltip: 'Print PDF',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header Section: School Info
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        widget.schoolName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        "P.O. BOX 43, ${widget.schoolName.split(" ").first.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "2024/25 END OF TERM ONE STUDENT'S PROGRESS REPORT",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1.2),
                // Name and Class Info Row
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "NAME OF STUDENT: ${studentInfo?['firstName'] ?? ''} ${studentInfo?['lastName'] ?? ''}".toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          "CLASS: ", // Leave class blank
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // SUBJECTS TABLE
                Table(
                  border: TableBorder.all(width: 1.0, color: Colors.black),
                  columnWidths: const {
                    0: FlexColumnWidth(2),   // SUBJECT
                    1: FlexColumnWidth(1),   // SCORE
                    2: FlexColumnWidth(1),   // GRADE
                    3: FlexColumnWidth(2),   // GRADE INTERPRETATION
                    4: FlexColumnWidth(1),   // CLASS AVG
                    5: FlexColumnWidth(1),   // POSITION
                    6: FlexColumnWidth(2),   // TEACHERS' COMMENTS
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE5E5E5)),
                      children: [
                        cell("SUBJECT", true),
                        cell("SCORE", true),
                        cell("GRADE", true),
                        cell("INTERPRETATION", true),
                        cell("CLASS AVG", true),
                        cell("POSITION", true),
                        cell("TEACHERS' COMMENTS", true),
                      ],
                    ),
                    ...subjects.map((subject) => TableRow(
                      children: [
                        cell(subject['Subject_Name'] ?? "-"),
                        cell(subject['Subject_Score']?.toString() ?? "-"),
                        cell(subject['Subject_Grade']?.toString() ?? "-"),
                        cell(subject['Grade_Interpretation']?.toString() ?? "-"),
                        cell(subject['Class_Average']?.toString() ?? "-"),
                        cell(subject['Position']?.toString() ?? "-"),
                        cell(subject['Teacher_Comment'] ?? "-"),
                      ],
                    )),
                  ],
                ),
                // AGGREGATE POINTS, POSITION, END RESULT
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "GRADE: ${(totalMarks?['Aggregate_Grade'] ?? 'N/A').toString()}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "POSITION: ${(totalMarks?['Best_Six_Total_Points'] ?? 'N/A').toString()}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "OUT OF: ${(totalMarks?['Student_Total_Marks'] ?? 'N/A').toString()}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "END RESULT: ${(totalMarks?['End_Result'] ?? 'JCE')}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                // JCE GRADING KEY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        "JCE GRADING KEY",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      jceGradingKeyTable(),
                    ],
                  ),
                ),
                // REMARKS (left aligned in Row)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Form Teacher's Remarks: ",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Expanded(
                            child: Text(totalMarks?['Form_Teacher_Remarks'] ?? "N/A"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Head Teacher's Remarks: ",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Expanded(
                            child: Text(totalMarks?['Head_Teacher_Remarks'] ?? "N/A"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // FEES & NEXT TERM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("Fees for next term :  ",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(totalMarks?['Fees'] ?? 'MK ###,###.##'),
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Next term begins on :  ",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(totalMarks?['Next_Term_Begins'] ?? 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget cell(String text, [bool header = false]) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        fontWeight: header ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    ),
  );

  Widget jceGradingKeyTable() {
    // JCE grading scale
    return Table(
      border: TableBorder.all(width: 0.8, color: Colors.black),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          children: [
            cell("Mark Range per 100", true),
            cell("Grade", true),
            cell("Interpretation", true),
          ],
        ),
        TableRow(
          children: [cell("85 - 100"), cell("A"), cell("EXCELLENT")],
        ),
        TableRow(
          children: [cell("70 - 84"), cell("B"), cell("GOOD")],
        ),
        TableRow(
          children: [cell("60 - 69"), cell("C"), cell("CREDIT")],
        ),
        TableRow(
          children: [cell("50 - 59"), cell("D"), cell("PASS")],
        ),
        TableRow(
          children: [cell("0 - 49"),  cell("F"), cell("FAIL")],
        ),
      ],
    );
  }
}