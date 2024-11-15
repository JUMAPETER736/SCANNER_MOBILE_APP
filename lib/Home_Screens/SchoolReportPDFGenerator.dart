import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SchoolReportPDFGenerator extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final int studentTotalMarks;
  final int teachersTotalMarks;

  // Constructor
  const SchoolReportPDFGenerator({
    Key? key,
    required this.studentName,
    required this.studentClass,
    required this.studentTotalMarks,
    required this.teachersTotalMarks,
  }) : super(key: key);

  // Function to determine the grade based on the score
  String getGrade(int score) {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      if (score >= 80) return 'A';
      if (score >= 70) return 'B';
      if (score >= 60) return 'C';
      if (score >= 50) return 'D';
      if (score >= 40) return 'E';
      return 'F';
    } else {
      if (score >= 85) return '1';
      if (score >= 75) return '2';
      if (score >= 70) return '3';
      if (score >= 65) return '4';
      if (score >= 60) return '5';
      if (score >= 55) return '6';
      if (score >= 50) return '7';
      if (score >= 40) return '8';
      return '9';
    }
  }

  // Function to determine the aggregate score based on all subjects for FORM 1 or FORM 2
  String getAggregateGrade(int studentTotalMarks) {
    if (studentTotalMarks >= 950 && studentTotalMarks <= 1100) return 'A';
    if (studentTotalMarks >= 750 && studentTotalMarks < 950) return 'B';
    if (studentTotalMarks >= 600 && studentTotalMarks < 750) return 'C';
    if (studentTotalMarks >= 500 && studentTotalMarks < 600) return 'D';
    if (studentTotalMarks >= 400 && studentTotalMarks < 500) return 'E';
    return 'F';
  }

  // Function to return the teacher's remark based on the score
  String getTeacherRemark(int score) {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      if (score >= 80) return 'EXCELLENT';
      if (score >= 70) return 'VERY GOOD';
      if (score >= 60) return 'GOOD';
      if (score >= 50) return 'AVERAGE';
      if (score >= 40) return 'NEED SUPPORT';
      return 'FAIL';
    } else {
      if (score >= 85) return 'DISTINCTION';
      if (score >= 80) return 'EXCELLENT';
      if (score >= 75) return 'VERY GOOD';
      if (score >= 70) return 'GOOD';
      if (score >= 65) return 'STRONG CREDIT';
      if (score >= 60) return 'WEAK CREDIT';
      if (score >= 50) return 'PASS';
      if (score >= 40) return 'NEED SUPPORT';
      return 'FAIL';
    }
  }

  // Function to get the Exam Reward based on studentTotalMarks
  String getExamReward() {
    if (studentTotalMarks >= 950 && studentTotalMarks <= 1100) return 'DISTINCTION';
    if (studentTotalMarks >= 750 && studentTotalMarks < 950) return 'STRONG CREDIT';
    if (studentTotalMarks >= 600 && studentTotalMarks < 750) return 'WEAK CREDIT';
    if (studentTotalMarks >= 500 && studentTotalMarks < 600) return 'PASS';
    if (studentTotalMarks >= 400 && studentTotalMarks < 500) return 'NEED SUPPORT';
    return 'FAIL';
  }

  // Function to get grade key ranges based on student class
  Widget getGradeKey() {
    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      return Wrap(
        alignment: WrapAlignment.start,
        children: [
          Text('GRADE KEY: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(width: 16),
          Text('80% - 100% = EXCELLENT', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('70% - 79% = VERY GOOD', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('60% - 69% = GOOD', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('50% - 59% = PASS', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('40% - 49% = NEED SUPPORT', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('0% - 39% = FAIL', style: TextStyle(fontSize: 14)),
        ],
      );
    } else {
      return Wrap(
        alignment: WrapAlignment.start,
        children: [
          Text('GRADE KEY: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(width: 16),
          Text('85% - 100% = 1', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('80% - 84% = 2', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('75% - 79% = 3', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('70% - 74% = 4', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('65% - 69% = 5', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('60% - 64% = 6', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('50% - 59% = 7', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('40% - 49% = 8', style: TextStyle(fontSize: 14)),
          SizedBox(width: 16),
          Text('0% - 39% = 9', style: TextStyle(fontSize: 14)),
        ],
      );
    }
  }

  // Added the requested sections
  Widget getTeacherRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(height: 16),
          Text("TEACHER'S COMMENT ___________________________________", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Text('CONDUCT:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('____________________________________________', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          SizedBox(height: 8),

          Row(
            children: [
              Text('SIGNATURE:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('__________________', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 6), // Adding some space between SIGNATURE and DATE
              Text('DATE:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('_______________', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          SizedBox(height: 16),
          Text("HEAD TEACHER'S REMARK: ________________________________", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Text('SIGNATURE:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('__________________', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 6), // Adding some space between SIGNATURE and DATE
              Text('DATE:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('_______________', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("NEXT TERM OPENS:", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('________________', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ]


    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCHOOL PROGRESS REPORT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              await _generateAndPrintPDF();
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Students_Details')
            .doc(studentClass)
            .collection('Student_Details')
            .doc(studentName)
            .collection('Student_Subjects')
            .get(),
        builder: (context, snapshot) {
          // Handling loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handling errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Handling case when no data is found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No grades found.'));
          }

          final subjectDocs = snapshot.data!.docs;

          // List of subject grades from Firestore data
          List<int> subjectGrades = subjectDocs.map<int>((doc) {
            final subjectData = doc.data() as Map<String, dynamic>;
            final grade = (subjectData['Subject_Grade'] is int)
                ? subjectData['Subject_Grade']
                : int.tryParse(subjectData['Subject_Grade'].toString()) ?? 0;
            return grade;
          }).toList();

          // Calculate the total marks by summing all grades
          int totalMarks = subjectGrades.reduce((a, b) => a + b);

          // Get the aggregate grade based on the total marks of all subjects
          String aggregateGrade = getAggregateGrade(totalMarks);

          // Output the total marks and aggregate grade for debugging
          print("AGGREGATE:$aggregateGrade");



          // Sorting grades to find the best six scores
          subjectGrades.sort((a, b) => b.compareTo(a));

          // Now, instead of adding the actual grades, we calculate the aggregate based on your grading scale
          int aggregate = subjectGrades
              .take(6) // Take the top 6 grades
              .map((grade) => int.parse(getGrade(grade))) // Convert each grade to its corresponding value
              .reduce((a, b) => a + b); // Sum the values

          // Output the aggregate
          print("AGGREGATE: $aggregate");

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('Students_Details')
                .doc(studentClass)
                .collection('Student_Details')
                .orderBy('Student_Total_Marks', descending: true)
                .get(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              int position = studentSnapshot.data!.docs
                  .indexWhere((doc) => doc.id == studentName) +
                  1;
              int totalStudents = studentSnapshot.data!.docs.length;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with student info
                    Center(
                      child: Text(
                        'STUDENT SCHOOL REPORT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STUDENT NAME: $studentName',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        Text(
                          'CLASS: $studentClass',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TERM:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('YEAR: ${DateTime.now().year}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('TOTAL MARKS: $studentTotalMarks/$teachersTotalMarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('ENROLLMENT: $totalStudents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('POSITION: $position', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Table to display subjects, scores, grades, and remarks
                    DataTable(
                      border: TableBorder.all(),
                      dataRowHeight: 40,
                      headingRowHeight: 50,
                      columnSpacing: 8,
                      columns: [
                        DataColumn(label: Text('SUBJECTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('GRADE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("TEACHER'S REMARK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SIGNATURE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                      rows: subjectDocs.map((subjectDoc) {
                        final subjectData = subjectDoc.data() as Map<String, dynamic>;

                        final subjectName = subjectData['Subject_Name'] ?? 'Unknown';
                        final subjectGrade = (subjectData['Subject_Grade'] is int)
                            ? subjectData['Subject_Grade']
                            : int.tryParse(subjectData['Subject_Grade']) ?? 0;

                        final scorePercentage = '$subjectGrade%';
                        final grade = getGrade(subjectGrade);
                        final teacherRemark = getTeacherRemark(subjectGrade);

                        return DataRow(cells: [
                          DataCell(Text(subjectName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(scorePercentage, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(grade, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(teacherRemark, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(" ", style: TextStyle(fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                    SizedBox(height: 16),

                    // Displaying aggregate and exam reward
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align items to the start
                      children: [
                        Text(
                          'AGGREGATE: $aggregate',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 24), // Adjust the width to control the space
                        Text(
                          'EXAM REWARD: ${getExamReward()}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Display GRADE KEY below AGGREGATE section
                    getGradeKey(),

                    // Display teacher's remark
                    getTeacherRemarksSection(),

                    SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }



  Future<void> _generateAndPrintPDF() async {
    final pdf = pw.Document();

    // Fetching the subjects dynamically from Firestore
    final subjectSnapshot = await FirebaseFirestore.instance
        .collection('Students_Details')
        .doc(studentClass)
        .collection('Student_Details')
        .doc(studentName)
        .collection('Student_Subjects')
        .get();

    if (subjectSnapshot.docs.isEmpty) {
      print('No subjects available');
      return;
    }

    // Fetch total students and determine position
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('Students_Details')
        .doc(studentClass)
        .collection('Student_Details')
        .orderBy('Student_Total_Marks', descending: true)
        .get();

    int totalStudents = studentsSnapshot.docs.length;
    int position = studentsSnapshot.docs
        .indexWhere((doc) => doc.id == studentName) + 1;

    // Map the subjects data into a list of maps
    final List<Map<String, dynamic>> subjects = subjectSnapshot.docs.map((doc) {
      final subjectData = doc.data() as Map<String, dynamic>;
      final subjectName = subjectData['Subject_Name'] ?? 'Unknown';
      final subjectGrade = (subjectData['Subject_Grade'] is int)
          ? subjectData['Subject_Grade']
          : (subjectData['Subject_Grade'] is String)
          ? int.tryParse(subjectData['Subject_Grade']) ?? 0
          : 0;

      final scorePercentage = '$subjectGrade%';
      final grade = getGrade(subjectGrade);
      final teacherRemark = getTeacherRemark(subjectGrade);

      return {
        'subject': subjectName,
        'score': scorePercentage,
        'grade': grade,
        'remark': teacherRemark,
        'signature': '', // Add any dynamic signature data if required
      };
    }).toList();

    pw.Widget getGradeKey() {
      if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
        return pw.Wrap(
          alignment: pw.WrapAlignment.start,
          children: [
            pw.Text('GRADE KEY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('80% - 100% = EXCELLENT', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('70% - 79% = VERY GOOD', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('60% - 69% = GOOD', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('50% - 59% = PASS', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('40% - 49% = NEED SUPPORT', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('0% - 39% = FAIL', style: pw.TextStyle(fontSize: 14)),
          ],
        );
      } else {
        return pw.Wrap(
          alignment: pw.WrapAlignment.start,
          children: [
            pw.Text('GRADE KEY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('85% - 100% = 1', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('80% - 84% = 2', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('75% - 79% = 3', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('70% - 74% = 4', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('65% - 69% = 5', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('60% - 64% = 6', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('50% - 59% = 7', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('40% - 49% = 8', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 16),
            pw.Text('0% - 39% = 9', style: pw.TextStyle(fontSize: 14)),
          ],
        );
      }
    }

    // Function to display teacher's remarks section as a pdf widget
    pw.Widget getTeacherRemarksSection() {
      return pw.Container(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 16),
            pw.Text("TEACHER'S COMMENT: _________________________________", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('CONDUCT:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('__________________________', style: pw.TextStyle(fontSize: 12))),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('SIGNATURE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('________________', style: pw.TextStyle(fontSize: 12))),
                pw.SizedBox(width: 6),
                pw.Text('DATE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('_______________', style: pw.TextStyle(fontSize: 12))),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text("HEAD TEACHER'S REMARK: ____________________________", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('SIGNATURE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('________________', style: pw.TextStyle(fontSize: 12))),
                pw.SizedBox(width: 6),
                pw.Text('DATE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('_______________', style: pw.TextStyle(fontSize: 12))),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                pw.Text("NEXT TERM OPENS:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text('________________', style: pw.TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
      );
    }




    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SCHOOL PROGRESS REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('STUDENT NAME: $studentName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('CLASS: $studentClass', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TERM:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('YEAR: ${DateTime.now().year}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('TOTAL MARKS: $studentTotalMarks/$teachersTotalMarks', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('ENROLLMENT: $totalStudents', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('POSITION: $position', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text("TEACHER'S COMMENT:________________", style: pw.TextStyle(fontSize: 14)),
                  pw.Text('CONDUCT', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('SIGNATURE: ___________________ DATE: ____________', style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 16),
                  pw.Text("HEAD TEACHER'S REMARK: __________________", style: pw.TextStyle(fontSize: 14)),
                  pw.Text("NEXT TERM OPENS: ________", style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table for subjects and details
              pw.Table(
                border: pw.TableBorder.all(width: 1), // Increased the vertical line size here
                columnWidths: {
                  0: pw.FlexColumnWidth(2), // Increased horizontal space for subjects column
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(3), // Adjusted for remarks
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SUBJECTS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SCORE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('GRADE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("TEACHER'S REMARK", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SIGNATURE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...subjects.map((subject) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['subject'], style: pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['score'], style: pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['grade'], style: pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['remark'], style: pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['signature'], style: pw.TextStyle(fontSize: 8))),
                      ],
                    );
                  }).toList(),
                ],
              ),


              pw.SizedBox(height: 20),




              // Displaying aggregate and exam reward
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text('AGGREGATE: $studentTotalMarks ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('EXAM REWARD: ${getExamReward()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],

              ),

              // Displaying grade key
              getGradeKey(),

              // Display teacher's remark
              getTeacherRemarksSection(),

              pw.Text('Generated on: ${DateTime.now()}'),
            ],
          );
        },
      ),
    );

    // Print or save the PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }


}