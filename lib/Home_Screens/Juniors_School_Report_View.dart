import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Compose the subject rows to match the FORM 2 list, filling in blanks for missing records
  List<Map<String, dynamic>> get subjectsForDisplay {
    // Map the fetched subjects to a map for easier lookup
    final Map<String, Map<String, dynamic>> subjectMap = {
      for (final subj in subjects)
        (subj['Subject_Name'] ?? '').toString().toUpperCase(): subj
    };

    if (widget.studentClass.trim().toUpperCase() == 'FORM 2') {
      return form2Subjects.map((subjectName) {
        final subj = subjectMap[subjectName] ?? {};
        // Calculate the grade using JCE grading key logic
        final score = subj['Subject_Marks'];
        String gradeLetter = '';
        String gradeInterpretation = '';
        if (score != null && score.toString().isNotEmpty) {
          final gradeInt = int.tryParse(score.toString()) ?? 0;
          if (gradeInt >= 85 && gradeInt <= 100) {
            gradeLetter = 'A';
            gradeInterpretation = 'EXCELLENT';
          } else if (gradeInt >= 70) {
            gradeLetter = 'B';
            gradeInterpretation = 'GOOD';
          } else if (gradeInt >= 60) {
            gradeLetter = 'C';
            gradeInterpretation = 'CREDIT';
          } else if (gradeInt >= 50) {
            gradeLetter = 'D';
            gradeInterpretation = 'PASS';
          } else {
            gradeLetter = 'F';
            gradeInterpretation = 'FAIL';
          }
        }
        return {
          'Subject_Name': subjectName,
          'Subject_Score': score?.toString() ?? '',
          'Subject_Grade': gradeLetter,
          'Grade_Interpretation': gradeInterpretation,
          'Class_Average': subj['Class_Average'] ?? '',
          'Position': subj['Position'] ?? '',
          'Teacher_Comment': subj['Teacher_Comment'] ?? '',
        };
      }).toList();
    } else {
      // fallback: just show whatever subjects are fetched
      return subjects.map((subj) {
        final score = subj['Subject_Marks'];
        String gradeLetter = '';
        String gradeInterpretation = '';
        if (score != null && score.toString().isNotEmpty) {
          final gradeInt = int.tryParse(score.toString()) ?? 0;
          if (gradeInt >= 85 && gradeInt <= 100) {
            gradeLetter = 'A';
            gradeInterpretation = 'EXCELLENT';
          } else if (gradeInt >= 70) {
            gradeLetter = 'B';
            gradeInterpretation = 'GOOD';
          } else if (gradeInt >= 60) {
            gradeLetter = 'C';
            gradeInterpretation = 'CREDIT';
          } else if (gradeInt >= 50) {
            gradeLetter = 'D';
            gradeInterpretation = 'PASS';
          } else {
            gradeLetter = 'F';
            gradeInterpretation = 'FAIL';
          }
        }
        return {
          'Subject_Name': subj['Subject_Name'] ?? '',
          'Subject_Score': score?.toString() ?? '',
          'Subject_Grade': gradeLetter,
          'Grade_Interpretation': gradeInterpretation,
          'Class_Average': subj['Class_Average'] ?? '',
          'Position': subj['Position'] ?? '',
          'Teacher_Comment': subj['Teacher_Comment'] ?? '',
        };
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                    ...subjectsForDisplay.map((subject) => TableRow(
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
                // REMARKS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Form Teacher's Remarks:",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(totalMarks?['Form_Teacher_Remarks'] ?? "N/A"),
                      const SizedBox(height: 5),
                      const Text(
                        "Head Teacher's Remarks:",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(totalMarks?['Head_Teacher_Remarks'] ?? "N/A"),
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