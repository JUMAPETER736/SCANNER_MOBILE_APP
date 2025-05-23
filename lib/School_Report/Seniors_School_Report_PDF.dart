import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class Seniors_School_Report_PDF {
  final String? schoolName;
  final String? schoolAddress;
  final String? schoolPhone;
  final String? schoolEmail;
  final String? schoolAccount;
  final String? nextTermDate;
  final String? formTeacherRemarks;
  final String? headTeacherRemarks;
  final String studentFullName;
  final String studentClass;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic> subjectStats;
  final Map<String, int> subjectPositions;
  final Map<String, int> totalStudentsPerSubject;
  final int aggregatePoints;
  final int aggregatePosition;
  final int totalStudents;
  final int studentTotalMarks;
  final int teacherTotalMarks;

  Seniors_School_Report_PDF({
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolPhone,
    required this.schoolEmail,
    required this.schoolAccount,
    required this.nextTermDate,
    required this.formTeacherRemarks,
    required this.headTeacherRemarks,
    required this.studentFullName,
    required this.studentClass,
    required this.subjects,
    required this.subjectStats,
    required this.subjectPositions,
    required this.totalStudentsPerSubject,
    required this.aggregatePoints,
    required this.aggregatePosition,
    required this.totalStudents,
    required this.studentTotalMarks,
    required this.teacherTotalMarks,
  });

  String _getGrade(int score) {
    if (score >= 90) return '1';
    if (score >= 80) return '2';
    if (score >= 75) return '3';
    if (score >= 70) return '4';
    if (score >= 65) return '5';
    if (score >= 60) return '6';
    if (score >= 55) return '7';
    if (score >= 50) return '8';
    return '9';
  }

  String _getRemark(String grade) {
    switch (grade) {
      case '1': return 'Distinction';
      case '2': return 'Distinction';
      case '3': return 'Strong Credit';
      case '4': return 'Strong Credit';
      case '5': return 'Credit';
      case '6': return 'Weak Credit';
      case '7': return 'Pass';
      case '8': return 'Weak Pass';
      default: return 'Fail';
    }
  }

  String _getPoints(String grade) {
    switch (grade) {
      case '1': return '1';
      case '2': return '2';
      case '3': return '3';
      case '4': return '4';
      case '5': return '5';
      case '6': return '6';
      case '7': return '7';
      case '8': return '8';
      default: return '9';
    }
  }

  Future<void> generateAndPrint() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // School Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName ?? 'UNKWON SECONDARY SCHOOL',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      schoolAddress ?? 'P.O. BOX 47, LILONGWE',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Tel: ${schoolPhone ?? '(+265) # ### ### ### or (+265) # ### ### ###'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Email: ${schoolEmail ?? 'secondaryschool@gmail.com'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      '${DateFormat('yyyy').format(DateTime.now())}/${DateFormat('yy').format(DateTime.now().add(Duration(days: 365)))} '
                          '$studentClass END OF TERM ONE STUDENT\'S PROGRESS REPORT',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Student Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NAME OF STUDENT: $studentFullName'),
                  pw.Text('CLASS: $studentClass'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Report Table
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['SUBJECT', 'MARKS %', 'POINTS', 'CLASS AVERAGE', 'POSITION', 'OUT OF', 'TEACHERS\' COMMENTS'],
                data: subjects.map((subj) {
                  final subjectName = subj['subject'] ?? 'Unknown';
                  final score = subj['score'] as int? ?? 0;
                  final grade = _getGrade(score);
                  final remark = _getRemark(grade);
                  final points = _getPoints(grade);
                  final subjectStat = subjectStats[subjectName];
                  final avg = subjectStat != null ? subjectStat['average'] as int : 0;
                  final subjectPosition = subjectPositions[subjectName] ?? 0;
                  final totalStudentsForSubject = totalStudentsPerSubject[subjectName] ?? 0;

                  return [
                    subjectName,
                    score.toString(),
                    points,
                    avg.toString(),
                    subjectPosition.toString(),
                    totalStudentsForSubject.toString(),
                    remark,
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              // Aggregate Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('(Best 6 subjects)', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AGGREGATE POINTS: $aggregatePoints'),
                      pw.Text('POSITION: $aggregatePosition'),
                      pw.Text('OUT OF: $totalStudents'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('END RESULT: MSCE'),
                      pw.Text('TOTAL MARKS: $studentTotalMarks/$teacherTotalMarks'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Grading Key
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MSCE GRADING KEY FOR ${schoolName?.toUpperCase() ?? 'UNKNOWN SECONDARY SCHOOL'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    headers: ['Mark Range per 100', '100-90', '89-80', '79-75', '74-70', '69-65', '64-60', '59-55', '54-50', '0-49'],
                    data: [
                      ['Points', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
                      ['Interpretation', 'Distinction', 'Distinction', 'Strong Credit', 'Strong Credit', 'Credit', 'Weak Credit', 'Pass', 'Weak Pass', 'Fail'],
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Remarks Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Form Teachers\' Remarks: ${formTeacherRemarks ?? 'She is disciplined and mature, encourage her to continue portraying good behaviour'}',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'Continue working hard and encourage her to maintain scoring above pass mark in all the subjects'}',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Fees for next term', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('School account: ${schoolAccount ?? 'National Bank of Malawi, Old Town Branch, Current Account, Unknwon Secondary School, ############'}'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Next term begins on ${nextTermDate ?? 'Monday, 06th January, 2025'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}