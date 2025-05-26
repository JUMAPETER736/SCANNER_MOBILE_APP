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
  });

  // Method to determine current term based on date (matching main app logic)
  String getCurrentTerm() {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentDay = now.day;

    // TERM ONE: 1 Sept - 31 Dec
    if ((currentMonth == 9 && currentDay >= 1) ||
        (currentMonth >= 10 && currentMonth <= 12)) {
      return 'ONE';
    }
    // TERM TWO: 2 Jan - 20 April
    else if ((currentMonth == 1 && currentDay >= 2) ||
        (currentMonth >= 2 && currentMonth <= 3) ||
        (currentMonth == 4 && currentDay <= 20)) {
      return 'TWO';
    }
    // TERM THREE: 25 April - 30 July
    else if ((currentMonth == 4 && currentDay >= 25) ||
        (currentMonth >= 5 && currentMonth <= 7)) {
      return 'THREE';
    }
    // Default to ONE if date falls outside defined terms
    else {
      return 'ONE';
    }
  }

  // Method to get academic year (matching main app logic)
  String getAcademicYear() {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // Academic year starts in September
    if (currentMonth >= 9) {
      // If current month is Sept-Dec, academic year is current year to next year
      return '$currentYear/${currentYear + 1}';
    } else {
      // If current month is Jan-Aug, academic year is previous year to current year
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
          pw.SizedBox(height: 10),
          // Added PROGRESS REPORT text (matching main app)
          pw.Text(
            'PROGRESS REPORT',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '${getAcademicYear()} '
                '$studentClass END OF TERM ${getCurrentTerm()} STUDENT\'S PROGRESS REPORT',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
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
    // Create table data including individual subjects
    List<List> tableData = subjects.map((subj) {
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
        subjectPosition > 0 ? subjectPosition.toString() : '-',
        totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : '-',
        remark,
      ];
    }).toList();

    // Calculate average grade letter
    String finalAverageGrade = averageGradeLetter ?? 'F';
    if (teacherTotalMarks > 0 && finalAverageGrade.isEmpty) {
      double percentage = (studentTotalMarks / teacherTotalMarks) * 100;
      finalAverageGrade = _getGradeFromPercentage(percentage);
    }

    // Add TOTAL MARKS row
    tableData.add([
      'TOTAL MARKS',
      studentTotalMarks.toString(),
      finalAverageGrade,
      '',
      '',
      '',
      '',
    ]);

    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      cellStyle: pw.TextStyle(fontSize: 10),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.centerLeft,   // Subject
        1: pw.Alignment.center,       // Marks %
        2: pw.Alignment.center,       // Grade
        3: pw.Alignment.center,       // Class Average
        4: pw.Alignment.center,       // Position
        5: pw.Alignment.center,       // Out Of
        6: pw.Alignment.centerLeft,   // Teachers' Comments
      },
      columnWidths: {
        0: pw.FlexColumnWidth(3),     // Subject
        1: pw.FlexColumnWidth(1.5),   // Marks %
        2: pw.FlexColumnWidth(1),     // Grade
        3: pw.FlexColumnWidth(1.5),   // Class Average
        4: pw.FlexColumnWidth(1.5),   // Position
        5: pw.FlexColumnWidth(1.5),   // Out Of
        6: pw.FlexColumnWidth(3),     // Teachers' Comments
      },
      headers: ['SUBJECT', 'MARKS %', 'GRADE', 'CLASS AVERAGE', 'POSITION', 'OUT OF', 'TEACHERS\' COMMENTS'],
      data: tableData,
    );
  }

  pw.Widget _buildPdfPositionSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('OVERALL POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}'),
        pw.Text('OUT OF: ${totalStudents > 0 ? totalStudents : 'N/A'}'),
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
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: pw.TextStyle(fontSize: 9),
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
            5: pw.Alignment.center,
          },
          columnWidths: {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1),
            5: pw.FlexColumnWidth(1),
          },
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
        pw.SizedBox(height: 16),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            'Fees for next term',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
        ),
        pw.Text('School account: ${schoolAccount ?? 'N/A'}'),
        pw.SizedBox(height: 8),
        pw.Text(
          'Next term begins on ${nextTermDate ?? 'N/A'}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  Future<void> generateAndPrintPDF() async {
    try {
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
                _buildPdfSchoolHeader(),
                pw.SizedBox(height: 20),

                // Student Info
                _buildPdfStudentInfo(),
                pw.SizedBox(height: 20),

                // Report Table (includes TOTAL MARKS row)
                _buildPdfReportTable(),
                pw.SizedBox(height: 10),

                // Position Section
                _buildPdfPositionSection(),
                pw.SizedBox(height: 16),

                // Grading Key
                _buildPdfGradingKey(),
                pw.SizedBox(height: 16),

                // Remarks Section
                _buildPdfRemarksSection(),

                // Footer
                _buildPdfFooter(),
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
      // You might want to show an error message to the user
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
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfSchoolHeader(),
                pw.SizedBox(height: 20),
                _buildPdfStudentInfo(),
                pw.SizedBox(height: 20),
                _buildPdfReportTable(),
                pw.SizedBox(height: 10),
                _buildPdfPositionSection(),
                pw.SizedBox(height: 16),
                _buildPdfGradingKey(),
                pw.SizedBox(height: 16),
                _buildPdfRemarksSection(),
                _buildPdfFooter(),
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