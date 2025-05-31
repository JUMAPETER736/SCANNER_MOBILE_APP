import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';


class Juniors_School_Reports_PDF_List extends StatefulWidget {
  final String schoolName;
  final String className; // e.g., "FORM 1" or "FORM 2"
  final String? schoolAddress;
  final String? schoolPhone;
  final String? schoolEmail;
  final String? schoolAccount;
  final String? nextTermDate;
  final List<Map<String, dynamic>>? studentsData; // List of student data for PDF generation

  const Juniors_School_Reports_PDF_List({
    Key? key,
    required this.schoolName,
    required this.className,
    this.schoolAddress,
    this.schoolPhone,
    this.schoolEmail,
    this.schoolAccount,
    this.nextTermDate,
    this.studentsData,
    required String studentFullName,
    required String studentClass,

  }) : super(key: key);

  @override
  _Juniors_School_Reports_PDF_ListState createState() => _Juniors_School_Reports_PDF_ListState();
}

class _Juniors_School_Reports_PDF_ListState extends State<Juniors_School_Reports_PDF_List> {
  List<String> savedPDFs = [];
  bool isLoading = false;
  bool isGenerating = false;

  // Get the dynamic PDF storage path
  String get _pdfStoragePath {
    return '/Schools/${widget.schoolName}/Classes/${widget.className}/School_Reports_PDF';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPDFs();
  }

  // Method to determine current term based on date
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

  // Method to get academic year
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

  // Generate PDF for a single student
  Future<void> _generateStudentPDF(Map<String, dynamic> studentData) async {
    try {
      final pdfGenerator = Juniors_School_Report_PDF(
        studentClass: widget.className,
        studentFullName: studentData['studentFullName'] ?? 'Unknown Student',
        subjects: List<Map<String, dynamic>>.from(studentData['subjects'] ?? []),
        subjectStats: Map<String, dynamic>.from(studentData['subjectStats'] ?? {}),
        studentTotalMarks: studentData['studentTotalMarks'] ?? 0,
        teacherTotalMarks: studentData['teacherTotalMarks'] ?? 0,
        studentPosition: studentData['studentPosition'] ?? 0,
        totalStudents: studentData['totalStudents'] ?? 0,
        schoolName: widget.schoolName,
        schoolAddress: widget.schoolAddress,
        schoolPhone: widget.schoolPhone,
        schoolEmail: widget.schoolEmail,
        schoolAccount: widget.schoolAccount,
        nextTermDate: widget.nextTermDate,
        formTeacherRemarks: studentData['formTeacherRemarks'],
        headTeacherRemarks: studentData['headTeacherRemarks'],
        averageGradeLetter: studentData['averageGradeLetter'],
        jceStatus: studentData['jceStatus'],
      );

      // Platform-safe directory selection
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final pdfDir = Directory('${directory.path}${_pdfStoragePath}');

      // Create directory if it doesn't exist
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final fileName = '${studentData['studentFullName'].replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${pdfDir.path}/$fileName';

      await pdfGenerator.generateAndSaveToPath(filePath);

      print('PDF saved to: $filePath');

    } catch (e) {
      print('Error generating PDF for ${studentData['studentFullName']}: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }


  // Generate PDFs for all students
  Future<void> _generateAllPDFs() async {
    if (widget.studentsData == null || widget.studentsData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No student data available for PDF generation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;

      for (var studentData in widget.studentsData!) {
        try {
          await _generateStudentPDF(studentData);
          successCount++;
        } catch (e) {
          failureCount++;
          print('Failed to generate PDF for ${studentData['studentFullName']}: $e');
        }
      }

      // Refresh the PDF list
      await _loadSavedPDFs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated $successCount PDFs successfully${failureCount > 0 ? ', $failureCount failed' : ''}'),
          backgroundColor: failureCount > 0 ? Colors.orange : Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  // Load list of saved PDFs from device storage
  Future<void> _loadSavedPDFs() async {
    setState(() {
      isLoading = true;
    });

    try {
      Directory? directory;

      // Platform-safe directory selection
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms (Windows, macOS, Linux, web)
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final pdfDir = Directory('${directory.path}${_pdfStoragePath}');

        // Create the directory if it doesn't exist
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
          print('Created PDF directory: ${pdfDir.path}');
        }

        final files = pdfDir.listSync()
            .where((file) => file.path.endsWith('.pdf'))
            .map((file) {
          String fileName = file.path.split('/').last;
          // Remove .pdf extension and _Report suffix, replace underscores with spaces
          return fileName
              .replaceAll('.pdf', '')
              .replaceAll('_Report', '')
              .replaceAll('_', ' ');
        })
            .toList();

        // Sort the files alphabetically
        files.sort();

        setState(() {
          savedPDFs = files;
        });

        print('Loaded ${files.length} PDF files from: ${pdfDir.path}');
      }
    } catch (e) {
      print('Error loading saved PDFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading PDF files: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Open saved PDF
  Future<void> _openPDF(String studentName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory.path}${_pdfStoragePath}/$fileName';

      print('Attempting to open PDF: $filePath');

      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
      } else {
        print('PDF file not found at: $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found for $studentName'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

// Update the _deletePDF method
  Future<void> _deletePDF(String studentName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory.path}${_pdfStoragePath}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('Deleted PDF: $filePath');
        await _loadSavedPDFs(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF deleted successfully for $studentName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found for $studentName'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error deleting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Update the pdfExistsForStudent method
  Future<bool> pdfExistsForStudent(String studentName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        return false;
      }

      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory.path}${_pdfStoragePath}/$fileName';
      return await File(filePath).exists();
    } catch (e) {
      print('Error checking PDF existence: $e');
      return false;
    }
  }

  // Get full PDF file path for external use
  String getPDFFilePath(String studentName) {
    return '${_pdfStoragePath}/${studentName.replaceAll(' ', '_')}_Report.pdf';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.className} Reports List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [

          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Storage Information', style: TextStyle(color: Colors.blue.shade700)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('School: ${widget.schoolName}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Class: ${widget.className}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Storage Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _pdfStoragePath,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: TextStyle(color: Colors.blue.shade700)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  widget.schoolName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.className} - ${savedPDFs.length} Reports Available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Generate PDFs Button
          if (widget.studentsData != null && widget.studentsData!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: isGenerating ? null : _generateAllPDFs,
                icon: isGenerating
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  isGenerating
                      ? 'Generating PDFs...'
                      : 'Generate All Student Reports',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // PDF List Section
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF reports...',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : savedPDFs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.blue.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No PDF Reports Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.studentsData != null && widget.studentsData!.isNotEmpty
                        ? 'Tap "Generate All Student Reports" to create PDFs.'
                        : 'No student data available for PDF generation.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: savedPDFs.length,
                itemBuilder: (context, index) {
                  final studentName = savedPDFs[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          offset: Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      subtitle: Text(
                        'Tap to open report',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.blue.shade600),
                        color: Colors.white,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, color: Colors.blue.shade600),
                                SizedBox(width: 8),
                                Text('Open Report', style: TextStyle(color: Colors.blue.shade800)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red.shade600),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red.shade600)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'open') {
                            _openPDF(studentName);
                          } else if (value == 'delete') {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete PDF Report', style: TextStyle(color: Colors.blue.shade700)),
                                content: Text('Are you sure you want to delete the report for $studentName?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deletePDF(studentName);
                                    },
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      onTap: () => _openPDF(studentName),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modified PDF Generator Class with file saving capability
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
  });

  // Method to determine current term based on date
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

  // Method to get academic year
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
          0: pw.FlexColumnWidth(3.5),  // Subject name
          1: pw.FlexColumnWidth(1.2),  // Marks - reduced
          2: pw.FlexColumnWidth(0.8),  // Grade
          3: pw.FlexColumnWidth(1.0),  // Class average - reduced
          4: pw.FlexColumnWidth(1.0),  // Position - reduced
          5: pw.FlexColumnWidth(0.8),  // Out of - reduced
          6: pw.FlexColumnWidth(3.0),  // Comments
        },
        children: tableRows.asMap().entries.map((entry) {
          int index = entry.key;
          List<String> row = entry.value;
          bool isHeader = index == 0;
          bool isTotalRow = index == tableRows.length - 1;

          return pw.TableRow(
            decoration: isHeader
                ? pw.BoxDecoration(color: PdfColors.grey300)
                : (isTotalRow ? pw.BoxDecoration(color: PdfColors.grey100) : null),
            children: row.map((cell) {
              return pw.Container(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(
                    fontSize: isHeader ? 9 : 8,
                    fontWeight: isHeader || isTotalRow ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                  textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // Build remarks section with smaller fonts
  pw.Widget _buildRemarksSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(
            'FORM TEACHER\'S REMARKS:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 30,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            padding: pw.EdgeInsets.all(4),
            child: pw.Text(
              formTeacherRemarks ?? '',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'HEAD TEACHER\'S REMARKS:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 30,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            padding: pw.EdgeInsets.all(4),
            child: pw.Text(
              headTeacherRemarks ?? '',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // Build signature section
  pw.Widget _buildSignatureSection() {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 30),
              pw.Container(
                width: 120,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'FORM TEACHER\'S SIGNATURE',
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 30),
              pw.Container(
                width: 120,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'HEAD TEACHER\'S SIGNATURE',
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build JCE status section (if applicable)
  pw.Widget _buildJCEStatusSection() {
    if (jceStatus == null || jceStatus!.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(
            'JCE STATUS:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Text(
              jceStatus!,
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // Build footer section
  pw.Widget _buildFooter() {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.SizedBox(height: 12),
          if (nextTermDate != null && nextTermDate!.isNotEmpty)
            pw.Text(
              'NEXT TERM BEGINS: $nextTermDate',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 8),
          if (schoolAccount != null && schoolAccount!.isNotEmpty)
            pw.Text(
              'SCHOOL ACCOUNT: $schoolAccount',
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Generate PDF document
  Future<pw.Document> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSchoolHeader(),
              _buildStudentInfo(),
              _buildReportTable(),
              _buildRemarksSection(),
              _buildJCEStatusSection(),
              _buildSignatureSection(),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Generate and save PDF to specific file path
  Future<void> generateAndSaveToPath(String filePath) async {
    try {
      final pdf = await generatePDF();
      final file = File(filePath);

      // Ensure the directory exists
      await file.parent.create(recursive: true);

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      print('PDF successfully saved to: $filePath');
    } catch (e) {
      print('Error saving PDF to $filePath: $e');
      throw Exception('Failed to save PDF: $e');
    }
  }

  // Generate and print PDF (for preview/printing)
  Future<void> generateAndPrint() async {
    try {
      final pdf = await generatePDF();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${studentFullName}_Report_${getCurrentTerm()}_${getAcademicYear()}',
      );
    } catch (e) {
      print('Error printing PDF: $e');
      throw Exception('Failed to print PDF: $e');
    }
  }

  // Generate and share PDF
  Future<void> generateAndShare() async {
    try {
      final pdf = await generatePDF();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${studentFullName.replaceAll(' ', '_')}_Report.pdf',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      throw Exception('Failed to share PDF: $e');
    }
  }
}