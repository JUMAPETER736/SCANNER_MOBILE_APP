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


  // School Information
  String? schoolFees;
  String? schoolBankAccount;
  String? nextTermOpeningDate;
  String? userEmail;
  String? schoolName;
  String? schoolPhone;
  String? schoolEmail;
  String? schoolAccount;
  String? formTeacherRemarks;
  String? headTeacherRemarks;
  int boxNumber = 0;
  String schoolLocation = 'N/A';

  // State variables
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
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

  Future<void> _fetchStudentData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
      return;
    }

    userEmail = user.email;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

      if (!userDoc.exists) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'User details not found.';
        });
        return;
      }

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Classes before accessing reports.';
        });
        return;
      }

      schoolName = teacherSchool;
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 1' && studentClass != 'FORM 2') {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Only students in FORM 1 or FORM 2 can access this report.';
        });
        return;
      }

      final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

      // Fetch all data concurrently for better performance
      await Future.wait([
        _fetchSchoolInfo(teacherSchool),
        _fetchStudentSubjects(basePath),
        _fetchTotalMarks(basePath),
        _fetchSubjectStats(teacherSchool, studentClass),
        _updateTotalStudentsCount(teacherSchool, studentClass),
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data: ${e.toString()}';
      });
    }
  }

// _fetchSchoolInfo method to fetch from the new path structure
  Future<void> _fetchSchoolInfo(String school) async {
    try {
      DocumentSnapshot schoolInfoDoc = await _firestore
          .collection('Schools')
          .doc(school)
          .collection('School_Information')
          .doc('School_Details')
          .get();

      setState(() {
        schoolPhone = schoolInfoDoc['Telephone'] ?? 'N/A';
        schoolEmail = schoolInfoDoc['Email'] ?? 'N/A';
        boxNumber = schoolInfoDoc['boxNumber'] ?? 0;
        schoolLocation = schoolInfoDoc['schoolLocation'] ?? 'N/A';
        schoolFees = schoolInfoDoc['School_Fees'] ?? 'N/A';
        schoolBankAccount = schoolInfoDoc['School_Bank_Account'] ?? 'N/A';
        nextTermOpeningDate = schoolInfoDoc['Next_Term_Opening_Date'] ?? 'N/A';
      });
    } catch (e) {
      print("Error fetching school info: $e");
      setState(() {
        schoolPhone = 'N/A';
        schoolEmail = 'N/A';
        schoolAccount = 'N/A';
        boxNumber = 0;
        schoolLocation = 'N/A';
        schoolFees = 'N/A';
        schoolBankAccount = 'N/A';
        nextTermOpeningDate = 'N/A';
      });
    }
  }

  Future<void> _fetchStudentSubjects(String basePath) async {
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

      setState(() {
        subjects = subjectList;
      });
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  Future<void> _fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore.doc('$basePath/TOTAL_MARKS/Marks').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          totalMarks = data;
          studentTotalMarks = (data['Student_Total_Marks'] as num?)?.toInt() ?? 0;
          teacherTotalMarks = (data['Teacher_Total_Marks'] as num?)?.toInt() ?? 0;
          studentPosition = (data['Student_Class_Position'] as num?)?.toInt() ?? 0;
          totalStudents = (data['Total_Class_Students_Number'] as num?)?.toInt() ?? 0;
          averageGradeLetter = data['Average_Grade_Letter']?.toString() ?? '';
          averagePercentage = (data['Average_Percentage'] as num?)?.toDouble() ?? 0.0;
          jceStatus = data['JCE_Status']?.toString() ?? (studentTotalMarks >= 550 ? 'PASS' : 'FAIL');
        });
      }

      // Fetch remarks from the correct path
      final remarksDoc = await _firestore.doc('$basePath/TOTAL_MARKS/Results_Remarks').get();
      if (remarksDoc.exists) {
        final remarksData = remarksDoc.data() as Map<String, dynamic>;
        setState(() {
          formTeacherRemarks = remarksData['Form_Teacher_Remark']?.toString() ?? 'N/A';
          headTeacherRemarks = remarksData['Head_Teacher_Remark']?.toString() ?? 'N/A';
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
    }
  }

// Replace the existing _fetchSubjectStats method with this updated version
  Future<void> _fetchSubjectStats(String school, String studentClass) async {
    try {
      // Fetch subject averages from the new Class_Performance structure
      final subjectStatsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Class_Performance/Subject_Performance/Subjects')
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

      // If no data found in new structure, try the old structure as fallback
      if (stats.isEmpty) {
        final oldStatsDoc = await _firestore
            .doc('Schools/$school/Classes/$studentClass/Class_Statistics/subject_averages')
            .get();

        if (oldStatsDoc.exists) {
          final data = oldStatsDoc.data() as Map<String, dynamic>;
          stats = data;
        }
      }

      setState(() {
        subjectStats = stats;
      });
    } catch (e) {
      print("Error fetching subject statistics: $e");
    }
  }

  // Keep this method as requested - it calculates and updates total students count
  Future<void> _updateTotalStudentsCount(String school, String studentClass) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      int totalStudentsCount = studentsSnapshot.docs.length;

      // Update the total students count for all students in the class
      final batch = _firestore.batch();
      for (var studentDoc in studentsSnapshot.docs) {
        final totalMarksRef = _firestore
            .doc('Schools/$school/Classes/$studentClass/Student_Details/${studentDoc.id}/TOTAL_MARKS/Marks');

        batch.update(totalMarksRef, {
          'Total_Class_Students_Number': totalStudentsCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        totalStudents = totalStudentsCount;
      });
    } catch (e) {
      print("Error updating total students count: $e");
    }
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 85) return 'A';
    if (percentage >= 75) return 'B';
    if (percentage >= 65) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
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
          'P.O. BOX ${boxNumber ?? 0}, ${schoolLocation?.toUpperCase() ?? 'N/A'}',
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive font size based on screen width
              double baseFontSize = constraints.maxWidth > 600 ? 14 : 12;
              double responsiveFontSize = constraints.maxWidth < 400 ? 10 : baseFontSize;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Student Name
                    Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth * 0.4,
                        maxWidth: constraints.maxWidth * 0.5,
                      ),
                      child: Text(
                        'NAME OF STUDENT: ${widget.studentFullName}',
                        style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(width: 20),

                    // Position
                    Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth * 0.12,
                      ),
                      child: Text(
                        'POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}',
                        style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(width: 15),

                    // Out of
                    Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth * 0.12,
                      ),
                      child: Text(
                        'OUT OF: ${totalStudents > 0 ? totalStudents : 'N/A'}',
                        style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(width: 15),

                    // Class
                    Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth * 0.15,
                      ),
                      child: Text(
                        'CLASS: ${widget.studentClass}',
                        style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(width: 15),

                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // Also update the _buildReportTable method to properly use the subject average
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

            // Updated to fetch from the new structure
            final subjectStat = subjectStats[subjectName];
            final avg = subjectStat != null
                ? (subjectStat['average'] as num?)?.round() ?? 0
                : 0;

            final subjectPosition = subj['position'] as int? ?? 0;
            final totalStudentsForSubject = subj['totalStudents'] as int? ?? 0;

            return TableRow(
              children: [
                _tableCell(subjectName),
                _tableCell(score.toString()),
                _tableCell(grade),
                _tableCell(avg.toString()), // This now uses Subject_Average from Firestore
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
              _tableCell(averageGradeLetter.isNotEmpty ? averageGradeLetter : ' ', isHeader: true),
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
          Text(
            'Form Teacher\'s Remarks: ${formTeacherRemarks ?? 'N/A'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Head Teacher\'s Remarks: ${headTeacherRemarks ?? 'N/A'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'School Fees: ${schoolFees ?? 'N/A'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'School Bank Account: ${schoolBankAccount ?? 'N/A'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Next Term Opening Date: ${nextTermOpeningDate ?? 'N/A'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }


// Update the _printDocument method to pass the new fields
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
        schoolPhone: schoolPhone,
        schoolEmail: schoolEmail,
        schoolAccount: schoolAccount,
        formTeacherRemarks: formTeacherRemarks,
        headTeacherRemarks: headTeacherRemarks,
        averageGradeLetter: averageGradeLetter,
        jceStatus: jceStatus,
        schoolFees: schoolFees,
        boxNumber: boxNumber,
        schoolLocation: schoolLocation,
        schoolBankAccount: schoolBankAccount,
        nextTermOpeningDate: nextTermOpeningDate,
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
        backgroundColor: Colors.grey[300], // Light gray color
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printDocument,
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
              onPressed: _fetchStudentData,
              child: Text('Try Again'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
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
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}