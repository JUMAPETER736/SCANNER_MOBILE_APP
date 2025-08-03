import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Student_Subjects extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const Student_Subjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  _Student_SubjectsState createState() => _Student_SubjectsState();
}

class _Student_SubjectsState extends State<Student_Subjects> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _subjects = [];
  List<String> _userSubjects = [];
  List<String> _userClasses = [];
  Map<String, String> _subjectGrades = {}; // Cache grades
  bool isLoading = true;

  // Class performance data storage
  Map<String, dynamic> classPerformance = {};
  Map<String, dynamic> subjectPerformance = {};

  Future<void> _fetchSubjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Use a single query to get teacher details
      final userDoc = await _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email)
          .get();

      if (!userDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      String schoolName = userData['school'] ?? '';
      String className = widget.studentClass;

      // Fetch user's subjects and classes in parallel
      List<String> userSubjectsList = List<String>.from(userData['subjects'] ?? []);
      List<String> userClassesList = List<String>.from(userData['classes'] ?? []);

      // Use batch operations for better performance
      final batch = _firestore.batch();

      // Get specific student's subjects directly instead of querying all students
      final studentSubjectsRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Student_Subjects');

      final studentSubjectsSnapshot = await studentSubjectsRef.get();

      Set<String> subjectsSet = {};
      Map<String, String> gradesMap = {};

      // Process student's subjects and grades in a single loop
      for (var doc in studentSubjectsSnapshot.docs) {
        String subjectName = doc['Subject_Name']?.toString() ?? doc.id;
        String grade = doc['Subject_Grade']?.toString() ?? '';

        subjectsSet.add(subjectName);
        if (grade.isNotEmpty) {
          gradesMap[subjectName] = grade;
        }
      }

      // If no subjects found for this student, fetch from class level (fallback)
      if (subjectsSet.isEmpty) {
        final classRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details');

        final classSnapshot = await classRef.limit(5).get(); // Limit to improve performance

        for (var studentDoc in classSnapshot.docs) {
          final subjectSnapshot = await studentDoc.reference
              .collection('Student_Subjects')
              .limit(10) // Limit subjects per student
              .get();

          for (var subjectDoc in subjectSnapshot.docs) {
            subjectsSet.add(subjectDoc['Subject_Name']?.toString() ?? subjectDoc.id);
          }

          // Break after finding some subjects to improve performance
          if (subjectsSet.isNotEmpty) break;
        }
      }

      setState(() {
        _subjects = subjectsSet.toList()..sort(); // Sort for consistent display
        _userSubjects = userSubjectsList;
        _userClasses = userClassesList;
        _subjectGrades = gradesMap;
        isLoading = false;
      });

      print("All subjects: $_subjects");
      print("User's assigned Subjects: $_userSubjects");
      print("User's assigned Classes: $_userClasses");
      print("Current student class: ${widget.studentClass}");
    } catch (e) {
      print('Error fetching Subjects: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to check if teacher can edit this subject
  bool _canEditSubject(String subject) {
    // Check if the current class is in teacher's assigned classes
    if (!_userClasses.contains(widget.studentClass)) {
      return false;
    }

    // If teacher has only one class, they can edit all their assigned subjects
    if (_userClasses.length == 1) {
      return _userSubjects.contains(subject);
    }

    // For multiple classes, use index-based matching (original logic)
    int classIndex = _userClasses.indexOf(widget.studentClass);

    // Check if there's a subject at the same index position
    if (classIndex < _userSubjects.length) {
      String subjectAtSameIndex = _userSubjects[classIndex];
      return subjectAtSameIndex == subject;
    }

    return false;
  }

  // Optimized grade fetching - use cached data first
  Future<String> _fetchGradeForSubject(String subject) async {
    // Return cached grade if available
    if (_subjectGrades.containsKey(subject)) {
      return _subjectGrades[subject]!;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'N/A';

      final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        String schoolName = docSnapshot['school'] ?? '';
        String className = widget.studentClass;

        final gradeRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details')
            .doc(widget.studentName)
            .collection('Student_Subjects')
            .doc(subject);

        final gradeSnapshot = await gradeRef.get();

        if (gradeSnapshot.exists) {
          final grade = gradeSnapshot['Subject_Grade'];
          if (grade != null && grade.isNotEmpty) {
            print("Fetched Grade for $subject: $grade");
            // Cache the grade
            _subjectGrades[subject] = grade.toString();
            return grade.toString();
          }
        }
      }
    } catch (e) {
      print('Error fetching Grade for Subject: $e');
    }
    return '';
  }

  // Enhanced comprehensive position calculation for all students in the class
  Future<void> _calculateSubjectStatsAndPosition(String schoolName, String className) async {
    try {
      print("Starting Student Subject Positioning calculation...");

      final studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$className/Student_Details')
          .get();

      Map<String, List<int>> marksPerSubject = {};
      Map<String, List<Map<String, dynamic>>> subjectStudentData = {};

      // Collect all students' marks for each subject
      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        final subjectsSnapshot = await _firestore
            .collection('Schools/$schoolName/Classes/$className/Student_Details/$studentName/Student_Subjects')
            .get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? 'N/A';

          // Skip students who don't take the subject (N/A grades)
          if (gradeStr == 'N/A' || gradeStr == null || gradeStr.isEmpty) continue;

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

      // Calculate positions and update Firestore for each subject
      for (String subjectName in subjectStudentData.keys) {
        var studentList = subjectStudentData[subjectName]!;

        // Sort by grade in descending order
        studentList.sort((a, b) => b['grade'].compareTo(a['grade']));

        // Calculate positions (handle ties properly)
        Map<String, int> positions = {};
        int currentPosition = 1;

        for (int i = 0; i < studentList.length; i++) {
          String currentStudentName = studentList[i]['studentName'];
          int currentGrade = studentList[i]['grade'];

          // Handle ties - if previous grade is different, update position
          if (i > 0 && studentList[i-1]['grade'] != currentGrade) {
            currentPosition = i + 1;
          }

          positions[currentStudentName] = currentPosition;

          // Update the position in Firestore for each student
          try {
            await _firestore
                .doc('Schools/$schoolName/Classes/$className/Student_Details/$currentStudentName/Student_Subjects/$subjectName')
                .update({
              'Subject_Position': currentPosition,
              'Total_Students_Subject': studentList.length, // Only count students who actually take the subject
              'lastUpdated': FieldValue.serverTimestamp(),
            });

            print("Updated Position for $currentStudentName in $subjectName: Position $currentPosition of ${studentList.length}");
          } catch (e) {
            print("Error updating Position for $currentStudentName in $subjectName: $e");
          }
        }
      }

      print("Student Subject Positioning Calculations Completed Successfully!");

    } catch (e) {
      print("Error in Subject Positioning Calculations: $e");
    }
  }


  Map<String, dynamic> calculateMSCEAggregate(List<int> subjectPoints) {
    if (subjectPoints.length < 6) {
      return {
        'status': 'STATEMENT',
        'points': 0,
        'message': 'Insufficient Subjects (less than 6)'
      };
    }

    subjectPoints.sort();
    List<int> bestSix = subjectPoints.take(6).toList();
    int totalPoints = bestSix.fold(0, (sum, point) => sum + point);

    if (bestSix.contains(9)) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Contains Grade 9 in Best Six Subjects'
      };
    }

    if (totalPoints > 48) {
      return {
        'status': 'STATEMENT',
        'points': totalPoints,
        'message': 'Total Points Exceed 48'
      };
    }

    return {
      'status': 'PASS',
      'points': totalPoints,
      'message': 'Qualified Aggregate'
    };
  }

// Method to process student data and calculate totals
  Future<void> _processStudentData(String schoolName, String className, String studentName) async {
    try {
      // Get student's subjects and grades
      final subjectsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('Student_Subjects')
          .get();

      bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';
      bool isJunior = className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2';

      if (isJunior) {
        // Process junior student (Form 1 & 2)
        await _processJuniorStudent(schoolName, className, studentName, subjectsSnapshot);
      } else if (isSenior) {
        // Process senior student (Form 3 & 4)
        await _processSeniorStudent(schoolName, className, studentName, subjectsSnapshot);
      }
    } catch (e) {
      print("Error Processing Student data for $studentName: $e");
    }
  }

// Process junior student data
  Future<void> _processJuniorStudent(
      String schoolName, String className,
      String studentName, QuerySnapshot subjectsSnapshot) async {
    try {
      int totalMarks = 0;
      int totalPossibleMarks = 0;

      for (var subjectDoc in subjectsSnapshot.docs) {
        var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};
        if (subjectData.containsKey('Subject_Grade')) {
          var subjectGradeValue = subjectData['Subject_Grade'];

          if (subjectGradeValue == null ||
              subjectGradeValue.toString().toUpperCase() == 'N/A') {
            continue;
          }

          int subjectGrade = 0;
          if (subjectGradeValue is int) {
            subjectGrade = subjectGradeValue;
          } else if (subjectGradeValue is String) {
            subjectGrade = int.tryParse(subjectGradeValue) ?? 0;
          }

          if (subjectGrade > 0) {
            totalMarks += subjectGrade;
            totalPossibleMarks += 100;
          }
        }
      }

      String jceStatus = totalMarks >= 550 ? 'PASS' : 'FAIL';

      // Update student's total marks document
      DocumentReference marksRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('TOTAL_MARKS')
          .doc('Marks');

      Map<String, dynamic> updateData = {

        'Student_Total_Marks': totalMarks,
        'Teacher_Total_Marks': totalPossibleMarks,
        'JCE_Status': jceStatus,
      };

      await marksRef.set(updateData, SetOptions(merge: true));

      print("Junior Student $studentName processed: $totalMarks/$totalPossibleMarks - $jceStatus");
    } catch (e) {
      print("Error Processing Junior Student $studentName: $e");
    }
  }

// Process senior student data
  Future<void> _processSeniorStudent(
      String schoolName,
      String className,
      String studentName,
      QuerySnapshot subjectsSnapshot) async {

    try {
      List<int> subjectPoints = [];

      for (var subjectDoc in subjectsSnapshot.docs) {
        var subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};

        if (subjectData.containsKey('Subject_Grade')) {
          var subjectGradeValue = subjectData['Subject_Grade'];

          if (subjectGradeValue == null ||
              subjectGradeValue.toString().toUpperCase() == 'N/A') {
            continue;
          }

          int? subjectScore;
          if (subjectGradeValue is int) {
            subjectScore = subjectGradeValue;
          } else if (subjectGradeValue is String) {
            subjectScore = int.tryParse(subjectGradeValue);
          }

          if (subjectScore != null && subjectScore >= 0) {
            int gradePoint = int.parse(_getSeniorsGrade(subjectScore));
            subjectPoints.add(gradePoint);
          }
        }
      }

      Map<String, dynamic> msceResult = calculateMSCEAggregate(subjectPoints);
      int bestSixPoints = msceResult['points'];
      String msceStatus = msceResult['status'];
      String msceMessage = msceResult['message'];

      // Update student's total marks document
      DocumentReference marksRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('TOTAL_MARKS')
          .doc('Marks');

      Map<String, dynamic> updateData = {
        'Best_Six_Total_Points': bestSixPoints,
        'MSCE_Status': msceStatus,
        'MSCE_Message': msceMessage,
      };

      await marksRef.set(updateData, SetOptions(merge: true));

      print("Senior Student $studentName processed: $bestSixPoints points - $msceStatus");
    } catch (e) {
      print("Error Processing Senior Student $studentName: $e");
    }
  }

// Method to process all students in the class (for comprehensive calculation)
  Future<void> _processAllStudentsInClass(String schoolName, String className) async {
    try {
      print("Processing all Students in Class $className...");

      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .get();

      // Process each student
      List<Future<void>> processingFutures = [];
      for (var studentDoc in studentsSnapshot.docs) {
        String studentName = studentDoc.id;
        processingFutures.add(_processStudentData(schoolName, className, studentName));
      }

      // Wait for all students to be processed
      await Future.wait(processingFutures);

      print("All Students in Class $className Processed Successfully!");
    } catch (e) {
      print("Error Processing all Students in Class: $e");
    }
  }

  // Grading functions for different levels
  String _getJuniorsGrade(int score) {
    if (score >= 85) return 'A';
    if (score >= 75) return 'B';
    if (score >= 65) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  String _getJuniorsRemark(String grade) {
    switch (grade) {
      case 'A': return 'EXCELLENT';
      case 'B': return 'VERY GOOD';
      case 'C': return 'GOOD';
      case 'D': return 'PASS';
      default: return 'FAIL';
    }
  }

  String _getSeniorsGrade(int score) {
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

  String _getSeniorsRemark(String grade) {
    switch (grade) {
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



// Method to calculate class performance metrics
  Future<void> _calculateClassPerformance(String schoolName, String className) async {
    try {
      print("Calculating Class Performance for $className...");

      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .get();

      bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';
      bool isJunior = className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2';

      Map<String, Map<String, dynamic>> subjectPerformanceData = {};
      int totalStudents = studentsSnapshot.docs.length;
      int totalClassPassed = 0;
      int totalClassFailed = 0;

      // Process each student
      for (var studentDoc in studentsSnapshot.docs) {
        String studentName = studentDoc.id;
        bool studentPassed = false;

        // Get student's total marks document to check pass/fail status
        final marksDoc = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details')
            .doc(studentName)
            .collection('TOTAL_MARKS')
            .doc('Marks')
            .get();

        if (marksDoc.exists) {
          var marksData = marksDoc.data() as Map<String, dynamic>;

          if (isSenior) {
            String msceStatus = marksData['MSCE_Status'] ?? 'STATEMENT';
            studentPassed = msceStatus == 'PASS';
          } else if (isJunior) {
            String jceStatus = marksData['JCE_Status'] ?? 'FAIL';
            studentPassed = jceStatus == 'PASS';
          }
        }

        if (studentPassed) {
          totalClassPassed++;
        } else {
          totalClassFailed++;
        }

        // Get student's subjects for subject-wise performance
        final subjectsSnapshot = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details')
            .doc(studentName)
            .collection('Student_Subjects')
            .get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          var subjectData = subjectDoc.data() as Map<String, dynamic>;
          String subjectName = subjectData['Subject_Name'] ?? subjectDoc.id;
          var gradeValue = subjectData['Subject_Grade'];

          // Skip if no grade or N/A
          if (gradeValue == null || gradeValue.toString().toUpperCase() == 'N/A' || gradeValue.toString().isEmpty) {
            continue;
          }

          // Initialize subject data if not exists
          if (!subjectPerformanceData.containsKey(subjectName)) {
            subjectPerformanceData[subjectName] = {
              'totalStudents': 0,
              'totalPass': 0,
              'totalFail': 0,
              'passRate': 0.0,
              'totalMarks': 0,
              'subjectAverage': 0,
              'allGrades': <int>[], // FIXED: Track all grades for proper average calculation
            };
          }

          int grade = int.tryParse(gradeValue.toString()) ?? 0;
          if (grade > 0) { // Only include valid grades
            bool subjectPassed = false;

            if (isSenior) {
              // Senior: Grade 1-8 is pass, 9 is fail
              String gradePoint = _getSeniorsGrade(grade);
              subjectPassed = gradePoint != '9';
            } else if (isJunior) {
              // Junior: 50% and above is pass
              subjectPassed = grade >= 50;
            }

            subjectPerformanceData[subjectName]!['totalStudents']++;
            subjectPerformanceData[subjectName]!['totalMarks'] += grade;
            subjectPerformanceData[subjectName]!['allGrades'].add(grade); // FIXED: Add to grades list

            if (subjectPassed) {
              subjectPerformanceData[subjectName]!['totalPass']++;
            } else {
              subjectPerformanceData[subjectName]!['totalFail']++;
            }
          }
        }
      }

      // FIXED: Calculate pass rates and subject averages properly
      subjectPerformanceData.forEach((subject, data) {
        int totalStudentsInSubject = data['totalStudents'];
        int totalPassInSubject = data['totalPass'];
        List<int> allGrades = data['allGrades'];

        if (totalStudentsInSubject > 0) {
          data['passRate'] = (totalPassInSubject / totalStudentsInSubject * 100).round();

          // FIXED: Calculate average from actual grades, not total marks
          if (allGrades.isNotEmpty) {
            double average = allGrades.reduce((a, b) => a + b) / allGrades.length;
            data['subjectAverage'] = average.round();
          } else {
            data['subjectAverage'] = 0;
          }
        }

        // Remove the temporary grades list before storing
        data.remove('allGrades');
      });

      // Calculate overall class pass rate
      double classPassRate = totalStudents > 0 ? (totalClassPassed / totalStudents * 100) : 0.0;

      // Store the calculated data
      classPerformance = {
        'totalStudents': totalStudents,
        'totalClassPassed': totalClassPassed,
        'totalClassFail': totalClassFailed,
        'classPassRate': classPassRate.round(),
      };

      subjectPerformance = subjectPerformanceData;

      print("Class Performance Calculation Completed!");
      print("Total Students: $totalStudents");
      print("Total Passed: $totalClassPassed");
      print("Total Failed: $totalClassFailed");
      print("Class Pass Rate: ${classPassRate.round()}%");

    } catch (e) {
      print("Error calculating class performance: $e");
    }
  }

// Method to save class performance data to Firestore
  Future<void> _saveClassPerformanceToFirestore(String schoolName, String className) async {
    try {
      print("Saving Class Performance to Firestore...");

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      String userEmail = currentUser.email ?? '';
      String basePath = 'Schools/$schoolName/Classes/$className';

      // Save class summary - FIXED: Added proper document ID
      await _firestore.doc('$basePath/Class_Performance/Class_Summary').set({
        'Total_Students': classPerformance['totalStudents'],
        'Class_Pass_Rate': classPerformance['classPassRate'],
        'Total_Class_Passed': classPerformance['totalClassPassed'],
        'Total_Class_Failed': classPerformance['totalClassFail'],
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userEmail,
      }, SetOptions(merge: true));

      // Save each subject's performance - FIXED: Proper document path
      for (String subject in subjectPerformance.keys) {
        var subjectData = subjectPerformance[subject];

        // Clean subject name for document ID (remove special characters)
        String cleanSubjectName = subject.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        if (cleanSubjectName.isEmpty) cleanSubjectName = 'Unknown_Subject';

        await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Class_Performance')
            .doc('Subject_Performance')
            .collection('Subjects')
            .doc(cleanSubjectName)
            .set({
          'Subject_Name': subject,
          'Total_Students': subjectData['totalStudents'],
          'Total_Pass': subjectData['totalPass'],
          'Total_Fail': subjectData['totalFail'],
          'Pass_Rate': subjectData['passRate'],
          'Subject_Average': subjectData['subjectAverage'], // FIXED: This was missing
          'lastUpdated': FieldValue.serverTimestamp(),
          'updatedBy': userEmail,
        }, SetOptions(merge: true));
      }

      print("Class Performance saved to Firestore successfully!");

    } catch (e) {
      print("Error saving class performance to Firestore: $e");
    }
  }

// Method to run complete class performance calculation and save
  Future<void> _runCompleteClassPerformanceCalculation(String schoolName, String className) async {
    try {
      print("Running Complete Class Performance Analysis...");

      // Step 1: Calculate class performance
      await _calculateClassPerformance(schoolName, className);

      // Step 2: Save to Firestore
      await _saveClassPerformanceToFirestore(schoolName, className);

      print("Complete Class Performance Analysis Finished!");

    } catch (e) {
      print("Error in complete class performance calculation: $e");
    }
  }

  // Replace your existing _updateGrade method with this updated version

  Future<void> _updateGrade(String subject) async {
    String newGrade = '';
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Grade for $subject'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter grade (0-100)",
                      labelText: "Grade",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        newGrade = value.trim();
                        // Real-time validation
                        if (value.isEmpty) {
                          errorMessage = '';
                        } else if (int.tryParse(value) == null) {
                          errorMessage = 'Please enter a valid numeric grade';
                        } else {
                          int grade = int.parse(value);
                          if (grade < 0) {
                            errorMessage = 'Grade cannot be less than 0';
                          } else if (grade > 100) {
                            errorMessage = 'Grade cannot be greater than 100';
                          } else {
                            errorMessage = '';
                          }
                        }
                      });
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                // Final validation before saving
                if (newGrade.isEmpty || int.tryParse(newGrade) == null) {
                  setState(() {
                    errorMessage = 'Please enter a valid grade (numeric value)';
                  });
                  return;
                } else if (int.parse(newGrade) < 0) {
                  setState(() {
                    errorMessage = 'Grade cannot be less than 0';
                  });
                  return;
                } else if (int.parse(newGrade) > 100) {
                  setState(() {
                    errorMessage = 'Grade cannot be greater than 100';
                  });
                  return;
                }

                // Close dialog first to avoid widget lifecycle issues
                Navigator.of(context).pop();

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;

                  final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
                  final docSnapshot = await userRef.get();

                  if (docSnapshot.exists) {
                    String schoolName = (docSnapshot['school'] ?? '').trim();
                    String className = widget.studentClass.trim();
                    String studentName = widget.studentName.trim();

                    // Handle name variations
                    List<String> nameParts = studentName.split(" ");
                    String reversedName = nameParts.length == 2
                        ? "${nameParts[1]} ${nameParts[0]}"
                        : studentName;

                    final studentRefNormal = _firestore
                        .collection('Schools')
                        .doc(schoolName)
                        .collection('Classes')
                        .doc(className)
                        .collection('Student_Details')
                        .doc(studentName);

                    final studentRefReversed = _firestore
                        .collection('Schools')
                        .doc(schoolName)
                        .collection('Classes')
                        .doc(className)
                        .collection('Student_Details')
                        .doc(reversedName);

                    final studentSnapshotNormal = await studentRefNormal.get();
                    final studentSnapshotReversed = await studentRefReversed.get();

                    DocumentReference studentRef;
                    String actualStudentName;
                    if (studentSnapshotNormal.exists) {
                      studentRef = studentRefNormal;
                      actualStudentName = studentName;
                    } else if (studentSnapshotReversed.exists) {
                      studentRef = studentRefReversed;
                      actualStudentName = reversedName;
                    } else {
                      print("Student document not found for either name variation");
                      return;
                    }

                    final subjectRef = studentRef.collection('Student_Subjects').doc(subject);
                    int gradeInt = int.parse(newGrade);

                    final subjectSnapshot = await subjectRef.get();
                    Map<String, dynamic> existingData = {};

                    if (subjectSnapshot.exists) {
                      existingData = subjectSnapshot.data() as Map<String, dynamic>? ?? {};
                    }

                    // Determine if student is Senior or Junior based on class
                    bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';
                    bool isJunior = className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2';

                    Map<String, dynamic> dataToSave = {
                      'Subject_Grade': newGrade,
                      'Subject_Name': subject, // Ensure subject name is saved
                    };

                    if (isSenior) {
                      // Senior system (FORM 3 & 4)
                      String gradePoint = _getSeniorsGrade(gradeInt);
                      String remark = _getSeniorsRemark(gradePoint);

                      dataToSave.addAll({
                        'Grade_Point': int.parse(gradePoint),
                        'Grade_Remark': remark,
                      });

                    } else if (isJunior) {
                      // Junior system (FORM 1 & 2)
                      String gradeLetter = _getJuniorsGrade(gradeInt);
                      String remark = _getJuniorsRemark(gradeLetter);

                      dataToSave.addAll({
                        'Grade_Letter': gradeLetter,
                        'Grade_Remark': remark,
                      });
                    }

                    // Merge with existing data and save
                    existingData.addAll(dataToSave);
                    await subjectRef.set(existingData, SetOptions(merge: true));

                    print("Grade updated successfully for $actualStudentName in $subject");

                    // Update cached grade
                    if (mounted) {
                      setState(() {
                        _subjectGrades[subject] = newGrade;
                      });
                    }

                    // *** COMPREHENSIVE CALCULATIONS ***
                    print("Starting comprehensive calculations...");

                    // 1. Calculate subject positions
                    await _calculateSubjectStatsAndPosition(schoolName, className);
                    print("Position calculation completed!");

                    // 2. Process all students for total marks and status
                    await _processAllStudentsInClass(schoolName, className);
                    print("Student data processing completed!");

                    // 3. Calculate and save class performance
                    await _runCompleteClassPerformanceCalculation(schoolName, className);
                    print("Class performance calculation completed!");

                    // 4. *** NEW: Update student remarks based on performance ***
                    await _updateRemarksForAllStudents(schoolName, className);
                    print("Student remarks updated successfully!");

                    // Refresh the main widget state
                    if (mounted) {
                      setState(() {});
                    }

                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Grade updated successfully! All calculations, performance analysis, and student remarks completed.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('Error updating Subject Grade: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating grade. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


// Method to generate performance-based remarks
  Map<String, String> _generatePerformanceRemarks(
      String className,
      Map<String, String> subjectGrades,
      {int? totalMarks,
        int? bestSixPoints,
        String? academicStatus})

  {

    bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';
    bool isJunior = className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2';

    List<String> failedSubjects = [];
    List<String> weakSubjects = [];
    List<String> strongSubjects = [];

    // Analyze subject performance
    subjectGrades.forEach((subject, grade) {
      if (grade == 'N/A' || grade.isEmpty) return;

      int gradeInt = int.tryParse(grade) ?? 0;
      if (gradeInt == 0) return;

      if (isSenior) {
        String gradePoint = _getSeniorsGrade(gradeInt);
        if (gradePoint == '9') {
          failedSubjects.add(subject);
        } else if (gradePoint == '8' || gradePoint == '7') {
          weakSubjects.add(subject);
        } else if (gradePoint == '1' || gradePoint == '2') {
          strongSubjects.add(subject);
        }
      } else if (isJunior) {
        if (gradeInt < 50) {
          failedSubjects.add(subject);
        } else if (gradeInt < 65) {
          weakSubjects.add(subject);
        } else if (gradeInt >= 85) {
          strongSubjects.add(subject);
        }
      }
    });

    // Generate Form Teacher Remark (more encouraging, specific guidance)
    String formTeacherRemark = '';
    if (failedSubjects.isNotEmpty) {
      if (failedSubjects.length == 1) {
        formTeacherRemark = 'Good effort overall. Focus more attention on ${failedSubjects.first} to improve your understanding. ';
      } else if (failedSubjects.length <= 3) {
        formTeacherRemark = 'You show potential. Give extra attention to ${failedSubjects.join(', ')} through additional practice and study. ';
      } else {
        formTeacherRemark = 'You need to put in more consistent effort across subjects. Focus especially on ${failedSubjects.take(3).join(', ')} and others. ';
      }
    }

    if (weakSubjects.isNotEmpty && failedSubjects.length <= 2) {
      formTeacherRemark += 'Work harder in ${weakSubjects.take(2).join(' and ')} to reach your full potential. ';
    }

    if (strongSubjects.isNotEmpty) {
      formTeacherRemark += 'Well done in ${strongSubjects.take(2).join(' and ')}. ';
    }

    // Add academic status comment for Form Teacher
    if (isSenior && academicStatus != null) {
      if (academicStatus == 'STATEMENT') {
        formTeacherRemark += 'Work harder to achieve university entry requirements.';
      } else {
        formTeacherRemark += 'Keep up the good work for university preparation.';
      }
    } else if (isJunior && totalMarks != null) {
      if (totalMarks < 550) {
        formTeacherRemark += 'Aim for higher scores to prepare for senior classes.';
      } else {
        formTeacherRemark += 'Good preparation for senior level studies.';
      }
    }

    if (formTeacherRemark.isEmpty) {
      formTeacherRemark = 'Continue working hard and stay focused on your studies.';
    }

    // Generate Head Teacher Remark (more formal, overall assessment)
    String headTeacherRemark = '';

    if (failedSubjects.length >= 4) {
      headTeacherRemark = 'Serious improvement needed across multiple subjects. Parent conference recommended to discuss support strategies.';
    } else if (failedSubjects.length >= 2) {
      headTeacherRemark = 'Significant improvement required in ${failedSubjects.take(3).join(', ')}. Additional academic support recommended.';
    } else if (failedSubjects.length == 1) {
      if (isSenior && academicStatus == 'STATEMENT') {
        headTeacherRemark = 'Address weakness in ${failedSubjects.first} to improve university prospects. Consider remedial classes.';
      } else {
        headTeacherRemark = 'Generally satisfactory performance. Focus on improving ${failedSubjects.first} for better overall results.';
      }
    } else {
      // No failed subjects
      if (weakSubjects.length >= 3) {
        headTeacherRemark = 'Moderate performance. Consistent effort needed to reach higher academic standards.';
      } else if (strongSubjects.length >= 3) {
        headTeacherRemark = 'Commendable academic performance. Continue to maintain high standards across all subjects.';
      } else {
        headTeacherRemark = 'Satisfactory academic progress. Encourage continued effort and improvement.';
      }
    }

    // Add overall academic status comment for Head Teacher
    if (isSenior && bestSixPoints != null) {
      if (bestSixPoints > 48) {
        headTeacherRemark += ' Current performance may limit higher education opportunities.';
      } else if (bestSixPoints <= 18) {
        headTeacherRemark += ' Excellent preparation for tertiary education.';
      }
    } else if (isJunior && totalMarks != null) {
      if (totalMarks >= 700) {
        headTeacherRemark += ' Outstanding foundation for senior secondary education.';
      } else if (totalMarks < 450) {
        headTeacherRemark += ' Additional support needed to meet academic expectations.';
      }
    }

    return {
      'Form_Teacher_Remark': formTeacherRemark.trim(),
      'Head_Teacher_Remark': headTeacherRemark.trim(),
    };
  }

// Method to update student remarks based on current performance
  Future<void> _updateStudentRemarks(String schoolName, String className, String studentName) async {
    try {
      print("Updating remarks for student: $studentName");

      // Get student's current grades
      final subjectsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('Student_Subjects')
          .get();

      // Get student's total marks/status
      final marksDoc = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get();

      Map<String, String> subjectGrades = {};
      int? totalMarks;
      int? bestSixPoints;
      String? academicStatus;

      // Collect subject grades
      for (var doc in subjectsSnapshot.docs) {
        String subject = doc['Subject_Name'] ?? doc.id;
        String grade = doc['Subject_Grade']?.toString() ?? 'N/A';
        if (grade != 'N/A' && grade.isNotEmpty) {
          subjectGrades[subject] = grade;
        }
      }

      // Get academic performance data
      if (marksDoc.exists) {
        var marksData = marksDoc.data() as Map<String, dynamic>;

        bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';

        if (isSenior) {
          bestSixPoints = marksData['Best_Six_Total_Points'];
          academicStatus = marksData['MSCE_Status'];
        } else {
          var studentMarks = marksData['Student_Total_Marks'];
          totalMarks = studentMarks is String ? int.tryParse(studentMarks) : studentMarks;
        }
      }

      // Generate remarks based on performance
      Map<String, String> remarks = _generatePerformanceRemarks(
        className,
        subjectGrades,
        totalMarks: totalMarks,
        bestSixPoints: bestSixPoints,
        academicStatus: academicStatus,
      );

      // Update remarks in Firestore
      final remarksRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(studentName)
          .collection('TOTAL_MARKS')
          .doc('Results_Remarks');

      await remarksRef.set({
        'Form_Teacher_Remark': remarks['Form_Teacher_Remark'],
        'Head_Teacher_Remark': remarks['Head_Teacher_Remark'],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Remarks updated successfully for $studentName");

    } catch (e) {
      print("Error updating remarks for $studentName: $e");
    }
  }

// Method to update remarks for all students in class
  Future<void> _updateRemarksForAllStudents(String schoolName, String className) async {
    try {
      print("Updating remarks for all students in $className...");

      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .get();

      List<Future<void>> remarkUpdates = [];

      for (var studentDoc in studentsSnapshot.docs) {
        String studentName = studentDoc.id;
        remarkUpdates.add(_updateStudentRemarks(schoolName, className, studentName));
      }

      await Future.wait(remarkUpdates);
      print("All student remarks updated successfully!");

    } catch (e) {
      print("Error updating remarks for all students: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects for ${widget.studentName}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent, // Changed to blue color
          strokeWidth: 3.0,
        ),
      )
          : _subjects.isEmpty
          ? const Center(
        child: Text(
          'No Subjects Available.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            bool canEditThisSubject = _canEditSubject(_subjects[index]);
            String subject = _subjects[index];

            // Use cached grade if available, otherwise show loading
            String grade = _subjectGrades[subject] ?? '';

            if (grade.isEmpty) {
              // Load grade asynchronously and update cache
              _fetchGradeForSubject(subject).then((fetchedGrade) {
                if (fetchedGrade.isNotEmpty && mounted) {
                  setState(() {
                    _subjectGrades[subject] = fetchedGrade;
                  });
                }
              });
              grade = 'Loading...'; // Show loading state
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  '${index + 1}. $subject',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                subtitle: Text(
<<<<<<< HEAD
                  'Grade: ${grade.isEmpty || grade == 'Loading...' ? (grade == 'Loading...' ? grade : 'N/A') : grade}%',
=======
                  'Grade: ${grade.isEmpty || grade == 'Loading...' ? (grade == 'Loading...' ? grade : 'N/A') : grade}',
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: grade == 'Loading...' ? Colors.blue : Colors.black54,
                  ),
                ),
                trailing: canEditThisSubject
                    ? IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blueAccent,
                  iconSize: 20,
                  onPressed: () {
                    _updateGrade(subject);
                  },
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}