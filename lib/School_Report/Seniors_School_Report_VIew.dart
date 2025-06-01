import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Seniors_School_Report_PDF.dart';

class Seniors_School_Report_View extends StatefulWidget {
  final String studentClass;
  final String studentFullName;

  const Seniors_School_Report_View({
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Seniors_School_Report_ViewState createState() => _Seniors_School_Report_ViewState();
}

class _Seniors_School_Report_ViewState extends State<Seniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  Map<String, dynamic> subjectStats = {};
  Map<String, int> subjectPositions = {};
  Map<String, int> totalStudentsPerSubject = {};
  int studentPosition = 0;
  int Total_Class_Students_Number = 0;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;
  String? schoolName;
  String? schoolAddress;
  String? schoolPhone;
  String? schoolEmail;
  String? schoolAccount;
  String? nextTermDate;
  String? formTeacherRemarks;
  String? headTeacherRemarks;
  int studentTotalMarks = 0;
  int teacherTotalMarks = 0;
  int aggregatePoints = 0;
  int aggregatePosition = 0;
  String averageGradeLetter = '';
  String msceStatus = '';
  String msceMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentDataWithTimeout(); // Use the timeout version
  }

  // Method to determine current term based on date
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

  // Method to get academic year
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

  Map<String, dynamic> calculateMSCEAggregate(List<int> subjectPoints) {
    if (subjectPoints.length < 6) {
      return {
        'status': 'STATEMENT',
        'points': 0,
        'message': 'Insufficient subjects (less than 6)'
      };
    }

    subjectPoints.sort();
    List<int> bestSix = subjectPoints.take(6).toList();
    int totalPoints = bestSix.fold(0, (sum, point) => sum + point);

    if (bestSix.contains(9)) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Contains Grade 9 in best six subjects'
      };
    }

    if (totalPoints > 48) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Total points exceed 48'
      };
    }

    return {
      'status': 'PASS',
      'points': totalPoints,
      'message': 'Qualified aggregate'
    };
  }

  Future<void> _fetchStudentDataWithTimeout() async {
    try {
      await _fetchStudentData().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            isLoading = false;
            hasError = true;

          });
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchStudentData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'No user is currently logged in.';
        });
      }
      return;
    }

    userEmail = user.email;

    try {
      // Use parallel execution for independent operations
      final futures = <Future>[
        _firestore.collection('Teachers_Details').doc(userEmail).get(),
      ];

      final results = await Future.wait(futures);
      final userDoc = results[0] as DocumentSnapshot;

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'User details not found.';
          });
        }
        return;
      }

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Please select a School and Classes before accessing reports.';
          });
        }
        return;
      }

      schoolName = teacherSchool;
      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 3' && studentClass != 'FORM 4') {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Only students in FORM 3 or FORM 4 can access this report.';
          });
        }
        return;
      }

      final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

      // Execute all data fetching operations in parallel
      await Future.wait([
        _fetchSchoolInfo(teacherSchool),
        fetchStudentSubjects(basePath),
        fetchTotalMarks(basePath),
        _updateTotalStudentsCount(teacherSchool, studentClass),
      ]);

      // Execute calculations in parallel (these depend on the above data)
      await Future.wait([
        calculate_Subject_Stats_And_Position(teacherSchool, studentClass, studentFullName),
        calculate_Aggregate_Points_And_Position(teacherSchool, studentClass, studentFullName),
        _calculateAndUpdateAverageGradeLetter(basePath),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'An error occurred while fetching data.';
        });
      }
    }
  }

  Future<void> _calculateAndUpdateAverageGradeLetter(String basePath) async {
    try {
      if (teacherTotalMarks > 0) {
        // Calculate percentage
        double percentage = (studentTotalMarks / teacherTotalMarks) * 100;

        // Determine grade letter based on percentage
        String gradeLetter = Seniors_Grade(percentage.round());

        // Update Firestore with the calculated average grade letter
        await _firestore.doc('$basePath/TOTAL_MARKS/Marks').update({
          'Average_Grade_Letter': gradeLetter,
          'Average_Percentage': percentage,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            averageGradeLetter = gradeLetter;
          });
        }

        print("Average Grade Letter calculated: $gradeLetter (${percentage.toStringAsFixed(1)}%)");
      }
    } catch (e) {
      print("Error calculating average grade letter: $e");
      // Set default if calculation fails
      if (mounted) {
        setState(() {
          averageGradeLetter = '9';
        });
      }
    }
  }


  Future<void> calculate_Aggregate_Points_And_Position(
      String school, String studentClass, String studentFullName) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      List<Map<String, dynamic>> studentAggregates = [];

      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;
        final subjectsSnapshot = await _firestore
            .collection(
            'Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects')
            .get();

        List<int> points = [];
        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final gradeStr = data['Subject_Grade']?.toString() ?? 'N/A';

          // Skip subjects with N/A grades
          if (gradeStr == 'N/A' || gradeStr == null) continue;

          int grade = double.tryParse(gradeStr)?.round() ?? 0;
          final pointsStr = getPoints(Seniors_Grade(grade));
          points.add(int.tryParse(pointsStr) ?? 9);
        }

        // Calculate MSCE aggregate using the new function
        Map<String, dynamic> msceResult = calculateMSCEAggregate(points);
        int aggregate = msceResult['points'];

        studentAggregates.add({
          'name': studentName,
          'aggregate': aggregate,
          'status': msceResult['status'],
          'message': msceResult['message']
        });

        // Update student's MSCE status in Firestore
        final basePath = 'Schools/$school/Classes/$studentClass/Student_Details/$studentName';
        await _firestore.doc('$basePath/TOTAL_MARKS/Marks').update({
          'MSCE_Status': msceResult['status'],
          'MSCE_Message': msceResult['message'],
          'Best_Six_Total_Points': aggregate,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      studentAggregates.sort((a, b) =>
          (a['aggregate'] as int).compareTo(b['aggregate'] as int));

      for (int i = 0; i < studentAggregates.length; i++) {
        if (studentAggregates[i]['name'] == studentFullName) {
          setState(() {
            aggregatePosition = i + 1;
            msceStatus = studentAggregates[i]['status'];
            msceMessage = studentAggregates[i]['message'];
          });
          break;
        }
      }

      List<int> currentStudentPoints = subjects
          .where((subj) => subj['hasGrade'] == true)
          .map((subj) {
        final score = subj['score'] as int? ?? 0;
        final grade = Seniors_Grade(score);
        return int.tryParse(getPoints(grade)) ?? 9;
      }).toList();

      Map<String, dynamic> currentMsceResult = calculateMSCEAggregate(
          currentStudentPoints);

      setState(() {
        aggregatePoints = currentMsceResult['points'];
        msceStatus = currentMsceResult['status'];
        msceMessage = currentMsceResult['message'];
      });
    } catch (e) {
      print("Error calculating aggregate points and position: $e");
    }
  }


  Future<void> _fetchSchoolInfo(String school) async {
    try {
      DocumentSnapshot schoolDoc = await _firestore.collection('Schools').doc(school).get();
      if (schoolDoc.exists) {
        setState(() {
          schoolAddress = schoolDoc['address'];
          schoolPhone = schoolDoc['phone'];
          schoolEmail = schoolDoc['email'];
          schoolAccount = schoolDoc['account'];
          nextTermDate = schoolDoc['nextTermDate'];
          formTeacherRemarks = schoolDoc['formTeacherRemarks'];
          headTeacherRemarks = schoolDoc['headTeacherRemarks'];
        });
      }
    } catch (e) {
      print("Error fetching school info: $e");
    }
  }

  Future<void> _updateTotalStudentsCount(String school, String studentClass) async {
    try {
      final classInfoDoc = await _firestore
          .collection('Schools')
          .doc(school)
          .collection('Classes')
          .doc(studentClass)
          .collection('Class_Info')
          .doc('Info')
          .get();

      if (classInfoDoc.exists) {
        final classData = classInfoDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            Total_Class_Students_Number = classData['totalStudents'] ?? 0;
          });
        }
      } else {
        final studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(school)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .get();

        Total_Class_Students_Number = studentsSnapshot.docs.length;

        await _firestore
            .collection('Schools')
            .doc(school)
            .collection('Classes')
            .doc(studentClass)
            .collection('Class_Info')
            .doc('Info')
            .set({
          'totalStudents': Total_Class_Students_Number,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            // UI will update with correct count
          });
        }
      }
      print("Total Students: $Total_Class_Students_Number");
    } catch (e) {
      print('Error updating total students count: $e');
    }
  }


  Future<void> fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get(GetOptions(source: Source.serverAndCache)); // Use cache when available

      List<Map<String, dynamic>> subjectList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        int score = 0;
        bool hasGrade = true;

        if (data['Subject_Grade'] == 'N/A' || data['Subject_Grade'] == null) {
          hasGrade = false;
        } else {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }

        int subjectPosition = (data['Subject_Position'] as num?)?.toInt() ?? 0;
        int totalStudentsInSubject = (data['Total_Students_Subject'] as num?)?.toInt() ?? 0;
        String gradeLetter = hasGrade ? Seniors_Grade(score) : '';

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': hasGrade ? score : null,
          'position': subjectPosition,
          'totalStudents': totalStudentsInSubject,
          'gradeLetter': gradeLetter,
          'hasGrade': hasGrade,
        });
      }

      setState(() {
        subjects = subjectList;
      });
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }


  Future<void> fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Marks')
          .get(GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        int safeParse(dynamic value) {
          if (value == null) return 0;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
          return 0;
        }

        setState(() {
          totalMarks = data;
          studentTotalMarks = safeParse(data['Student_Total_Marks']);
          teacherTotalMarks = safeParse(data['Teacher_Total_Marks']) == 0
              ? (subjects.where((s) => s['hasGrade'] == true).length * 100)
              : safeParse(data['Teacher_Total_Marks']);
          studentPosition = safeParse(data['Student_Class_Position']);
          // Use the total from Firestore if available
          if (data['Total_Class_Students_Number'] != null) {
            Total_Class_Students_Number = safeParse(data['Total_Class_Students_Number']);
          }
          averageGradeLetter = data['Average_Grade_Letter']?.toString() ?? '';
          msceStatus = data['MSCE_Status']?.toString() ?? '';
          msceMessage = data['MSCE_Message']?.toString() ?? '';
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        studentTotalMarks = 0;
        teacherTotalMarks = subjects.where((s) => s['hasGrade'] == true).length * 100;
        studentPosition = 0;
        averageGradeLetter = '';
        msceStatus = '';
        msceMessage = '';
      });
    }
  }


  Future<void> calculate_Subject_Stats_And_Position(
      String school, String studentClass, String studentFullName) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Schools/$school/Classes/$studentClass/Student_Details')
          .get();

      Map<String, List<int>> marksPerSubject = {};
      Map<String, List<Map<String, dynamic>>> subjectStudentData = {};

      // Collect all students' marks for each subject
      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        final subjectsSnapshot = await _firestore
            .collection('Schools/$school/Classes/$studentClass/Student_Details/$studentName/Student_Subjects')
            .get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? 'N/A';

          // Skip students who don't take the subject (N/A grades)
          if (gradeStr == 'N/A' || gradeStr == null) continue;

          int grade = double.tryParse(gradeStr)?.round() ?? 0;

          if (!marksPerSubject.containsKey(subjectName)) {
            marksPerSubject[subjectName] = [];
            subjectStudentData[subjectName] = [];
          }

          marksPerSubject[subjectName]!.add(grade);
          subjectStudentData[subjectName]!.add({
            'studentName': studentName,
            'grade': grade,
          });
        }
      }

      // Calculate positions and update Firestore
      for (String subjectName in subjectStudentData.keys) {
        var studentList = subjectStudentData[subjectName]!;

        // Sort by grade in descending order
        studentList.sort((a, b) => b['grade'].compareTo(a['grade']));

        // Calculate positions (handle ties)
        Map<String, int> positions = {};
        int currentPosition = 1;

        for (int i = 0; i < studentList.length; i++) {
          String currentStudentName = studentList[i]['studentName'];
          int currentGrade = studentList[i]['grade'];

          if (i > 0 && studentList[i-1]['grade'] != currentGrade) {
            currentPosition = i + 1;
          }

          positions[currentStudentName] = currentPosition;

          // Update the position in Firestore for each student
          try {
            await _firestore
                .doc('Schools/$school/Classes/$studentClass/Student_Details/$currentStudentName/Student_Subjects/$subjectName')
                .update({
              'Subject_Position': currentPosition,
              'Total_Students_Subject': studentList.length, // Only count students who actually take the subject
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            print("Error updating position for $currentStudentName in $subjectName: $e");
          }
        }
      }

      // Calculate averages and update subject stats
      Map<String, int> averages = {};
      Map<String, int> totalStudentsPerSubjectMap = {};

      marksPerSubject.forEach((subject, scores) {
        int total = scores.fold(0, (prev, el) => prev + el);
        int avg = scores.isNotEmpty ? (total / scores.length).round() : 0;
        averages[subject] = avg;
        totalStudentsPerSubjectMap[subject] = scores.length; // Only students who take the subject
      });

      setState(() {
        subjectStats = averages.map((key, value) => MapEntry(key, {'average': value}));
        totalStudentsPerSubject = totalStudentsPerSubjectMap;
      });

      // Refresh student subjects data to get updated positions
      final String basePath = 'Schools/$school/Classes/$studentClass/Student_Details/$studentFullName';
      await fetchStudentSubjects(basePath);

    } catch (e) {
      print("Error calculating stats & position: $e");
    }
  }

  String Seniors_Grade(int Seniors_Score) {
    if (Seniors_Score >= 90) return '1';
    if (Seniors_Score >= 80) return '2';
    if (Seniors_Score >= 75) return '3';
    if (Seniors_Score >= 70) return '4';
    if (Seniors_Score >= 65) return '5';
    if (Seniors_Score >= 60) return '6';
    if (Seniors_Score >= 55) return '7';
    if (Seniors_Score >= 50) return '8';
    return '9';
  }

  String getRemark(String Seniors_Grade) {
    switch (Seniors_Grade) {
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

  String getPoints(String Seniors_Grade) {
    switch (Seniors_Grade) {
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

  Widget _buildSchoolHeader() {
    return Column(
      children: [
        Text(
          (schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (schoolAddress != null)
          Text(
            schoolAddress!,
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        if (schoolPhone != null)
          Text(
            'Tel: $schoolPhone',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        if (schoolEmail != null)
          Text(
            'Email: $schoolEmail',
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text('NAME OF STUDENT: ${widget.studentFullName}'),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text('POSITION: ${studentPosition > 0 ? studentPosition : 'N/A'}'),
                SizedBox(width: 10),
                Text('OUT OF: ${Total_Class_Students_Number > 0 ? Total_Class_Students_Number :
                (subjects.isNotEmpty ? subjects.first['totalStudents'] ?? 'N/A' : 'N/A')}'),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('CLASS: ${widget.studentClass}'),
          ),
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
              _tableCell('POINTS', isHeader: true),
              _tableCell('CLASS AVERAGE', isHeader: true),
              _tableCell('POSITION', isHeader: true),
              _tableCell('OUT OF', isHeader: true),
              _tableCell('TEACHERS\' COMMENTS', isHeader: true),
            ],
          ),
          ...subjects.map((subj) {
            final subjectName = subj['subject'] ?? 'Unknown';
            final hasGrade = subj['hasGrade'] as bool? ?? true;
            final score = subj['score'] as int? ?? 0;
            final grade = hasGrade ? (subj['gradeLetter']?.toString().isNotEmpty == true
                ? subj['gradeLetter']
                : Seniors_Grade(score)) : '';
            final remark = hasGrade ? getRemark(grade) : 'Doesn\'t take';
            final points = hasGrade ? getPoints(grade) : '';
            final subjectStat = subjectStats[subjectName];
            final avg = subjectStat != null ? subjectStat['average'] as int : 0;
            final subjectPosition = subj['position'] as int? ?? 0;
            final totalStudentsForSubject = subj['totalStudents'] as int? ?? 0;

            return TableRow(
              children: [
                _tableCell(subjectName),
                _tableCell(hasGrade ? score.toString() : ''),
                _tableCell(points),
                _tableCell(hasGrade ? avg.toString() : ''),
                _tableCell(hasGrade && subjectPosition > 0 ? subjectPosition.toString() : ''),
                _tableCell(hasGrade && totalStudentsForSubject > 0 ? totalStudentsForSubject.toString() : ''),
                _tableCell(remark),
              ],
            );
          }).toList(),
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

  Widget _buildAggregateSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('(Best 6 subjects)', style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AGGREGATE POINTS: $aggregatePoints'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RESULT: $msceStatus'),

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
            'MSCE GRADING KEY FOR ${(schoolName ?? 'UNKNOWN SECONDARY SCHOOL').toUpperCase()}',
            style: TextStyle(fontWeight: FontWeight.bold),
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
              6: FlexColumnWidth(1),
              7: FlexColumnWidth(1),
              8: FlexColumnWidth(1),
              9: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _tableCell('Mark Range', isHeader: true),
                  _tableCell('100-90', isHeader: true),
                  _tableCell('89-80', isHeader: true),
                  _tableCell('79-75', isHeader: true),
                  _tableCell('74-70', isHeader: true),
                  _tableCell('69-65', isHeader: true),
                  _tableCell('64-60', isHeader: true),
                  _tableCell('59-55', isHeader: true),
                  _tableCell('54-50', isHeader: true),
                  _tableCell('0-49', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Points', isHeader: true),
                  _tableCell('1', isHeader: true),
                  _tableCell('2', isHeader: true),
                  _tableCell('3', isHeader: true),
                  _tableCell('4', isHeader: true),
                  _tableCell('5', isHeader: true),
                  _tableCell('6', isHeader: true),
                  _tableCell('7', isHeader: true),
                  _tableCell('8', isHeader: true),
                  _tableCell('9', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('Interpretation', isHeader: true),
                  _tableCell('Distinction', isHeader: true),
                  _tableCell('Distinction', isHeader: true),
                  _tableCell('Strong Credit', isHeader: true),
                  _tableCell('Strong Credit', isHeader: true),
                  _tableCell('Credit', isHeader: true),
                  _tableCell('Weak Credit', isHeader: true),
                  _tableCell('Pass', isHeader: true),
                  _tableCell('Weak Pass', isHeader: true),
                  _tableCell('Fail', isHeader: true),
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
    final pdfGenerator = Seniors_School_Report_PDF(
      schoolName: schoolName,
      schoolAddress: schoolAddress,
      schoolPhone: schoolPhone,
      schoolEmail: schoolEmail,
      schoolAccount: schoolAccount,
      nextTermDate: nextTermDate,
      formTeacherRemarks: formTeacherRemarks,
      headTeacherRemarks: headTeacherRemarks,
      studentFullName: widget.studentFullName,
      studentClass: widget.studentClass,
      subjects: subjects,
      subjectStats: subjectStats,
      subjectPositions: subjectPositions,
      totalStudentsPerSubject: totalStudentsPerSubject,
      aggregatePoints: aggregatePoints,
      aggregatePosition: aggregatePosition,
      Total_Class_Students_Number: Total_Class_Students_Number,
      studentTotalMarks: studentTotalMarks,
      teacherTotalMarks: teacherTotalMarks,
      studentPosition: studentPosition,
    );

    await pdfGenerator.generateAndPrint();
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Report'),
        actions: [
          IconButton(icon: Icon(Icons.print), onPressed: _printDocument),
        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              _buildSchoolHeader(),
              _buildStudentInfo(),
              _buildReportTable(),
              _buildAggregateSection(),
              _buildGradingKey(),
              _buildRemarksSection(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}