import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Juniors_School_Report_PDF.dart';

class Juniors_School_Report_View extends StatefulWidget {
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Report_View({
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() => _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data variables
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  Map<String, dynamic> subjectStats = {};

  // Student info
  int studentPosition = 0;
  int totalStudents = 0;
  int studentTotalMarks = 0;
  int teacherTotalMarks = 0;
  String averageGradeLetter = '';
  String jceStatus = 'FAIL';
  double averagePercentage = 0.0;

  // School info
  String? userEmail;
  String? schoolName;
  String? schoolAddress;
  String? schoolPhone;
  String? schoolEmail;
  String? schoolAccount;
  String? nextTermDate;
  String? formTeacherRemarks;
  String? headTeacherRemarks;

  // State variables
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentDataOptimized();
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

  Future<void> _fetchStudentDataOptimized() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      _setError('No user is currently logged in.');
      return;
    }

    userEmail = user.email;

    try {
      // Validate user and get school info
      DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

      if (!userDoc.exists) {
        _setError('User details not found.');
        return;
      }

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        _setError('Please select a School and Classes before accessing reports.');
        return;
      }

      schoolName = teacherSchool;
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 1' && studentClass != 'FORM 2') {
        _setError('Only students in FORM 1 or FORM 2 can access this report.');
        return;
      }

      // Use batch operations and parallel fetching for better performance
      await _fetchAllDataInParallel(teacherSchool, studentClass, studentFullName);

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print("Error: $e");
      _setError('An error occurred while fetching data: ${e.toString()}');
    }
  }

  void _setError(String message) {
    setState(() {
      isLoading = false;
      hasError = true;
      errorMessage = message;
    });
  }

  Future<void> _fetchAllDataInParallel(
      String teacherSchool,
      String studentClass,
      String studentFullName) async {

    final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

    // Create batch for reading multiple documents
    WriteBatch batch = _firestore.batch();

    try {
      // Fetch all data in parallel for maximum speed
      final List<Future> futures = [
        _fetchSchoolInfoOptimized(teacherSchool),
        _fetchStudentSubjectsOptimized(basePath),
        _fetchTotalMarksOptimized(basePath),
        _fetchSubjectStatsOptimized(teacherSchool, studentClass),
      ];

      // Wait for all operations to complete
      await Future.wait(futures);

      // Calculate JCE status
      jceStatus = studentTotalMarks >= 550 ? 'PASS' : 'FAIL';

    } catch (e) {
      print("Error in parallel fetch: $e");
      throw e;
    }
  }

  Future<void> _fetchSchoolInfoOptimized(String school) async {
    try {
      DocumentSnapshot schoolInfoDoc = await _firestore
          .collection('Schools')
          .doc(school)
          .collection('School_Information')
          .doc('details')
          .get();

      if (schoolInfoDoc.exists && schoolInfoDoc.data() != null) {
        final data = schoolInfoDoc.data() as Map<String, dynamic>;
        setState(() {
          schoolAddress = data['address']?.toString() ?? 'N/A';
          schoolPhone = data['phone']?.toString() ?? 'N/A';
          schoolEmail = data['email']?.toString() ?? 'N/A';
          schoolAccount = data['account']?.toString() ?? 'N/A';
          nextTermDate = data['nextTermDate']?.toString() ?? 'N/A';
          formTeacherRemarks = data['formTeacherRemarks']?.toString() ?? 'N/A';
          headTeacherRemarks = data['headTeacherRemarks']?.toString() ?? 'N/A';
        });
      } else {
        // Set default values if document doesn't exist
        setState(() {
          schoolAddress = 'N/A';
          schoolPhone = 'N/A';
          schoolEmail = 'N/A';
          schoolAccount = 'N/A';
          nextTermDate = 'N/A';
          formTeacherRemarks = 'N/A';
          headTeacherRemarks = 'N/A';
        });
      }
    } catch (e) {
      print("Error fetching school info: $e");
      // Set default values on error
      setState(() {
        schoolAddress = 'N/A';
        schoolPhone = 'N/A';
        schoolEmail = 'N/A';
        schoolAccount = 'N/A';
        nextTermDate = 'N/A';
        formTeacherRemarks = 'N/A';
        headTeacherRemarks = 'N/A';
      });
    }
  }

  Future<void> _fetchStudentSubjectsOptimized(String basePath) async {
    try {
      final snapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get(GetOptions(source: Source.cache)); // Try cache first

      if (snapshot.docs.isEmpty) {
        // If cache is empty, fetch from server
        final serverSnapshot = await _firestore
            .collection('$basePath/Student_Subjects')
            .get(GetOptions(source: Source.server));
        _processSubjectsData(serverSnapshot);
      } else {
        _processSubjectsData(snapshot);
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      // Try server if cache fails
      try {
        final serverSnapshot = await _firestore
            .collection('$basePath/Student_Subjects')
            .get(GetOptions(source: Source.server));
        _processSubjectsData(serverSnapshot);
      } catch (serverError) {
        print("Error fetching subjects from server: $serverError");
        setState(() {
          subjects = [];
        });
      }
    }
  }

  void _processSubjectsData(QuerySnapshot snapshot) {
    List<Map<String, dynamic>> subjectList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      int score = 0;
      if (data['Subject_Grade'] != null) {
        score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
      }

      int subjectPosition = _getIntValue(data, ['Subject_Position', 'position']);
      int totalStudentsInSubject = _getIntValue(data, ['Total_Students_Subject', 'totalStudents']);
      String gradeLetter = data['Grade_Letter']?.toString() ?? '';

      subjectList.add({
        'subject': data['Subject_Name']?.toString() ?? doc.id,
        'score': score,
        'position': subjectPosition,
        'totalStudents': totalStudentsInSubject,
        'gradeLetter': gradeLetter,
      });
    }

    setState(() {
      subjects = subjectList;
    });
  }

  int _getIntValue(Map<String, dynamic> data, List<String> keys) {
    for (String key in keys) {
      if (data[key] != null) {
        return (data[key] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  Future<void> _fetchTotalMarksOptimized(String basePath) async {
    try {
      final doc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Marks')
          .get(GetOptions(source: Source.cache)); // Try cache first

      DocumentSnapshot finalDoc = doc;
      if (!doc.exists) {
        // If not in cache, fetch from server
        finalDoc = await _firestore
            .doc('$basePath/TOTAL_MARKS/Marks')
            .get(GetOptions(source: Source.server));
      }

      if (finalDoc.exists && finalDoc.data() != null) {
        final data = finalDoc.data() as Map<String, dynamic>;
        setState(() {
          totalMarks = data;
          studentTotalMarks = (data['Student_Total_Marks'] as num?)?.toInt() ?? 0;
          teacherTotalMarks = (data['Teacher_Total_Marks'] as num?)?.toInt() ?? 0;
          studentPosition = (data['Student_Class_Position'] as num?)?.toInt() ?? 0;
          totalStudents = (data['Total_Class_Students_Number'] as num?)?.toInt() ?? 0;
          averageGradeLetter = data['Average_Grade_Letter']?.toString() ?? '';
          averagePercentage = (data['Average_Percentage'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        totalMarks = {};
        studentTotalMarks = 0;
        teacherTotalMarks = 0;
        studentPosition = 0;
        totalStudents = 0;
        averageGradeLetter = '';
        averagePercentage = 0.0;
      });
    }
  }

  Future<void> _fetchSubjectStatsOptimized(String school, String studentClass) async {
    try {
      // Use a more efficient query to get class statistics
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get(GetOptions(source: Source.cache)); // Try cache first

      QuerySnapshot finalSnapshot = studentsSnapshot;
      if (studentsSnapshot.docs.isEmpty) {
        finalSnapshot = await _firestore
            .collection('Schools/$school/Classes/$studentClass/Student_Details')
            .get(GetOptions(source: Source.server));
      }

      Map<String, List<int>> marksPerSubject = {};

      // Use Future.wait for parallel processing of student subjects
      List<Future> subjectFutures = [];

      for (var studentDoc in finalSnapshot.docs) {
        final studentName = studentDoc.id;
        subjectFutures.add(_processStudentSubjects(school, studentClass, studentName, marksPerSubject));
      }

      await Future.wait(subjectFutures);

      // Calculate averages
      Map<String, int> averages = {};
      marksPerSubject.forEach((subject, scores) {
        if (scores.isNotEmpty) {
          int total = scores.fold(0, (prev, el) => prev + el);
          int avg = (total / scores.length).round();
          averages[subject] = avg;
        }
      });

      setState(() {
        subjectStats = averages.map((key, value) => MapEntry(key, {'average': value}));
      });

    } catch (e) {
      print("Error calculating subject stats: $e");
      setState(() {
        subjectStats = {};
      });
    }
  }

  Future<void> _processStudentSubjects(String school, String studentClass, String studentName, Map<String, List<int>> marksPerSubject) async {
    try {
      final subjectsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects')
          .get();

      for (var subjectDoc in subjectsSnapshot.docs) {
        final data = subjectDoc.data();
        final subjectName = data['Subject_Name']?.toString() ?? subjectDoc.id;
        final gradeStr = data['Subject_Grade']?.toString() ?? '0';
        int grade = double.tryParse(gradeStr)?.round() ?? 0;

        if (!marksPerSubject.containsKey(subjectName)) {
          marksPerSubject[subjectName] = [];
        }
        marksPerSubject[subjectName]!.add(grade);
      }
    } catch (e) {
      print("Error processing subjects for $studentName: $e");
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

  Widget _buildSchoolHeader() {
    return Column(
      children: [
        Text(
          (schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          schoolAddress ?? 'N/A',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Text(
          'Tel: ${schoolPhone ?? 'N/A'}',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Text(
          'Email: ${schoolEmail ?? 'N/A'}',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'PROGRESS REPORT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          '${getAcademicYear()} '
              '${widget.studentClass} END OF TERM ${getCurrentTerm()} STUDENT\'S PROGRESS REPORT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text('NAME OF STUDENT: ${widget.studentFullName}'),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Text('POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}'),
                    SizedBox(width: 10),
                    Text('OUT OF: ${totalStudents > 0 ? totalStudents : 'N/A'}'),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text('CLASS: ${widget.studentClass}'),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(),
        columnWidths: {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.5),
          6: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: [
              _tableCell('SUBJECT', isHeader: true),
              _tableCell('MARKS %', isHeader: true),
              _tableCell('GRADE', isHeader: true),
              _tableCell('CLASS AVERAGE', isHeader: true),
              _tableCell('POSITION', isHeader: true),
              _tableCell('OUT OF', isHeader: true),
              _tableCell('TEACHERS\' COMMENTS', isHeader: true),
            ],
          ),
          ...subjects.map((subj) {
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

            return TableRow(
              children: [
                _tableCell(subjectName),
                _tableCell(score.toString()),
                _tableCell(grade),
                _tableCell(avg.toString()),
                _tableCell(subjectPosition > 0 ? subjectPosition.toString() : '-'),
                _tableCell(totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : '-'),
                _tableCell(remark),
              ],
            );
          }).toList(),
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: [
              _tableCell('TOTAL MARKS', isHeader: true),
              _tableCell(studentTotalMarks.toString(), isHeader: true),
              _tableCell(averageGradeLetter.isNotEmpty ? averageGradeLetter : 'F', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
              _tableCell('', isHeader: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'RESULT: $jceStatus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGradingKey() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JCE GRADING KEY FOR ${(schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase()}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Table(
            border: TableBorder.all(),
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _tableCell('Mark Range', isHeader: true),
                  _tableCell('85-100', isHeader: true),
                  _tableCell('75-84', isHeader: true),
                  _tableCell('65-74', isHeader: true),
                  _tableCell('50-64', isHeader: true),
                  _tableCell('0-49', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Grade', isHeader: true),
                  _tableCell('A'),
                  _tableCell('B'),
                  _tableCell('C'),
                  _tableCell('D'),
                  _tableCell('F'),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Interpretation', isHeader: true),
                  _tableCell('EXCELLENT'),
                  _tableCell('VERY GOOD'),
                  _tableCell('GOOD'),
                  _tableCell('PASS'),
                  _tableCell('FAIL'),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Form Teachers\' Remarks: ${formTeacherRemarks ?? 'N/A'}',
              style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 8),
          Text('Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
              style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fees for next term', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('School account: ${schoolAccount ?? 'N/A'}'),
          SizedBox(height: 8),
          Text('Next term begins on ${nextTermDate ?? 'N/A'}',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _printDocument() async {
    try {
      final pdfGenerator = Juniors_School_Report_PDF(
        studentClass: widget.studentClass,
        studentFullName: widget.studentFullName,
        subjects: subjects,
        subjectStats: subjectStats,
        studentTotalMarks: studentTotalMarks,
        teacherTotalMarks: teacherTotalMarks,
        studentPosition: studentPosition,
        totalStudents: totalStudents,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolPhone: schoolPhone,
        schoolEmail: schoolEmail,
        schoolAccount: schoolAccount,
        nextTermDate: nextTermDate,
        formTeacherRemarks: formTeacherRemarks,
        headTeacherRemarks: headTeacherRemarks,
        averageGradeLetter: averageGradeLetter,
        jceStatus: jceStatus,
      );

      await pdfGenerator.generateAndPrintPDF();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle error messages
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Report'),
        backgroundColor: Colors.white,
        actions: [
          if (!isLoading && !hasError)
            IconButton(
              icon: Icon(Icons.print),
              onPressed: _printDocument,
              tooltip: 'Print Report',
            ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text('Loading student report...'),
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
              'Error Loading Report',
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
              onPressed: _fetchStudentDataOptimized,
              child: Text('Try Again'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchStudentDataOptimized,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSchoolHeader(),
              _buildStudentInfo(),
              _buildReportTable(),
              _buildResultSection(),
              _buildGradingKey(),
              _buildRemarksSection(),
              _buildFooter(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}