import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add these for printing and PDF
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

  Map<String, dynamic>? studentInfo;
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic>? totalMarks;
  bool isLoading = true;

  // List of FORM 2 Subjects
  static const List<String> form2Subjects = [
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

  @override
  void initState() {
    super.initState();
    fetchStudentData();
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

      // Fetch subjects
      final subjectsSnap = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Student_Subjects')
          .get();

      // Fetch TOTAL_MARKS
      final marksDoc = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get();

      setState(() {
        studentInfo = studentDoc.data() ?? {};
        subjects = subjectsSnap.docs.map((doc) => doc.data()).toList();
        totalMarks = marksDoc.data() ?? {};
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

  List<Map<String, dynamic>> get subjectsForDisplay {
    final Map<String, Map<String, dynamic>> subjectMap = {
      for (final subj in subjects)
        (subj['Subject_Name'] ?? '').toString().toUpperCase(): subj
    };

    int mscePoint(int gradeInt) {
      if (gradeInt >= 85) {
        return 1;
      } else if (gradeInt >= 80) {
        return 2;
      } else if (gradeInt >= 75) {
        return 3;
      } else if (gradeInt >= 70) {
        return 4;
      } else if (gradeInt >= 65) {
        return 5;
      } else if (gradeInt >= 60) {
        return 6;
      } else if (gradeInt >= 55) {
        return 7;
      } else if (gradeInt >= 50) {
        return 8;
      } else {
        return 9;
      }
    }

    String msceInterpretation(int point) {
      switch (point) {
        case 1:
        case 2:
          return "Distinction";
        case 3:
        case 4:
          return "Strong Credit";
        case 5:
        case 6:
          return "Credit";
        case 7:
          return "Weak Credit";
        case 8:
          return "Pass";
        case 9:
        default:
          return "Weak Pass";
      }
    }

    if (widget.studentClass.trim().toUpperCase() == 'FORM 2') {
      return form2Subjects.map((subjectName) {
        final subj = subjectMap[subjectName] ?? {};
        final score = subj['Subject_Marks'];
        int? points;
        String interpretation = "";
        if (score != null && score.toString().isNotEmpty) {
          final gradeInt = int.tryParse(score.toString()) ?? 0;
          points = mscePoint(gradeInt);
          interpretation = msceInterpretation(points);
        }
        return {
          'Subject_Name': subjectName,
          'Subject_Score': score?.toString() ?? '',
          'Subject_Points': points?.toString() ?? '',
          'Interpretation': interpretation,
          'Class_Average': subj['Class_Average'] ?? '',
          'Position': subj['Position'] ?? '',
          'Teacher_Comment': subj['Teacher_Comment'] ?? '',
        };
      }).toList();
    } else {
      return subjects.map((subj) {
        final score = subj['Subject_Marks'];
        int? points;
        String interpretation = "";
        if (score != null && score.toString().isNotEmpty) {
          final gradeInt = int.tryParse(score.toString()) ?? 0;
          points = mscePoint(gradeInt);
          interpretation = msceInterpretation(points);
        }
        return {
          'Subject_Name': subj['Subject_Name'] ?? '',
          'Subject_Score': score?.toString() ?? '',
          'Subject_Points': points?.toString() ?? '',
          'Interpretation': interpretation,
          'Class_Average': subj['Class_Average'] ?? '',
          'Position': subj['Position'] ?? '',
          'Teacher_Comment': subj['Teacher_Comment'] ?? '',
        };
      }).toList();
    }
  }

  // PDF generation logic
  Future<void> _printReportAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(widget.schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text("P.O. BOX 43, ${widget.schoolName.split(" ").first.toUpperCase()}"),
              pw.SizedBox(height: 8),
              pw.Text("2024/25 END OF TERM ONE STUDENT'S PROGRESS REPORT", style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text("NAME OF STUDENT: ${(studentInfo?['firstName'] ?? '')} ${(studentInfo?['lastName'] ?? '')}".toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("CLASS: "),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ["SUBJECT", "SCORE", "POINTS", "INTERPRETATION", "CLASS AVG", "POSITION", "TEACHERS' COMMENTS"],
                data: [
                  for (final subject in subjectsForDisplay)
                    [
                      subject['Subject_Name'] ?? "-",
                      subject['Subject_Score'] ?? "-",
                      subject['Subject_Points'] ?? "-",
                      subject['Interpretation'] ?? "-",
                      subject['Class_Average'] ?? "-",
                      subject['Position'] ?? "-",
                      subject['Teacher_Comment'] ?? "-",
                    ]
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text("AGGREGATE POINTS: ${(totalMarks?['Aggregate_Grade'] ?? 'N/A').toString()}")),
                  pw.Expanded(child: pw.Text("POSITION: ${(totalMarks?['Best_Six_Total_Points'] ?? 'N/A').toString()}")),
                  pw.Expanded(child: pw.Text("OUT OF: ${(totalMarks?['Student_Total_Marks'] ?? 'N/A').toString()}")),
                  pw.Expanded(child: pw.Text("END RESULT: ${(totalMarks?['End_Result'] ?? 'MSCE')}")),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text("MSCE GRADING KEY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ["Mark Range per 100", "Points", "Interpretation"],
                data: [
                  ["85 - 100", "1", "Distinction"],
                  ["80 - 84", "2", "Distinction"],
                  ["75 - 79", "3", "Strong Credit"],
                  ["70 - 74", "4", "Strong Credit"],
                  ["65 - 69", "5", "Credit"],
                  ["60 - 64", "6", "Credit"],
                  ["55 - 59", "7", "Weak Credit"],
                  ["50 - 54", "8", "Pass"],
                  ["0 - 49",  "9", "Weak Pass"],
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
                    2: FlexColumnWidth(1),   // POINTS
                    3: FlexColumnWidth(2),   // INTERPRETATION
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
                        cell("POINTS", true),
                        cell("INTERPRETATION", true),
                        cell("CLASS AVG", true),
                        cell("POSITION", true),
                        cell("TEACHERS' COMMENTS", true),
                      ],
                    ),
                    ...subjectsForDisplay.map((subject) => TableRow(
                      children: [
                        cell(subject['Subject_Name'] ?? "-"),
                        cell(subject['Subject_Score']?.toString() ?? "-"),
                        cell(subject['Subject_Points']?.toString() ?? "-"),
                        cell(subject['Interpretation']?.toString() ?? "-"),
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
                          "AGGREGATE POINTS: ${(totalMarks?['Aggregate_Grade'] ?? 'N/A').toString()}",
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
                          "END RESULT: ${(totalMarks?['End_Result'] ?? 'MSCE')}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                // MSCE GRADING KEY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        "MSCE GRADING KEY",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      msceGradingKeyTable(),
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

  Widget msceGradingKeyTable() {
    // MSCE grading scale
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
            cell("Points", true),
            cell("Interpretation", true),
          ],
        ),
        TableRow(
          children: [cell("85 - 100"), cell("1"), cell("Distinction")],
        ),
        TableRow(
          children: [cell("80 - 84"), cell("2"), cell("Distinction")],
        ),
        TableRow(
          children: [cell("75 - 79"), cell("3"), cell("Strong Credit")],
        ),
        TableRow(
          children: [cell("70 - 74"), cell("4"), cell("Strong Credit")],
        ),
        TableRow(
          children: [cell("65 - 69"), cell("5"), cell("Credit")],
        ),
        TableRow(
          children: [cell("60 - 64"), cell("6"), cell("Credit")],
        ),
        TableRow(
          children: [cell("55 - 59"), cell("7"), cell("Weak Credit")],
        ),
        TableRow(
          children: [cell("50 - 54"), cell("8"), cell("Pass")],
        ),
        TableRow(
          children: [cell("0 - 49"),  cell("9"), cell("Weak Pass")],
        ),
      ],
    );
  }
}