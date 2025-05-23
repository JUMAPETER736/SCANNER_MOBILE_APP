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

  Juniors_School_Report_PDF({
    required this.studentClass,
    required this.studentFullName,
    required this.subjects,
    required this.subjectStats,
    required this.studentTotalMarks,
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
  });

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

  pw.Widget _buildPdfSchoolHeader() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            schoolName ?? 'UNKNOWN SECONDARY SCHOOL',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            schoolAddress ?? 'N/A',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Tel: ${schoolPhone ?? 'N/A'}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Email: ${schoolEmail ?? 'N/A'}',
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
    );
  }

  pw.Widget _buildPdfStudentInfo() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('NAME OF STUDENT: $studentFullName'),
        pw.Text('CLASS: $studentClass'),
      ],
    );
  }

  pw.Widget _buildPdfReportTable() {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      headers: ['SUBJECT', 'MARKS %', 'GRADE', 'CLASS AVERAGE', 'POSITION', 'OUT OF', 'TEACHERS\' COMMENTS'],
      data: subjects.map((subj) {
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

        return [
          subjectName,
          score.toString(),
          grade,
          avg.toString(),
          subjectPosition.toString(),
          totalStudentsForSubject.toString(),
          remark,
        ];
      }).toList(),
    );
  }

  pw.Widget _buildPdfTotalMarksRow() {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      headers: ['TOTAL MARKS', '', '', '', '', '', ''],
      data: [
        [studentTotalMarks.toString(), '', '', '', '', '', '']
      ],
    );
  }

  pw.Widget _buildPdfPositionSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('POSITION: $studentPosition'),
        pw.Text('OUT OF: $totalStudents'),
      ],
    );
  }

  pw.Widget _buildPdfGradingKey() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'JCE GRADING KEY',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          headers: ['Mark Range', '85-100', '75-84', '65-74', '50-64', '0-49'],
          data: [
            ['Grade', 'A', 'B', 'C', 'D', 'F'],
            ['Interpretation', 'EXCELLENT', 'VERY GOOD', 'GOOD', 'PASS', 'FAIL'],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfRemarksSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Form Teachers\' Remarks: ${formTeacherRemarks ?? 'N/A'}',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Fees for next term', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('School account: ${schoolAccount ?? 'N/A'}'),
        pw.SizedBox(height: 8),
        pw.Text(
          'Next term begins on ${nextTermDate ?? 'N/A'}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> generateAndPrintPDF() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // School Header
              _buildPdfSchoolHeader(),
              pw.SizedBox(height: 20),

              // Student Info
              _buildPdfStudentInfo(),
              pw.SizedBox(height: 20),

              // Report Table
              _buildPdfReportTable(),

              // TOTAL MARKS row
              _buildPdfTotalMarksRow(),

              // Position Section
              pw.SizedBox(height: 10),
              _buildPdfPositionSection(),
              pw.SizedBox(height: 10),

              // Grading Key
              _buildPdfGradingKey(),
              pw.SizedBox(height: 20),

              // Remarks Section
              _buildPdfRemarksSection(),
              pw.SizedBox(height: 20),

              // Footer
              _buildPdfFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }
}