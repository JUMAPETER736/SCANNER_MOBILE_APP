import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class Seniors_School_Report_PDF {

  final String? schoolPhone;
  final String? schoolEmail;
  final String? formTeacherRemarks;
  final String? headTeacherRemarks;
  final String? schoolFees;
  final String? schoolBankAccount;
  final String? nextTermOpeningDate;
  final String? schoolName;
  final String studentFullName;
  final String studentClass;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic> subjectStats;
  final Map<String, int> subjectPositions;
  final Map<String, int> totalStudentsPerSubject;
  final int aggregatePoints;
  final int aggregatePosition;
  final int Total_Class_Students_Number;
  final int studentTotalMarks;
  final int teacherTotalMarks;
  final int studentPosition;
  final String? msceStatus;
  final String? msceMessage;
  final int boxNumber;
  final String schoolLocation;

  Seniors_School_Report_PDF({
    required this.schoolName,
    required this.schoolPhone,
    required this.schoolEmail,
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
    required this.Total_Class_Students_Number,
    required this.studentTotalMarks,
    required this.teacherTotalMarks,
    required this.studentPosition,
    this.msceStatus,
    this.msceMessage,
    this.schoolFees,
    this.schoolBankAccount,
    this.nextTermOpeningDate,
    required this.boxNumber,
    required this.schoolLocation,

  });

  // Grade Calculation Methods
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
      case '1':
      case '2':
        return 'Distinction';
      case '3':
      case '4':
        return 'Strong Credit';
      case '5':
        return 'Credit';
      case '6':
        return 'Weak Credit';
      case '7':
        return 'Pass';
      case '8':
        return 'Weak Pass';
      default:
        return 'Fail';
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

  // Academic Period Methods
  String _getCurrentTerm() {
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

  String _getAcademicYear() {
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

  // MSCE Status Calculation
  String _getMsceStatus() {
    if (msceStatus != null && msceStatus!.isNotEmpty) {
      return msceStatus!;
    }

    // Get subject points list (implement this method based on your data structure)
    List<int> subjectPointsList = _getSubjectPointsList();

    // Use the calculateMSCEAggregate logic
    if (subjectPointsList.length < 6) {
      return 'STATEMENT';
    }

    subjectPointsList.sort();
    List<int> bestSix = subjectPointsList.take(6).toList();
    int totalPoints = bestSix.fold(0, (sum, point) => sum + point);

    if (bestSix.contains(9)) {
      return 'STATEMENT';
    }

    if (totalPoints > 48) {
      return 'STATEMENT';
    }

    return 'PASS';
  }

  // Helper method to get subject points list (implement based on your data structure)
  List<int> _getSubjectPointsList() {
    List<int> pointsList = [];

    for (var subject in subjects) {
      final hasGrade = subject['hasGrade'] as bool? ?? true;
      if (hasGrade) {
        final score = subject['score'] as int? ?? 0;
        final grade = _getGrade(score);
        final points = int.parse(_getPoints(grade));
        pointsList.add(points);
      }
    }

    return pointsList;
  }

  // PDF Generation Methods
  Future<void> generateAndPrint() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSchoolHeader(),
              _buildStudentInfo(),
              pw.SizedBox(height: 8),
              _buildReportTable(),
              _buildAggregateSection(),
              _buildGradingKey(),
              _buildRemarksSection(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

// PDF Section Builders
  pw.Widget _buildSchoolHeader() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            (schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase(),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Tel: ${schoolPhone ?? 'N/A'}',
            style: pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Email: ${schoolEmail ?? 'N/A'}',
            style: pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'P.O. BOX $boxNumber, ${schoolLocation.toUpperCase()}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${_getAcademicYear()} $studentClass END OF TERM ${_getCurrentTerm()} STUDENT\'S PROGRESS REPORT',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  pw.Padding _buildStudentInfo() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              'NAME OF STUDENT: $studentFullName',
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Row(
              children: [
                pw.Text(
                  'POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'OUT OF: ${Total_Class_Students_Number > 0 ? Total_Class_Students_Number :
                  (subjects.isNotEmpty ? subjects.first['totalStudents'] ?? 'N/A' : 'N/A')}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'CLASS: $studentClass',
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Padding _buildReportTable() {
    return pw.Padding(
      padding: pw.EdgeInsets.all(12),
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
          _buildTableHeader(),
          ..._buildSubjectRows(),
        ],
      ),
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
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
    );
  }

  List<pw.TableRow> _buildSubjectRows() {
    return subjects.map((subject) {
      final subjectName = subject['subject'] ?? 'Unknown';
      final hasGrade = subject['hasGrade'] as bool? ?? true;
      final score = subject['score'] as int? ?? 0;
      final grade = hasGrade
          ? (subject['gradeLetter']?.toString().isNotEmpty == true
          ? subject['gradeLetter']
          : _getGrade(score))
          : '';
      final remark = hasGrade ? _getRemark(grade) : 'Doesn\'t take';
      final points = hasGrade ? _getPoints(grade) : '';
      final subjectStat = subjectStats[subjectName];

      final subjectPosition = subject['position'] as int? ?? 0;
      final totalStudentsForSubject = subject['totalStudents'] as int? ?? 0;
      final avg = subjectStat != null
          ? (subjectStat['average'] as double).round()
          : 0;

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
    }).toList();
  }

  pw.Padding _buildAggregateSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '(Best 6 subjects)',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AGGREGATE POINTS: $aggregatePoints',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'RESULT: ${_getMsceStatus()}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  pw.Padding _buildGradingKey() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MSCE GRADING KEY FOR ${(schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase()}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 6),
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
              9: pw.FlexColumnWidth(1),
            },
            children: [
              _buildGradingTableHeader(),
              _buildGradingTablePoints(),
              _buildGradingTableInterpretation(),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  pw.TableRow _buildGradingTableHeader() {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _buildPdfTableCell('Mark Range', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('100-90', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('89-80', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('79-75', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('74-70', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('69-65', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('64-60', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('59-55', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('54-50', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('0-49', isHeader: true, isGradingTable: true),
      ],
    );
  }

  pw.TableRow _buildGradingTablePoints() {
    return pw.TableRow(
      children: [
        _buildPdfTableCell('Points', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('1', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('2', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('3', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('4', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('5', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('6', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('7', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('8', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('9', isHeader: true, isGradingTable: true),
      ],
    );
  }

  pw.TableRow _buildGradingTableInterpretation() {
    return pw.TableRow(
      children: [
        _buildPdfTableCell('Interpretation', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Distinction', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Distinction', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Strong Credit', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Strong Credit', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Credit', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Weak Credit', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Pass', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Weak Pass', isHeader: true, isGradingTable: true),
        _buildPdfTableCell('Fail', isHeader: true, isGradingTable: true),
      ],
    );
  }

  pw.Padding _buildRemarksSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Form Teacher\'s Remarks: ${formTeacherRemarks ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'School Fees: ${schoolFees ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'School Bank Account: ${schoolBankAccount ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Next Term Opening Date: ${nextTermOpeningDate ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // Utility Methods
  pw.Padding _buildPdfTableCell(String text, {bool isHeader = false, bool isGradingTable = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isGradingTable ? 8 : (isHeader ? 10 : 9),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}