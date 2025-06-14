import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Juniors_School_Report_PDF.dart';

class Juniors_School_Reports_PDF_List extends StatefulWidget {
  // Updated constructor parameters to match the calling code
  final String schoolName;
  final String className;
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Reports_PDF_List({
    required this.schoolName,
    required this.className,
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  // Getter for backward compatibility
  String get selectedClass => studentClass;

  @override
  _Juniors_School_Reports_PDF_ListState createState() => _Juniors_School_Reports_PDF_ListState();
}

class _Juniors_School_Reports_PDF_ListState extends State<Juniors_School_Reports_PDF_List> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool isLoading = true;
  bool isGenerating = false;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;

  // Data variables
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
    final List<dynamic>? teacherClasses = userDoc['classes'];

    if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
      throw Exception('Please select a School and Classes before accessing reports.');
    }

    // Use the schoolName passed from constructor
    schoolName = widget.schoolName;

    // Validate that teacher's school matches the passed school name
    if (teacherSchool != widget.schoolName) {
      throw Exception('Access denied: You are not authorized for this school.');
    }

    final String studentClass = widget.studentClass.trim().toUpperCase();

    if (studentClass != 'FORM 1' && studentClass != 'FORM 2') {
      throw Exception('Only students in FORM 1 or FORM 2 can access this report.');
    }

    // Validate that teacher has access to this class
    final List<String> teacherClassesStr = teacherClasses.map((e) => e.toString().trim().toUpperCase()).toList();
    if (!teacherClassesStr.contains(studentClass)) {
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
      });
    } catch (e) {
      print("Error fetching PDF reports: $e");
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

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Generate All Reports'),
          content: Text('This will generate PDF reports for ${studentsList.length} students. This process may take several minutes. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Generate'),
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
          // Check if report already exists for this term
          final existingReport = await _firestore
              .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
              .where('studentName', isEqualTo: studentName)
              .where('term', isEqualTo: currentTerm)
              .where('academicYear', isEqualTo: academicYear)
              .limit(1)
              .get();

          if (existingReport.docs.isEmpty) {
            await _generateSingleReport(studentName, currentTerm, academicYear);
            successCount++;
          } else {
            print("Report already exists for $studentName");
          }

          setState(() {
            generatedReports = i + 1;
            generationProgress = (i + 1) / studentsList.length;
          });

          // Add small delay to prevent overwhelming Firestore
          await Future.delayed(Duration(milliseconds: 500));

        } catch (e) {
          print("Error generating report for $studentName: $e");
          errorCount++;
          // Continue with next student even if one fails
        }
      }

      await _fetchExistingPDFReports(); // Refresh the list

      String message = 'Report generation completed!';
      if (errorCount > 0) {
        message += ' ($successCount successful, $errorCount failed)';
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
      // Fetch student data (similar to the original view code)
      final basePath = 'Schools/$schoolName/Classes/${widget.studentClass}/Student_Details/$studentName';

      // Fetch all required data
      final studentData = await _fetchStudentReportData(basePath);

      // Generate PDF
      final pdfGenerator = Juniors_School_Report_PDF(
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
        schoolAccount: studentData['schoolAccount'],
        nextTermDate: studentData['nextTermDate'],
        formTeacherRemarks: studentData['formTeacherRemarks'],
        headTeacherRemarks: studentData['headTeacherRemarks'],
        averageGradeLetter: studentData['averageGradeLetter'] ?? '',
        jceStatus: studentData['jceStatus'] ?? 'FAIL',
        schoolFees: studentData['schoolFees'],
        boxNumber: studentData['boxNumber'] ?? 0,
        schoolLocation: studentData['schoolLocation'] ?? 'N/A',
        schoolBankAccount: studentData['schoolBankAccount'],
        nextTermOpeningDate: studentData['nextTermOpeningDate'],
      );

      // Generate PDF with student name as parameter
      await pdfGenerator.generateAndSavePDF(studentName);

      // Save PDF report metadata to Firestore (without pdfUrl since method returns void)
      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .add({
        'studentName': studentName,
        'studentClass': widget.studentClass,
        'pdfUrl': '', // Set to empty string since generateAndSavePDF returns void
        'generatedAt': FieldValue.serverTimestamp(),
        'term': term,
        'academicYear': academicYear,
        'status': 'completed',
        'fileSize': 0, // You can calculate this if needed
        'generatedBy': userEmail,
        'className': widget.className, // Additional field for tracking
      });

    } catch (e) {
      print("Error generating single report for $studentName: $e");

      // Save error status to Firestore
      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .add({
        'studentName': studentName,
        'studentClass': widget.studentClass,
        'pdfUrl': '',
        'generatedAt': FieldValue.serverTimestamp(),
        'term': term,
        'academicYear': academicYear,
        'status': 'error',
        'errorMessage': e.toString(),
        'generatedBy': userEmail,
        'className': widget.className,
      });

      throw e;
    }
  }

  Future<Map<String, dynamic>> _fetchStudentReportData(String basePath) async {
    // This method combines all the data fetching from the original view
    Map<String, dynamic> data = {};

    try {
      // Fetch school info
      final schoolData = await _fetchSchoolInfo();
      data.addAll(schoolData);

      // Fetch student subjects
      data['subjects'] = await _fetchStudentSubjects(basePath);

      // Fetch total marks and remarks
      final marksData = await _fetchTotalMarks(basePath);
      data.addAll(marksData);

      // Fetch subject stats
      data['subjectStats'] = await _fetchSubjectStats();

      // Set total students
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
        'schoolAccount': schoolInfoDoc.exists ? (schoolInfoDoc['account'] ?? 'N/A') : 'N/A',
        'nextTermDate': schoolInfoDoc.exists ? (schoolInfoDoc['nextTermDate'] ?? 'N/A') : 'N/A',
        'boxNumber': schoolInfoDoc.exists ? (schoolInfoDoc['boxNumber'] ?? 0) : 0,
        'schoolLocation': schoolInfoDoc.exists ? (schoolInfoDoc['schoolLocation'] ?? 'N/A') : 'N/A',
        'schoolFees': schoolInfoDoc.exists ? (schoolInfoDoc['School_Fees'] ?? 'N/A') : 'N/A',
        'schoolBankAccount': schoolInfoDoc.exists ? (schoolInfoDoc['School_Bank_Account'] ?? 'N/A') : 'N/A',
        'nextTermOpeningDate': schoolInfoDoc.exists ? (schoolInfoDoc['Next_Term_Opening_Date'] ?? 'N/A') : 'N/A',
      };
    } catch (e) {
      print("Error fetching school info: $e");
      return {
        'schoolName': schoolName,
        'schoolPhone': 'N/A',
        'schoolEmail': 'N/A',
        'schoolAccount': 'N/A',
        'nextTermDate': 'N/A',
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

      for (var doc in snapshot.docs) {
        final data = doc.data();
        int score = 0;
        if (data['Subject_Grade'] != null) {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }

        int subjectPosition = (data['Subject_Position'] as num?)?.toInt() ?? 0;
        int totalStudentsInSubject = (data['Total_Students_Subject'] as num?)?.toInt() ?? 0;
        String gradeLetter = data['Grade_Letter']?.toString() ?? _getGradeFromPercentage(score.toDouble());

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': score,
          'position': subjectPosition,
          'totalStudents': totalStudentsInSubject,
          'gradeLetter': gradeLetter,
        });
      }

      // Sort subjects alphabetically
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
          'studentTotalMarks': (data['Student_Total_Marks'] as num?)?.toInt() ?? 0,
          'teacherTotalMarks': (data['Teacher_Total_Marks'] as num?)?.toInt() ?? 0,
          'studentPosition': (data['Student_Class_Position'] as num?)?.toInt() ?? 0,
          'averageGradeLetter': data['Average_Grade_Letter']?.toString() ?? '',
          'jceStatus': data['JCE_Status']?.toString() ?? 'FAIL',
        };
      } else {
        result = {
          'studentTotalMarks': 0,
          'teacherTotalMarks': 0,
          'studentPosition': 0,
          'averageGradeLetter': '',
          'jceStatus': 'FAIL',
        };
      }

      // Fetch remarks
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
        'averageGradeLetter': '',
        'jceStatus': 'FAIL',
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

      // Delete existing report first
      final existingReports = await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .where('studentName', isEqualTo: studentName)
          .where('term', isEqualTo: currentTerm)
          .where('academicYear', isEqualTo: academicYear)
          .get();

      for (var doc in existingReports.docs) {
        await doc.reference.delete();
      }

      // Generate new report
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
      await _firestore
          .collection('Schools/$schoolName/Classes/${widget.studentClass}/STUDENT_SCHOOL_REPORT_PDF_LIST')
          .doc(docId)
          .delete();

      await _fetchExistingPDFReports(); // Refresh the list

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
            '${widget.studentClass} SCHOOL REPORTS PDF',
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
              _buildStatCard('Pending', (totalStudents - generatedReports).toString(), Colors.orange),
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
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                    // Open PDF viewer (implement based on your PDF viewer)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening PDF for ${report['studentName']}')),
                      );
                      break;
                    case 'download':
                    // Download PDF (implement based on your download mechanism)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading PDF for ${report['studentName']}')),
                      );
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
        title: Text('JUNIORS PDF LIST'),
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