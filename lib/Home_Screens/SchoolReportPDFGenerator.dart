
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';



class SchoolReportPDFGenerator extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final int studentTotalMarks; // Define studentTotalMarks variable
  final int teachersTotalMarks; // Define teachersTotalMarks variable


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
      if (score >= 80) return '1';
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

  // Function to return the teacher's remark based on the score
  String getTeacherRemark(int score) {

    if (studentClass == 'FORM 1' || studentClass == 'FORM 2') {
      // Remarks for FORM 1 & 2
      if (score >= 80) return 'EXCELLENT';
      if (score >= 70) return 'VERY GOOD';
      if (score >= 60) return 'GOOD';
      if (score >= 50) return 'AVERAGE';
      if (score >= 40) return 'NEED SUPPORT';
      return 'FAIL';

    } else {
      // Remarks for FORM 3 & 4
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

  const SchoolReportPDFGenerator(

      {Key? key,
        required this.studentName,
        required this.studentClass,
        required this.studentTotalMarks,
        required this.teachersTotalMarks
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCHOOL PROGRESS REPORT',
          style: TextStyle(fontWeight: FontWeight.bold), // Make the title bold
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No grades found.'));
          }

          final subjectDocs = snapshot.data!.docs;

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

              // Calculate position
              int position = studentSnapshot.data!.docs
                  .indexWhere((doc) => doc.id == studentName) + 1; // +1 to make it 1-based index

              int totalStudents = studentSnapshot.data!.docs.length;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Text('YEAR: ${DateTime.now().year}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Display current year
                        Text('TOTAL MARKS: $studentTotalMarks/$teachersTotalMarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('ENROLLMENT: $totalStudents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('POSITION: $position', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    DataTable(
                      border: TableBorder.all(),
                      dataRowHeight: 40,
                      headingRowHeight: 50,
                      columnSpacing: 8,
                      columns: [
                        DataColumn(label: Text('SUBJECTS', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SCORE', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('GRADE', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("TEACHER'S REMARK", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SIGNATURE', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: subjectDocs.map((subjectDoc) {
                        final subjectData = subjectDoc.data() as Map<String, dynamic>;

                        final subjectName = subjectData['Subject_Name'] ?? 'Unknown';
                        final subjectGrade = (subjectData['Subject_Grade'] is int)
                            ? subjectData['Subject_Grade']
                            : (subjectData['Subject_Grade'] is String)
                            ? int.tryParse(subjectData['Subject_Grade']) ?? 0
                            : 0;

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
                  pw.Text('TERM:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('YEAR: ${DateTime.now().year}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('TOTAL MARKS: $studentTotalMarks/$teachersTotalMarks', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('ENROLLMENT: $totalStudents', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('POSITION: $position', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table for subjects and details
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SUBJECTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SCORE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('GRADE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("TEACHER'S REMARK", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('SIGNATURE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...subjects.map((subject) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['subject'])),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['score'])),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['grade'])),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['remark'])),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(subject['signature'])),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),
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
