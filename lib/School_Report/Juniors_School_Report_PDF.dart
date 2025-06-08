import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class Juniors_School_Report_PDF {
  final String studentClass;
  final String studentFullName;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic> subjectStats;
  final int studentTotalMarks;
  final int teacherTotalMarks;
  final int studentPosition;
  final int totalStudents;
  final String? schoolName;
  final String? schoolAddress;
  final String? schoolPhone;
  final String? schoolEmail;
  final String? schoolAccount;
  final String? nextTermDate;
  final String? formTeacherRemarks;
  final String? headTeacherRemarks;
  final String? averageGradeLetter;
  final String? jceStatus;
  final String? schoolFees;
  final String? schoolBankAccount;
  final String? nextTermOpeningDate;

  Juniors_School_Report_PDF({
    required this.studentClass,
    required this.studentFullName,
    required this.subjects,
    required this.subjectStats,
    required this.studentTotalMarks,
    required this.teacherTotalMarks,
    required this.studentPosition,
    required this.totalStudents,
    this.schoolName,
    this.schoolAddress,
    this.schoolPhone,
    this.schoolEmail,
    this.schoolAccount,
    this.nextTermDate,
    this.formTeacherRemarks,
    this.headTeacherRemarks,
    this.averageGradeLetter,
    this.jceStatus,
    this.schoolFees,
    this.schoolBankAccount,
    this.nextTermOpeningDate,

  });

  // Method to determine current term based on date (matching main app logic)
  String getCurrentTerm() {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentDay = now.day;

    if ((currentMonth == 9 && currentDay >= 1) ||
        (currentMonth >= 10 && currentMonth <= 12)) {
      return 'ONE';
    }
    else if ((currentMonth == 1 && currentDay >= 2) ||
        (currentMonth >= 2 && currentMonth <= 3) ||
        (currentMonth == 4 && currentDay <= 20)) {
      return 'TWO';
    }
    else if ((currentMonth == 4 && currentDay >= 25) ||
        (currentMonth >= 5 && currentMonth <= 7)) {
      return 'THREE';
    }
    else {
      return 'ONE';
    }
  }

  // Method to get academic year (matching main app logic)
  String getAcademicYear() {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    if (currentMonth >= 9) {
      return '$currentYear/${currentYear + 1}';
    } else {
      return '${currentYear - 1}/$currentYear';
    }
  }

  String Juniors_Grade(int Juniors_Score) {
    if (Juniors_Score >= 85) return 'A';
    if (Juniors_Score >= 75) return 'B';
    if (Juniors_Score >= 65) return 'C';
    if (Juniors_Score >= 50) return 'D';
    return 'F';
  }

  String getRemark(String Juniors_Grade) {
    switch (Juniors_Grade) {
      case 'A': return 'EXCELLENT';
      case 'B': return 'VERY GOOD';
      case 'C': return 'GOOD';
      case 'D': return 'PASS';
      default: return 'FAIL';
    }
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 85) return 'A';
    if (percentage >= 75) return 'B';
    if (percentage >= 65) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  // Build school header with optimized font sizes
  pw.Widget _buildSchoolHeader() {
    return pw.Column(
      children: [
        pw.Text(
          (schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase(),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          schoolAddress ?? 'N/A',
          style: pw.TextStyle(fontSize: 12),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Tel: ${schoolPhone ?? 'N/A'}',
          style: pw.TextStyle(fontSize: 11),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Email: ${schoolEmail ?? 'N/A'}',
          style: pw.TextStyle(fontSize: 11),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'PROGRESS REPORT',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '${getAcademicYear()} '
              '$studentClass END OF TERM ${getCurrentTerm()} STUDENT\'S PROGRESS REPORT',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  // Build student info section with smaller font
  pw.Widget _buildStudentInfo() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'NAME OF STUDENT: $studentFullName',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'OUT OF: ${totalStudents > 0 ? totalStudents : 'N/A'}',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'CLASS: $studentClass',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  // Build report table with optimized column widths and smaller fonts
  pw.Widget _buildReportTable() {
    List<List<String>> tableRows = [];

    // Add header row
    tableRows.add([
      'SUBJECT',
      'MARKS %',
      'GRADE',
      'CLASS AVG',
      'POSITION',
      'OUT OF',
      'TEACHERS\' COMMENTS',
    ]);

    // Add subject rows
    for (var subj in subjects) {
      final subjectName = subj['subject'] ?? 'Unknown';
      final score = subj['score'] as int? ?? 0;
      final grade = subj['gradeLetter']?.toString().isNotEmpty == true
          ? subj['gradeLetter']
          : Juniors_Grade(score);
      final remark = getRemark(grade);
      final subjectStat = subjectStats[subjectName];
      final avg = subjectStat != null ? subjectStat['average'] as int : 0;
      final subjectPosition = subj['position'] as int? ?? 0;
      final totalStudentsForSubject = subj['totalStudents'] as int? ?? 0;

      tableRows.add([
        subjectName,
        score.toString(),
        grade,
        avg.toString(),
        subjectPosition > 0 ? subjectPosition.toString() : '-',
        totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : '-',
        remark,
      ]);
    }

    // Add total marks row
    tableRows.add([
      'TOTAL MARKS',
      studentTotalMarks.toString(),
      averageGradeLetter?.isNotEmpty == true ? averageGradeLetter! : 'F',
      '',
      '',
      '',
      '',
    ]);

    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5),
        columnWidths: {
          0: pw.FlexColumnWidth(3.0),  // Subject name - reduced slightly
          1: pw.FlexColumnWidth(1.0),  // Marks - reduced
          2: pw.FlexColumnWidth(1.0),  // Grade - increased
          3: pw.FlexColumnWidth(1.0),  // Class average
          4: pw.FlexColumnWidth(1.2),  // Position - increased
          5: pw.FlexColumnWidth(0.8),  // Out of
          6: pw.FlexColumnWidth(2.5),  // Comments
        },
        children: tableRows.asMap().entries.map((entry) {
          int index = entry.key;
          List<String> row = entry.value;
          bool isHeader = index == 0;
          bool isTotalRow = index == tableRows.length - 1;
          bool isGrayRow = isHeader || isTotalRow;

          return pw.TableRow(
            decoration: isGrayRow ? pw.BoxDecoration(color: PdfColors.grey300) : null,
            children: row.map((cell) => _tableCell(cell, isHeader: isGrayRow)).toList(),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,  // Reduced font sizes
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Build result section with smaller font
  pw.Widget _buildResultSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Text(
                'RESULT: ${jceStatus ?? 'FAIL'}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  // Build grading key with optimized layout
  pw.Widget _buildGradingKey() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'JCE GRADING KEY FOR ${(schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase()}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _gradingKeyCell('Mark Range', isHeader: true),
                  _gradingKeyCell('85-100', isHeader: true),
                  _gradingKeyCell('75-84', isHeader: true),
                  _gradingKeyCell('65-74', isHeader: true),
                  _gradingKeyCell('50-64', isHeader: true),
                  _gradingKeyCell('0-49', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _gradingKeyCell('Grade', isHeader: true),
                  _gradingKeyCell('A'),
                  _gradingKeyCell('B'),
                  _gradingKeyCell('C'),
                  _gradingKeyCell('D'),
                  _gradingKeyCell('F'),
                ],
              ),
              pw.TableRow(
                children: [
                  _gradingKeyCell('Interpretation', isHeader: true),
                  _gradingKeyCell('EXCELLENT'),
                  _gradingKeyCell('VERY GOOD'),
                  _gradingKeyCell('GOOD'),
                  _gradingKeyCell('PASS'),
                  _gradingKeyCell('FAIL'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  pw.Widget _gradingKeyCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Build remarks section with smaller font
  pw.Widget _buildRemarksSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Form Teachers\' Remarks: ${formTeacherRemarks ?? 'N/A'}',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  // Build footer with smaller font
  pw.Widget _buildFooter() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Fees for next term',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(
            'School account: ${schoolAccount ?? 'N/A'}',
            style: pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Next term begins on ${nextTermDate ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> generateAndPrintPDF() async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(12), // Reduced margin for more space
          build: (pw.Context context) {
            return pw.Column(
              children: [
                _buildSchoolHeader(),
                _buildStudentInfo(),
                _buildReportTable(),
                _buildResultSection(),
                _buildGradingKey(),
                _buildRemarksSection(),
                _buildFooter(),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );

    } catch (e) {
      print("Error generating PDF: $e");
      throw Exception("Failed to generate PDF: $e");
    }
  }

  // Additional method for saving PDF to file (optional)
  Future<void> generateAndSavePDF(String fileName) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(12),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                _buildSchoolHeader(),
                _buildStudentInfo(),
                _buildReportTable(),
                _buildResultSection(),
                _buildGradingKey(),
                _buildRemarksSection(),
                _buildFooter(),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: fileName,
      );

    } catch (e) {
      print("Error saving PDF: $e");
      throw Exception("Failed to save PDF: $e");
    }
  }
}