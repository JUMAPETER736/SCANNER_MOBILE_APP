import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Seniors_School_Reports_PDF_List extends StatefulWidget {
  final String schoolName;
  final String className;
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Reports_PDF_List({
    required this.schoolName,
    required this.className,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  String get selectedClass => studentClass;

  @override
  _Seniors_School_Reports_PDF_ListState createState() => _Seniors_School_Reports_PDF_ListState();
}

class _Seniors_School_Reports_PDF_ListState extends State<Seniors_School_Reports_PDF_List> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> teacherClasses = [];
  String currentClass = '';
  bool isLoading = true;
  bool isGenerating = false;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;

  List<Map<String, dynamic>> studentsList = [];
  List<Map<String, dynamic>> pdfReportsList = [];
  int totalStudents = 0;
  int generatedReports = 0;
  double generationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String getCurrentTerm() {
    final DateTime now = DateTime.now();
    final int month = now.month;
    final int day = now.day;

    if (month >= 9 || month == 12) {
      return 'TERM_ONE';
    } else if (month >= 1 && (month <= 3 || (month == 4 && day <= 20))) {
      return 'TERM_TWO';
    } else if (month >= 4 && month <= 8) {
      return 'TERM_THREE';
    }
    return 'TERM_ONE';
  }

  String getAcademicYear() {
    final DateTime now = DateTime.now();
    int startYear, endYear;

    if (now.month >= 9) {
      startYear = now.year;
      endYear = now.year + 1;
    } else {
      startYear = now.year - 1;
      endYear = now.year;
    }

    return '${startYear}_$endYear';
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      userEmail = user.email;
      await _validateUserAccess();
      await _fetchStudentsList();
      await _fetchExistingPDFReports();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error initializing data: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _validateUserAccess() async {
    DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

    if (!userDoc.exists) {
      throw Exception('User details not found.');
    }

    final String? teacherSchool = userDoc['school'];
    final List<dynamic>? teacherClassesList = userDoc['classes'];

    if (teacherSchool == null || teacherClassesList == null || teacherClassesList.isEmpty) {
      throw Exception('Please select a School and Classes before accessing reports.');
    }

    teacherClasses = teacherClassesList.map((e) => e.toString().trim().toUpperCase()).toList();
    currentClass = widget.studentClass.trim().toUpperCase();
    schoolName = widget.schoolName;

    if (teacherSchool != widget.schoolName) {
      throw Exception('Access denied: You are not authorized for this school.');
    }

    final String studentClass = widget.studentClass.trim().toUpperCase();

    if (studentClass != 'FORM 1' && studentClass != 'FORM 2' && studentClass != 'FORM 3') {
      throw Exception('Only students in FORM 1, FORM 2, or FORM 3 can access this report.');
    }

    if (!teacherClasses.contains(studentClass)) {
      throw Exception('Access denied: You are not authorized to access ${widget.studentClass} reports.');
    }
  }

  Future<void> _fetchStudentsList() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/Student_Details')
          .get();

      List<Map<String, dynamic>> students = [];
      for (var doc in studentsSnapshot.docs) {
        students.add({
          'studentName': doc.id,
          'studentClass': widget.studentClass,
          'docId': doc.id,
        });
      }

      setState(() {
        studentsList = students;
        totalStudents = students.length;
      });
    } catch (e) {
      print("Error fetching students list: $e");
      throw Exception('Failed to fetch students list: ${e.toString()}');
    }
  }

  Future<void> _fetchExistingPDFReports() async {
    try {
      final currentTerm = getCurrentTerm();
      final academicYear = getAcademicYear();

      final pdfReportsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .where('term', isEqualTo: currentTerm)
          .where('academicYear', isEqualTo: academicYear)
          .orderBy('generatedAt', descending: true)
          .get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in pdfReportsSnapshot.docs) {
        final data = doc.data();
        reports.add({
          'docId': doc.id,
          'studentName': data['studentName'] ?? 'Unknown',
          'pdfUrl': data['pdfUrl'] ?? '',
          'generatedAt': data['generatedAt'],
          'status': data['status'] ?? 'completed',
          'fileSize': data['fileSize'] ?? 0,
          'term': data['term'] ?? currentTerm,
          'academicYear': data['academicYear'] ?? academicYear,
          'errorMessage': data['errorMessage'] ?? '',
        });
      }

      setState(() {
        pdfReportsList = reports;
        generatedReports = reports.where((r) => r['status'] == 'completed').length;
        hasError = false;
        errorMessage = null;
      });
    } catch (e) {
      print("Error fetching PDF reports: $e");
      setState(() {
        hasError = true;
        errorMessage = 'Failed to fetch PDF reports: ${e.toString()}. Please ensure the Firestore index is created.';
      });
    }
  }

  Future<void> _generateAllReports() async {
    if (studentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students found to generate reports for.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Generate All Reports'),
          content: Text(
            'This will generate PDF reports for ${studentsList.length} students. '
                'This process may take several minutes. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Generate', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isGenerating = true;
      generationProgress = 0.0;
      generatedReports = 0;
    });

    try {
      final currentTerm = getCurrentTerm();
      final academicYear = getAcademicYear();
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < studentsList.length; i++) {
        final student = studentsList[i];
        final studentName = student['studentName'];

        try {
          final existingReport = await _firestore
              .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
              .where('studentName', isEqualTo: studentName)
              .where('term', isEqualTo: currentTerm)
              .where('academicYear', isEqualTo: academicYear)
              .limit(1)
              .get();

          if (existingReport.docs.isEmpty || existingReport.docs.first.data()['status'] == 'error') {
            await _generateSingleReport(studentName, currentTerm, academicYear);
            successCount++;
          } else {
            print("Report already exists for $studentName");
          }

          setState(() {
            generatedReports = i + 1;
            generationProgress = (i + 1) / studentsList.length;
          });
        } catch (e) {
          print("Error generating report for $studentName: $e");
          errorCount++;
        }
      }

      await _fetchExistingPDFReports();

      String message = 'Report generation completed!';
      if (errorCount > 0) {
        message += ' ($successCount successful, $errorCount failed)';
      } else if (successCount == 0) {
        message = 'No new reports generated. All reports may already exist.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print("Error during batch generation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during report generation: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        isGenerating = false;
        generationProgress = 0.0;
      });
    }
  }

  Future<void> _generateSingleReport(String studentName, String term, String academicYear) async {
    try {
      final basePath = 'Schools/$schoolName/Classes/${widget.studentClass}/Student_Details/$studentName';
      final studentData = await _fetchStudentReportData(basePath);

      String cleanStudentName = studentName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      String uniqueFileName = '${cleanStudentName}_${widget.studentClass}_${term}_${academicYear}.pdf';

      final pdfGenerator = Seniors_School_Report_PDF(
        studentClass: widget.studentClass,
        studentFullName: studentName,
        subjects: studentData['subjects'] ?? [],
        subjectStats: studentData['subjectStats'] ?? {},
        studentTotalMarks: studentData['studentTotalMarks'] ?? 0,
        teacherTotalMarks: studentData['teacherTotalMarks'] ?? 0,
        studentPosition: studentData['studentPosition'] ?? 0,
        totalStudents: studentData['totalStudents'] ?? 0,
        schoolName: studentData['schoolName'],
        schoolPhone: studentData['schoolPhone'],
        schoolEmail: studentData['schoolEmail'],
        schoolAccount: studentData['schoolAccount'] ?? 'N/A',
        formTeacherRemarks: studentData['formTeacherRemarks'],
        headTeacherRemarks: studentData['headTeacherRemarks'],
        averageGradeLetter: studentData['averageGradeLetter'] ?? '',
        jceStatus: studentData['jceStatus'] ?? 'FAIL',
        schoolFees: studentData['schoolFees'],
        boxNumber: studentData['boxNumber'] ?? 0,
        schoolLocation: studentData['schoolLocation'] ?? 'N/A',
        schoolBankAccount: studentData['schoolBankAccount'],
        nextTermOpeningDate: studentData['nextTermOpeningDate'],
        bestSixTotalPoints: studentData['bestSixTotalPoints'] ?? 0,
        msceMessage: studentData['msceMessage'] ?? 'N/A',
      );

      final pdfBytes = await pdfGenerator.generatePDF();

      final storageRef = _storage.ref().child(
          'Schools/$schoolName/Classes/${widget.studentClass}/Reports/$uniqueFileName');
      final uploadTask = await storageRef.putData(pdfBytes);
      final pdfUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .doc(studentName)
          .set({
        'studentName': studentName,
        'studentClass': widget.studentClass,
        'pdfFileName': uniqueFileName,
        'pdfUrl': pdfUrl,
        'generatedAt': FieldValue.serverTimestamp(),
        'term': term,
        'academicYear': academicYear,
        'status': 'completed',
        'fileSize': pdfBytes.length,
        'generatedBy': userEmail,
        'className': widget.className,
        'uniqueId': uniqueFileName,
      });
    } catch (e) {
      print("Error generating single report for $studentName: $e");

      String cleanStudentName = studentName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      String uniqueFileName = '${cleanStudentName}_${widget.studentClass}_${term}_${academicYear}.pdf';

      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .doc(studentName)
          .set({
        'studentName': studentName,
        'studentClass': widget.studentClass,
        'pdfFileName': uniqueFileName,
        'pdfUrl': '',
        'generatedAt': FieldValue.serverTimestamp(),
        'term': term,
        'academicYear': academicYear,
        'status': 'error',
        'errorMessage': e.toString(),
        'generatedBy': userEmail,
        'className': widget.className,
        'uniqueId': uniqueFileName,
      });

      throw e;
    }
  }

  Future<Map<String, dynamic>> _fetchStudentReportData(String basePath) async {
    Map<String, dynamic> data = {};

    try {
      final schoolData = await _fetchSchoolInfo();
      data.addAll(schoolData);
      data['subjects'] = await _fetchStudentSubjects(basePath);
      final marksData = await _fetchTotalMarks(basePath);
      data.addAll(marksData);
      data['subjectStats'] = await _fetchSubjectStats();
      data['totalStudents'] = totalStudents;
      return data;
    } catch (e) {
      print("Error fetching student report data: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>> _fetchSchoolInfo() async {
    try {
      DocumentSnapshot schoolInfoDoc = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('School_Information')
          .doc('School_Details')
          .get();

      return {
        'schoolName': schoolName,
        'schoolPhone': schoolInfoDoc.exists ? (schoolInfoDoc['Telephone'] ?? 'N/A') : 'N/A',
        'schoolEmail': schoolInfoDoc.exists ? (schoolInfoDoc['Email'] ?? 'N/A') : 'N/A',
        'boxNumber': schoolInfoDoc.exists ? (schoolInfoDoc['boxNumber'] ?? 0) : 0,
        'schoolLocation': schoolInfoDoc.exists ? (schoolInfoDoc['schoolLocation'] ?? 'N/A') : 'N/A',
        'schoolFees': schoolInfoDoc.exists ? (schoolInfoDoc['School_Fees'] ?? 'N/A') : 'N/A',
        'schoolBankAccount': schoolInfoDoc.exists ? (schoolInfoDoc['School_Bank_Account'] ?? 'N/A') : 'N/A',
        'nextTermOpeningDate': schoolInfoDoc.exists ? (schoolInfoDoc['Next_Term_Opening_Date'] ?? 'N/A') : 'N/A',
        'schoolAccount': schoolInfoDoc.exists ? (schoolInfoDoc['School_Account'] ?? 'N/A') : 'N/A',
      };
    } catch (e) {
      print("Error fetching school info: $e");
      return {
        'schoolName': schoolName,
        'schoolPhone': 'N/A',
        'schoolEmail': 'N/A',
        'schoolAccount': 'N/A',
        'boxNumber': 0,
        'schoolLocation': 'N/A',
        'schoolFees': 'N/A',
        'schoolBankAccount': 'N/A',
        'nextTermOpeningDate': 'N/A',
      };
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore.collection('$basePath/Student_Subjects').get();
      List<Map<String, dynamic>> subjectList = [];

      const allSubjects = [
        'ADDITIONAL MATHEMATICS',
        'AGRICULTURE',
        'BIBLE KNOWLEDGE',
        'BIOLOGY',
        'CHEMISTRY',
        'CHICHEWA',
        'COMPUTER SCIENCE',
        'ENGLISH',
        'GEOGRAPHY',
        'HISTORY',
        'HOME ECONOMICS',
        'LIFE & SOCIAL',
        'MATHEMATICS',
        'PHYSICS',
      ];

      for (var subject in allSubjects) {
        subjectList.add({
          'subject': subject,
          'score': 0,
          'position': 0,
          'totalStudents': 0,
          'gradeLetter': 'N/A',
          'gradeRemark': 'N/A',
        });
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final subjectName = data['Subject_Name']?.toString() ?? doc.id;
        int score = 0;
        if (data['Subject_Grade'] != null) {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }
        int subjectPosition = (data['Subject_Position'] as num?)?.toInt() ?? 0;
        int totalStudentsInSubject = (data['Total_Students_Subject'] as num?)?.toInt() ?? 0;
        String gradeLetter = data['Grade_Letter']?.toString() ?? _getGradeFromPercentage(score.toDouble());
        String gradeRemark = data['Grade_Remark']?.toString() ?? 'N/A';

        final index = subjectList.indexWhere((s) => s['subject'] == subjectName);
        if (index != -1) {
          subjectList[index] = {
            'subject': subjectName,
            'score': score,
            'position': subjectPosition,
            'totalStudents': totalStudentsInSubject,
            'gradeLetter': gradeLetter,
            'gradeRemark': gradeRemark,
          };
        }
      }

      subjectList.sort((a, b) => (a['subject'] as String).compareTo(b['subject'] as String));
      return subjectList;
    } catch (e) {
      print("Error fetching subjects: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore.doc('$basePath/TOTAL_MARKS/Marks').get();
      Map<String, dynamic> result = {};

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        result = {
          'studentTotalMarks': int.tryParse(data['Student_Total_Marks']?.toString() ?? '0') ?? 0,
          'teacherTotalMarks': int.tryParse(data['Teacher_Total_Marks']?.toString() ?? '0') ?? 0,
          'studentPosition': (data['Student_Class_Position'] as num?)?.toInt() ?? 0,
          'averageGradeLetter': data['Aggregate_Grade']?.toString() ?? 'N/A',
          'jceStatus': data['MSCE_Status']?.toString() ?? 'FAIL',
          'bestSixTotalPoints': (data['Best_Six_Total_Points'] as num?)?.toInt() ?? 0,
          'msceMessage': data['MSCE_Message']?.toString() ?? 'N/A',
        };
      } else {
        result = {
          'studentTotalMarks': 0,
          'teacherTotalMarks': 0,
          'studentPosition': 0,
          'averageGradeLetter': 'N/A',
          'jceStatus': 'FAIL',
          'bestSixTotalPoints': 0,
          'msceMessage': 'N/A',
        };
      }

      try {
        final remarksDoc = await _firestore.doc('$basePath/TOTAL_MARKS/Results_Remarks').get();
        if (remarksDoc.exists) {
          final remarksData = remarksDoc.data() as Map<String, dynamic>;
          result['formTeacherRemarks'] = remarksData['Form_Teacher_Remark']?.toString() ?? 'N/A';
          result['headTeacherRemarks'] = remarksData['Head_Teacher_Remark']?.toString() ?? 'N/A';
        } else {
          result['formTeacherRemarks'] = 'N/A';
          result['headTeacherRemarks'] = 'N/A';
        }
      } catch (e) {
        print("Error fetching remarks: $e");
        result['formTeacherRemarks'] = 'N/A';
        result['headTeacherRemarks'] = 'N/A';
      }

      return result;
    } catch (e) {
      print("Error fetching total marks: $e");
      return {
        'studentTotalMarks': 0,
        'teacherTotalMarks': 0,
        'studentPosition': 0,
        'averageGradeLetter': 'N/A',
        'jceStatus': 'FAIL',
        'bestSixTotalPoints': 0,
        'msceMessage': 'N/A',
        'formTeacherRemarks': 'N/A',
        'headTeacherRemarks': 'N/A',
      };
    }
  }

  Future<Map<String, dynamic>> _fetchSubjectStats() async {
    try {
      final subjectStatsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/Class_Performance/Subject_Performance/Subjects')
          .get();

      Map<String, dynamic> stats = {};

      for (var doc in subjectStatsSnapshot.docs) {
        final data = doc.data();
        final subjectName = data['Subject_Name'] ?? doc.id;

        stats[subjectName] = {
          'average': (data['Subject_Average'] as num?)?.toDouble() ?? 0.0,
          'totalStudents': (data['Total_Students'] as num?)?.toInt() ?? 0,
          'totalPass': (data['Total_Pass'] as num?)?.toInt() ?? 0,
          'totalFail': (data['Total_Fail'] as num?)?.toInt() ?? 0,
          'passRate': (data['Pass_Rate'] as num?)?.toDouble() ?? 0.0,
        };
      }

      return stats;
    } catch (e) {
      print("Error fetching subject statistics: $e");
      return {};
    }
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 85) return 'A';
    if (percentage >= 75) return 'B';
    if (percentage >= 65) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Future<void> _regenerateReport(String studentName) async {
    setState(() {
      isGenerating = true;
    });

    try {
      final currentTerm = getCurrentTerm();
      final academicYear = getAcademicYear();

      final existingReports = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .where('studentName', isEqualTo: studentName)
          .where('term', isEqualTo: currentTerm)
          .where('academicYear', isEqualTo: academicYear)
          .get();

      for (var doc in existingReports.docs) {
        final pdfFileName = doc.data()['pdfFileName'];
        if (pdfFileName != null) {
          await _storage
              .ref()
              .child('Schools/$schoolName/Classes/${widget.studentClass}/Reports/$pdfFileName')
              .delete()
              .catchError((e) => print("Error deleting old PDF: $e"));
        }
        await doc.reference.delete();
      }

      await _generateSingleReport(studentName, currentTerm, academicYear);
      await _fetchExistingPDFReports();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report regenerated successfully for $studentName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error regenerating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  Future<void> _deleteReport(String docId) async {
    try {
      final doc = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .doc(docId)
          .get();

      if (doc.exists && doc.data()!['pdfFileName'] != null) {
        await _storage
            .ref()
            .child('Schools/$schoolName/Classes/${widget.studentClass}/Reports/${doc.data()!['pdfFileName']}')
            .delete()
            .catchError((e) => print("Error deleting PDF: $e"));
      }

      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .doc(docId)
          .delete();

      await _fetchExistingPDFReports();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _downloadPDF(String pdfUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      return null;
    }
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Text(
            '${widget.studentClass} PDF REPORTS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.schoolName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Students', totalStudents.toString(), Colors.blue),
              _buildStatCard('Generated Reports', generatedReports.toString(), Colors.green),
              _buildStatCard('Pending', (totalStudents - generatedReports).toString(), Colors.red),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Term ${getCurrentTerm()} - ${getAcademicYear()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (!isGenerating) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generating Reports...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please wait while PDF reports are being generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: generationProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 8),
          Text(
            '${generatedReports}/${totalStudents} completed (${(generationProgress * 100).toInt()}%)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFReportsList() {
    if (pdfReportsList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No PDF reports generated yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                'Tap "Generate All Reports" to create PDF reports',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: pdfReportsList.length,
        itemBuilder: (context, index) {
          final report = pdfReportsList[index];
          final isCompleted = report['status'] == 'completed';
          final isError = report['status'] == 'error';
          final generatedAt = report['generatedAt'] as Timestamp?;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              onTap: isCompleted && report['pdfUrl'].isNotEmpty
                  ? () async {
                final filePath = await _downloadPDF(
                    report['pdfUrl'], report['pdfFileName']);
                if (filePath != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewerPage(
                        filePath: filePath,
                        title: report['studentName'],
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to open PDF for ${report['studentName']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
                  : null,
              leading: CircleAvatar(
                backgroundColor: isCompleted ? Colors.green : Colors.red,
                child: Icon(
                  isCompleted ? Icons.picture_as_pdf : Icons.error,
                  color: Colors.white,
                ),
              ),
              title: Text(
                report['studentName'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${report['status'].toString().toUpperCase()}'),
                  if (isError && report['errorMessage'] != null)
                    Text(
                      'Error: ${report['errorMessage']}',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (generatedAt != null)
                    Text(
                      'Generated: ${DateFormat('MMM dd, yyyy - HH:mm').format(generatedAt.toDate())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  Text(
                    'Term ${report['term']} - ${report['academicYear']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      if (report['pdfUrl'].isNotEmpty) {
                        final filePath = await _downloadPDF(
                            report['pdfUrl'], report['pdfFileName']);
                        if (filePath != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PDFViewerPage(
                                filePath: filePath,
                                title: report['studentName'],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to open PDF for ${report['studentName']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      break;
                    case 'download':
                      if (report['pdfUrl'].isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading PDF for ${report['studentName']}'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        // Implement additional download logic if needed
                      }
                      break;
                    case 'regenerate':
                      await _regenerateReport(report['studentName']);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(report['docId'], report['studentName']);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  if (isCompleted) ...[
                    PopupMenuItem<String>(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'download',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Download'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  if (isError)
                    PopupMenuItem<String>(
                      value: 'regenerate',
                      child: ListTile(
                        leading: Icon(Icons.refresh, color: Colors.blue),
                        title: Text('Regenerate', style: TextStyle(color: Colors.blue)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String docId, String studentName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Report'),
          content: Text('Are you sure you want to delete the PDF report for $studentName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReport(docId);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SENIORS PDF LIST'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading || isGenerating ? null : _fetchExistingPDFReports,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      )
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              child: Text('Try Again'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildHeaderStats(),
          _buildProgressIndicator(),
          _buildPDFReportsList(),
        ],
      ),
      floatingActionButton: isLoading || isGenerating
          ? null
          : FloatingActionButton.extended(
        onPressed: _generateAllReports,
        icon: Icon(Icons.picture_as_pdf),
        label: Text('Generate All Reports'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Seniors_School_Report_PDF {
  final String studentClass;
  final String studentFullName;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic> subjectStats;
  final int studentTotalMarks;
  final int teacherTotalMarks;
  final int studentPosition;
  final int totalStudents;
  final String schoolName;
  final String schoolPhone;
  final String schoolEmail;
  final String schoolAccount;
  final String formTeacherRemarks;
  final String headTeacherRemarks;
  final String averageGradeLetter;
  final String jceStatus;
  final String schoolFees;
  final int boxNumber;
  final String schoolLocation;
  final String schoolBankAccount;
  final String nextTermOpeningDate;
  final int bestSixTotalPoints;
  final String msceMessage;

  Seniors_School_Report_PDF({
    required String studentClass,
    required String studentFullName,
    required List<Map<String, dynamic>> subjects,
    required Map<String, dynamic> subjectStats,
    required int studentTotalMarks,
    required int teacherTotalMarks,
    required int studentPosition,
    required int totalStudents,
    required String schoolName,
    required String schoolPhone,
    required String schoolEmail,
    required String schoolAccount,
    required String formTeacherRemarks,
    required String headTeacherRemarks,
    required String averageGradeLetter,
    required String jceStatus,
    required String schoolFees,
    required int boxNumber,
    required String schoolLocation,
    required String schoolBankAccount,
    required String nextTermOpeningDate,
    required int bestSixTotalPoints,
    required String msceMessage,
  })  : studentClass = studentClass,
        studentFullName = studentFullName,
        subjects = subjects,
        subjectStats = subjectStats,
        studentTotalMarks = studentTotalMarks,
        teacherTotalMarks = teacherTotalMarks,
        studentPosition = studentPosition,
        totalStudents = totalStudents,
        schoolName = schoolName,
        schoolPhone = schoolPhone,
        schoolEmail = schoolEmail,
        schoolAccount = schoolAccount,
        formTeacherRemarks = formTeacherRemarks,
        headTeacherRemarks = headTeacherRemarks,
        averageGradeLetter = averageGradeLetter,
        jceStatus = jceStatus,
        schoolFees = schoolFees,
        boxNumber = boxNumber,
        schoolLocation = schoolLocation,
        schoolBankAccount = schoolBankAccount,
        nextTermOpeningDate = nextTermOpeningDate,
        bestSixTotalPoints = bestSixTotalPoints,
        msceMessage = msceMessage;

  Future<Uint8List> generatePDF() async {
    final pdf = pw.Document();

    // Load custom font with fallback
    pw.Font ttf = pw.Font.helvetica();
    pw.Font ttfBold = pw.Font.helveticaBold();
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      ttf = pw.Font.ttf(fontData);
      final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      ttfBold = pw.Font.ttf(fontBoldData);
    } catch (e) {
      print("Error loading fonts: $e");
      // Continue with default fonts
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                '$schoolName - Student Report',
                style: pw.TextStyle(fontSize: 24, font: ttfBold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Student: $studentFullName', style: pw.TextStyle(fontSize: 18, font: ttf)),
            pw.Text('Class: $studentClass', style: pw.TextStyle(fontSize: 16, font: ttf)),
            pw.SizedBox(height: 20),
            pw.Text('School Details:', style: pw.TextStyle(fontSize: 16, font: ttfBold)),
            pw.Text('Phone: $schoolPhone', style: pw.TextStyle(font: ttf)),
            pw.Text('Email: $schoolEmail', style: pw.TextStyle(font: ttf)),
            pw.Text('Location: $schoolLocation', style: pw.TextStyle(font: ttf)),
            pw.Text('Box Number: $boxNumber', style: pw.TextStyle(font: ttf)),
            pw.Text('Bank Account: $schoolBankAccount', style: pw.TextStyle(font: ttf)),
            pw.Text('School Fees: $schoolFees', style: pw.TextStyle(font: ttf)),
            pw.Text('Next Term Opening: $nextTermOpeningDate', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Text('Academic Performance:', style: pw.TextStyle(fontSize: 16, font: ttfBold)),
            pw.Table.fromTextArray(
              headers: ['Subject', 'Score', 'Grade', 'Remark', 'Position', 'Total Students'],
              headerStyle: pw.TextStyle(font: ttfBold),
              cellStyle: pw.TextStyle(font: ttf),
              data: subjects
                  .map((subject) => [
                subject['subject'],
                subject['score'].toString(),
                subject['gradeLetter'],
                subject['gradeRemark'],
                subject['position'].toString(),
                subject['totalStudents'].toString(),
              ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Overall Performance:', style: pw.TextStyle(fontSize: 16, font: ttfBold)),
            pw.Text('Total Marks: $studentTotalMarks / $teacherTotalMarks', style: pw.TextStyle(font: ttf)),
            pw.Text('Aggregate Grade: $averageGradeLetter', style: pw.TextStyle(font: ttf)),
            pw.Text('Best Six Total Points: $bestSixTotalPoints', style: pw.TextStyle(font: ttf)),
            pw.Text('Position: $studentPosition / $totalStudents', style: pw.TextStyle(font: ttf)),
            pw.Text('MSCE Status: $jceStatus', style: pw.TextStyle(font: ttf)),
            pw.Text('MSCE Message: $msceMessage', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Text('Remarks:', style: pw.TextStyle(fontSize: 16, font: ttfBold)),
            pw.Text('Form Teacher: $formTeacherRemarks', style: pw.TextStyle(font: ttf)),
            pw.Text('Head Teacher: $headTeacherRemarks', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            if (subjectStats.isNotEmpty) ...[
              pw.Text('Subject Statistics:', style: pw.TextStyle(fontSize: 16, font: ttfBold)),
              pw.Table.fromTextArray(
                headers: ['Subject', 'Average', 'Pass Rate', 'Total Pass', 'Total Fail'],
                headerStyle: pw.TextStyle(font: ttfBold),
                cellStyle: pw.TextStyle(font: ttf),
                data: subjectStats.entries
                    .map((entry) => [
                  entry.key,
                  entry.value['average'].toString(),
                  '${entry.value['passRate']}%',
                  entry.value['totalPass'].toString(),
                  entry.value['totalFail'].toString(),
                ])
                    .toList(),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }
}

class PDFViewerPage extends StatelessWidget {
  final String filePath;
  final String title;

  const PDFViewerPage({required this.filePath, required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading PDF: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}