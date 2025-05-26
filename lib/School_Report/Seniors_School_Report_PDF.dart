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
  final String? averageGradeLetter;

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
    this.averageGradeLetter,
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
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // School Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName ?? 'UNKNOWN SECONDARY SCHOOL',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      schoolAddress ?? 'P.O. BOX 47, LILONGWE',
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Tel: ${schoolPhone ?? '(+265) # ### ### ### or (+265) # ### ### ###'}',
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Email: ${schoolEmail ?? 'secondaryschool@gmail.com'}',
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PROGRESS REPORT',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      '${DateFormat('yyyy').format(DateTime.now())}/${DateFormat('yy').format(DateTime.now().add(Duration(days: 365)))} '
                          '$studentClass END OF TERM ONE STUDENT\'S PROGRESS REPORT',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Student Info
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NAME OF STUDENT: $studentFullName'),
                    pw.Text('CLASS: $studentClass'),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Report Table
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FlexColumnWidth(1.5),
                    5: pw.FlexColumnWidth(1.5),
                    6: pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildPdfTableCell('SUBJECT', isHeader: true),
                        _buildPdfTableCell('MARKS %', isHeader: true),
                        _buildPdfTableCell('POINTS', isHeader: true),
                        _buildPdfTableCell('CLASS AVERAGE', isHeader: true),
                        _buildPdfTableCell('POSITION', isHeader: true),
                        _buildPdfTableCell('OUT OF', isHeader: true),
                        _buildPdfTableCell('TEACHERS\' COMMENTS', isHeader: true),
                      ],
                    ),
                    ...subjects.map((subj) {
                      final subjectName = subj['subject'] ?? 'Unknown';
                      final hasGrade = subj['hasGrade'] as bool? ?? true;
                      final score = subj['score'] as int? ?? 0;
                      final grade = hasGrade ? (subj['gradeLetter']?.toString().isNotEmpty == true
                          ? subj['gradeLetter']
                          : _getGrade(score)) : '';
                      final remark = hasGrade ? _getRemark(grade) : 'Doesn\'t take';
                      final points = hasGrade ? _getPoints(grade) : '';
                      final subjectStat = subjectStats[subjectName];
                      final avg = subjectStat != null ? subjectStat['average'] as int : 0;
                      final subjectPosition = subj['position'] as int? ?? 0;
                      final totalStudentsForSubject = subj['totalStudents'] as int? ?? 0;

                      return pw.TableRow(
                        children: [
                          _buildPdfTableCell(subjectName),
                          _buildPdfTableCell(hasGrade ? score.toString() : ''),
                          _buildPdfTableCell(points),
                          _buildPdfTableCell(hasGrade ? avg.toString() : ''),
                          _buildPdfTableCell(hasGrade && subjectPosition > 0 ? subjectPosition.toString() : ''),
                          _buildPdfTableCell(hasGrade && totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : ''),
                          _buildPdfTableCell(remark),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Aggregate Section
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Column(
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
                        if (averageGradeLetter != null)
                          pw.Text('AVERAGE GRADE: $averageGradeLetter'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Grading Key
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MSCE GRADING KEY',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1),
                        2: pw.FlexColumnWidth(1),
                        3: pw.FlexColumnWidth(1),
                        4: pw.FlexColumnWidth(1),
                        5: pw.FlexColumnWidth(1),
                        6: pw.FlexColumnWidth(1),
                        7: pw.FlexColumnWidth(1),
                        8: pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            _buildPdfTableCell('Mark Range', isHeader: true),
                            _buildPdfTableCell('100-90', isHeader: true),
                            _buildPdfTableCell('89-80', isHeader: true),
                            _buildPdfTableCell('79-75', isHeader: true),
                            _buildPdfTableCell('74-70', isHeader: true),
                            _buildPdfTableCell('69-65', isHeader: true),
                            _buildPdfTableCell('64-60', isHeader: true),
                            _buildPdfTableCell('59-55', isHeader: true),
                            _buildPdfTableCell('54-50', isHeader: true),
                            _buildPdfTableCell('0-49', isHeader: true),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildPdfTableCell('Points', isHeader: true),
                            _buildPdfTableCell('1', isHeader: true),
                            _buildPdfTableCell('2', isHeader: true),
                            _buildPdfTableCell('3', isHeader: true),
                            _buildPdfTableCell('4', isHeader: true),
                            _buildPdfTableCell('5', isHeader: true),
                            _buildPdfTableCell('6', isHeader: true),
                            _buildPdfTableCell('7', isHeader: true),
                            _buildPdfTableCell('8', isHeader: true),
                            _buildPdfTableCell('9', isHeader: true),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildPdfTableCell('Interpretation', isHeader: true),
                            _buildPdfTableCell('Distinction', isHeader: true),
                            _buildPdfTableCell('Distinction', isHeader: true),
                            _buildPdfTableCell('Strong Credit', isHeader: true),
                            _buildPdfTableCell('Strong Credit', isHeader: true),
                            _buildPdfTableCell('Credit', isHeader: true),
                            _buildPdfTableCell('Weak Credit', isHeader: true),
                            _buildPdfTableCell('Pass', isHeader: true),
                            _buildPdfTableCell('Weak Pass', isHeader: true),
                            _buildPdfTableCell('Fail', isHeader: true),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Remarks Section
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Column(
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
              ),

              pw.SizedBox(height: 16),

              // Footer
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fees for next term', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('School account: ${schoolAccount ?? 'National Bank of Malawi, Old Town Branch, Current Account, Unknown Secondary School, ############'}'),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Next term begins on ${nextTermDate ?? 'Monday, 06th January, 2025'}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  pw.Padding _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}