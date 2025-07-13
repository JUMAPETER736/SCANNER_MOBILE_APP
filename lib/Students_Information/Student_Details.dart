import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';



class Student_Details extends StatefulWidget {
  const Student_Details({Key? key}) : super(key: key);

  @override
  State<Student_Details> createState() => _Student_DetailsState();
}

class _Student_DetailsState extends State<Student_Details> {
  // Constants
  static const List<String> _classes = ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'];
  static const List<String> _genders = ['Male', 'Female'];

  // Form and Firebase instances
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // State variables
  String? _selectedClass;
  String? _selectedGender;
  String? _studentID;
  String? _generatedQRCode;
  String? _studentFullName;
  User? _loggedInUser;
  int _totalClassStudentsNumber = 0;

  // Default subjects for each form
  static const Map<String, List<String>> _defaultSubjects = {
    'FORM 1': [
      'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA',
      'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS',
      'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'
    ],
    'FORM 2': [
      'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA',
      'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY', 'HOME ECONOMICS',
      'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'
    ],
    'FORM 3': [
      'ADDITIONAL MATHEMATICS', 'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY',
      'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY',
      'HISTORY', 'HOME ECONOMICS', 'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'
    ],
    'FORM 4': [
      'ADDITIONAL MATHEMATICS', 'AGRICULTURE', 'BIBLE KNOWLEDGE', 'BIOLOGY',
      'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY', 'HISTORY',
      'HOME ECONOMICS', 'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'
    ],
  };

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // MARK: - User Management
  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _loggedInUser = user;
    }
  }

  // MARK: - Academic Year Helper Methods
  String _getCurrentAcademicYear() {
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

  String _getCurrentTerm() {
    final DateTime now = DateTime.now();
    final int month = now.month;
    final int day = now.day;

    if (month >= 9 || month == 12) {
      return 'TERM_ONE';
    } else if (month >= 1 && (month < 3 || (month == 3 && day <= 20))) {
      return 'TERM_TWO';
    } else if (month >= 4 && month <= 8) {
      return 'TERM_THREE';
    } else {
      return 'TERM_ONE';
    }
  }

  Map<String, Map<String, String>> _getTermDates(String academicYear) {
    final List<String> years = academicYear.split('_');
    final int startYear = int.parse(years[0]);
    final int endYear = int.parse(years[1]);

    return {
      'TERM_ONE': {
        'start_date': '01-09-$startYear',
        'end_date': '31-12-$startYear',
      },
      'TERM_TWO': {
        'start_date': '01-01-$endYear',
        'end_date': '20-03-$endYear',
      },
      'TERM_THREE': {
        'start_date': '01-04-$endYear',
        'end_date': '30-08-$endYear',
      },
    };
  }

  // MARK: - Utility Methods
  String _generateRandomStudentID() {
    final Random random = Random();
    final int id = 100000 + random.nextInt(900000);
    return id.toString();
  }

  int _calculateAge(String dob) {
    try {
      final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      final DateTime birthDate = dateFormat.parse(dob);
      final DateTime currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;

      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // MARK: - Validation Methods
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter the student\'s $fieldName';
    }
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  String? _validateClass(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select the student\'s class';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select the student\'s gender';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the student\'s Date of Birth';
    }

    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
      return 'Please enter date in DD-MM-YYYY format';
    }

    try {
      final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      final DateTime dob = dateFormat.parseStrict(value);

      if (dob.isAfter(DateTime.now())) {
        return 'Date of Birth cannot be in the future';
      }

      if (DateTime.now().year - dob.year > 100) {
        return 'Please enter a valid Date of Birth';
      }
    } catch (e) {
      return 'Please enter a valid Date of Birth (DD-MM-YYYY)';
    }

    return null;
  }

  // MARK: - Database Operations
  Future<void> _saveStudentDetails() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _showLoadingDialog();

      // Format student name as per Firestore structure (uppercase, space-separated)
      _studentFullName = '${_lastNameController.text.trim().toUpperCase()} ${_firstNameController.text.trim().toUpperCase()}';
      _studentID = _generateRandomStudentID();

      final String schoolName = await _getSchoolName();

      await _saveStudentToFirestore(schoolName);
      await _updateTotalStudentsCountOnSave(schoolName, _selectedClass!);

      setState(() {
        _generatedQRCode = _studentID;
      });

      _hideLoadingDialog();
      _showSuccessMessage();
    } catch (e) {
      _hideLoadingDialog();
      _showErrorMessage(e.toString());
    }
  }

  Future<String> _getSchoolName() async {
    final teacherEmail = _loggedInUser?.email;
    final teacherDetails = await _firestore
        .collection('Teachers_Details')
        .doc(teacherEmail)
        .get();

    if (!teacherDetails.exists) {
      throw Exception('Teacher details not found');
    }

    return teacherDetails['school'] as String;
  }


  Future<void> _saveStudentToFirestore(String schoolName) async {
    final WriteBatch batch = _firestore.batch();
    final String currentAcademicYear = _getCurrentAcademicYear();
    final Map<String, Map<String, String>> termDates = _getTermDates(currentAcademicYear);

    // Initialize school information if it doesn't exist
    final DocumentReference schoolInfoRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('School_Information')
        .doc('School_Details');

    if (!(await schoolInfoRef.get()).exists) {
      batch.set(schoolInfoRef, {
        'Upcoming_School_Events': [],
        'Telephone': '',
        'Email': '',
        'Account': '',
        'Next_Term_Date': '',
        'Box_Number': 0,
        'School_Location': '',
        'School_Fees': '',
        'School_Bank_Account': '',
        'Next_Term_Opening_Date': '',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Initialize fees details if it doesn't exist
    final DocumentReference feesDetailsRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('School_Information')
        .doc('Fees_Details');

    if (!(await feesDetailsRef.get()).exists) {
      batch.set(feesDetailsRef, {
        'Tuition_Fee': 0,
        'Development_Fee': 0,
        'Library_Fee': 0,
        'Sports_Fee': 0,
        'Laboratory_Fee': 0,
        'Other_Fees': 0,
        'Total_Fees': 0,
        'Bank_Account_Number': '',
        'Amount_Paid': 0,
        'Next_Payment_Due': '',
        'Bank_Name': 'N/A',
        'Bank_Account_Name': 'N/A',
        'Airtel_Money': 'N/A',
        'TNM_Mpamba': 'N/A',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create term-based structure under Classes
    await _createTermBasedStructure(batch, schoolName, currentAcademicYear, termDates);

    await batch.commit();
  }

  // MARK: - Database Operations Helper Methods
  Future<void> _updateTotalStudentsCountOnSave(String schoolName, String className) async {
    final String currentAcademicYear = _getCurrentAcademicYear();

    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final DocumentReference classInfoRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(currentAcademicYear)
          .collection('Classes')
          .doc(className)
          .collection(term)
          .doc('Term_Informations')
          .collection('Term_Informations')
          .doc('Class_Information');

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot snapshot = await transaction.get(classInfoRef);
        int currentCount = 0;

        if (snapshot.exists) {
          currentCount = snapshot.get('Total_Students') ?? 0;
        }

        transaction.set(
          classInfoRef,
          {'Total_Students': currentCount + 1},
          SetOptions(merge: true),
        );
      });
    }
  }

  String _getTermStatus(String term, Map<String, Map<String, String>> termDates, String academicYear) {
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
    final DateTime now = DateTime.now();

    try {
      final DateTime startDate = dateFormat.parse(termDates[term]!['start_date']!);
      final DateTime endDate = dateFormat.parse(termDates[term]!['end_date']!);

      if (now.isBefore(startDate)) {
        return 'Not Started';
      } else if (now.isAfter(endDate)) {
        return 'Completed';
      } else {
        return 'In Progress';
      }
    } catch (e) {
      return 'Not Started';
    }
  }

  int _calculateDaysRemaining(String endDate) {
    try {
      final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      final DateTime end = dateFormat.parse(endDate);
      final DateTime now = DateTime.now();
      final difference = end.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _createTermBasedStructure(
      WriteBatch batch,
      String schoolName,
      String currentAcademicYear,
      Map<String, Map<String, String>> termDates,
      ) async {

    // Create each term (TERM_ONE, TERM_TWO, TERM_THREE) under Classes
    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final String termStatus = _getTermStatus(term, termDates, currentAcademicYear);

      // Create Term_Informations collection under each term
      await _createTermInformations(batch, schoolName, currentAcademicYear, term, termStatus, termDates);

      // Create Class_List collection under each term with student data
      await _createClassList(batch, schoolName, currentAcademicYear, term, termStatus, termDates);
    }
  }

  Future<void> _createTermInformations(
      WriteBatch batch,
      String schoolName,
      String currentAcademicYear,
      String term,
      String termStatus,
      Map<String, Map<String, String>> termDates,
      ) async {

    // Create Class_Information under Term_Informations
    final DocumentReference classInfoRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(_selectedClass)
        .collection(term)
        .doc('Term_Informations')
        .collection('Term_Informations')
        .doc('Class_Information');

    if (!(await classInfoRef.get()).exists) {
      // Create subjects offered with teacher names (to be updated later)
      Map<String, String> subjectsWithTeachers = {};
      for (String subject in _defaultSubjects[_selectedClass]!) {
        subjectsWithTeachers[subject] = 'N/A'; // Teacher names will be updated later
      }

      batch.set(classInfoRef, {
        'Class_Name': _selectedClass,
        'Class_Teacher': 'N/A',
        'Total_Students': 0,
        'Subjects_Offered': subjectsWithTeachers,
        'Academic_Year': currentAcademicYear,
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Class_Performance under Term_Informations
    final DocumentReference classPerformanceRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(_selectedClass)
        .collection(term)
        .doc('Term_Informations')
        .collection('Term_Informations')
        .doc('Class_Performance');

    if (!(await classPerformanceRef.get()).exists) {
      batch.set(classPerformanceRef, {
        'Total_Students': 0,
        'Average_Performance': 0.0,
        'Best_Student': 'N/A',
        'Class_Teacher': 'N/A',
        'Subjects_Offered': _defaultSubjects[_selectedClass]!,
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Teacher_Details under Term_Informations
    final DocumentReference teacherDetailsRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(_selectedClass)
        .collection(term)
        .doc('Term_Informations')
        .collection('Term_Informations')
        .doc('Teacher_Details');

    if (!(await teacherDetailsRef.get()).exists) {
      // Create subject teachers map
      Map<String, String> subjectTeachers = {};
      for (String subject in _defaultSubjects[_selectedClass]!) {
        subjectTeachers[subject] = 'N/A'; // Teacher names will be updated later
      }

      batch.set(teacherDetailsRef, {
        'Form_Teacher': 'N/A',
        'Subject_Teachers': subjectTeachers,
        'Teacher_Contacts': {},
        'Teacher_Remarks': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Term_Status under Term_Informations
    final DocumentReference termStatusRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(_selectedClass)
        .collection(term)
        .doc('Term_Informations')
        .collection('Term_Informations')
        .doc('Term_Status');

    if (!(await termStatusRef.get()).exists) {
      batch.set(termStatusRef, {
        'Term_Name': term,
        'Term_Status': termStatus,
        'Start_Date': termDates[term]!['start_date'],
        'End_Date': termDates[term]!['end_date'],
        'Academic_Year': currentAcademicYear,
        'Current_Term': _getCurrentTerm(),
        'Is_Active': termStatus == 'In Progress',
        'Is_Completed': termStatus == 'Completed',
        'Days_Remaining': _calculateDaysRemaining(termDates[term]!['end_date']!),
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createClassList(
      WriteBatch batch,
      String schoolName,
      String currentAcademicYear,
      String term,
      String termStatus,
      Map<String, Map<String, String>> termDates,
      ) async {

    // Create the student document under Class_List - EMPTY DOCUMENT (no fields)
    final DocumentReference studentRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(_selectedClass)
        .collection(term)
        .doc('Term_Informations')
        .collection('Class_List')
        .doc(_studentFullName);

    // Create empty student document (no fields directly on the student document)
    // This will create the document but with no fields at the root level

    // Create Student_Behaviors under student with subject-specific behaviors
    await _createStudentBehaviors(batch, studentRef, term);

    // Create Personal_Information under student
    batch.set(studentRef.collection('Personal_Information').doc('Student_Details'), {
      'First_Name': _firstNameController.text.trim().toUpperCase(),
      'Last_Name': _lastNameController.text.trim().toUpperCase(),
      'Full_Name': _studentFullName,
      'Student_Class': _selectedClass!,
      'Student_DOB': _dobController.text.trim(),
      'Student_Age': _calculateAge(_dobController.text.trim()).toString(),
      'Student_Gender': _selectedGender!,
      'Student_ID': _studentID!,
      'Term_Name': term,
      'Created_By': _loggedInUser?.email ?? '',
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    // Create Student_Subjects under student
    final CollectionReference subjectsRef = studentRef.collection('Student_Subjects');
    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(subjectsRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Total_Marks under student
    batch.set(studentRef.collection('Total_Marks').doc('Marks_Summary'), {
      'Aggregate_Grade': 'N/A',
      'Best_Six_Total_Points': 0,
      'Student_Total_Marks': '0',
      'Teacher_Total_Marks': '0',
      'Total_Marks_Obtained': 0,
      'Total_Possible_Marks': 0,
      'Overall_Percentage': 0.0,
      'Class_Position': 0,
      'Subjects_Passed': 0,
      'Subjects_Failed': 0,
      'Form_Teacher_Remark': 'N/A',
      'Head_Teacher_Remark': 'N/A',
      'Term_Name': term,
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    // Create Academic_Performance under student with term results
    await _createStudentAcademicPerformance(batch, studentRef, term);
  }

  // NEW METHOD: Create Student_Behaviors with subject-specific behaviors
  Future<void> _createStudentBehaviors(
      WriteBatch batch,
      DocumentReference studentRef,
      String term,
      ) async {

    // Create general behavior record
    batch.set(studentRef.collection('Student_Behaviors').doc('General_Behavior'), {
      'Overall_Conduct': 'N/A',
      'Class_Participation': 'N/A',
      'Punctuality': 'N/A',
      'Disciplinary_Records': [],
      'General_Behavior_Notes': '',
      'Term_Name': term,
      'Created_By': _loggedInUser?.email ?? '',
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    // Create behavior record for each subject
    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(studentRef.collection('Student_Behaviors').doc(subject), {
        'Subject_Name': subject,
        'Subject_Participation': 'N/A', // Excellent, Good, Fair, Poor
        'Homework_Completion': 'N/A', // Always, Usually, Sometimes, Rarely
        'Class_Attention': 'N/A', // Very Attentive, Attentive, Distracted, Very Distracted
        'Assignment_Submission': 'N/A', // On Time, Late, Never
        'Subject_Interest': 'N/A', // Very Interested, Interested, Not Interested
        'Cooperation_Level': 'N/A', // Excellent, Good, Fair, Poor
        'Subject_Behavior_Notes': '',
        'Teacher_Remarks': '',
        'Improvement_Areas': [],
        'Strengths': [],
        'Term_Name': term,
        'Created_By': _loggedInUser?.email ?? '',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createStudentAcademicPerformance(
      WriteBatch batch,
      DocumentReference studentRef,
      String currentTerm,
      ) async {
    final CollectionReference academicPerformanceRef = studentRef.collection('Academic_Performance');

    // Create TERM_ONE_RESULTS
    batch.set(academicPerformanceRef.doc('TERM_ONE_RESULTS'), {
      'Term_Name': 'TERM ONE',
      'Overall_Grade': 'N/A',
      'Overall_Percentage': 0.0,
      'Class_Ranking': 0,
      'Subjects_Count': _defaultSubjects[_selectedClass]!.length,
      'Passed_Subjects': 0,
      'Failed_Subjects': 0,
      'Best_Subject': 'N/A',
      'Weakest_Subject': 'N/A',
      'Improvement_Areas': [],
      'Strengths': [],
      'Teacher_Recommendations': '',
      'Parent_Feedback': '',
      'Subject_Grades': {},
      'Subject_Marks': {},
      'Total_Marks_Obtained': 0,
      'Total_Possible_Marks': 0,
      'Current_Term': currentTerm,
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    // Create TERM_TWO_RESULTS
    batch.set(academicPerformanceRef.doc('TERM_TWO_RESULTS'), {
      'Term_Name': 'TERM TWO',
      'Overall_Grade': 'N/A',
      'Overall_Percentage': 0.0,
      'Class_Ranking': 0,
      'Subjects_Count': _defaultSubjects[_selectedClass]!.length,
      'Passed_Subjects': 0,
      'Failed_Subjects': 0,
      'Best_Subject': 'N/A',
      'Weakest_Subject': 'N/A',
      'Improvement_Areas': [],
      'Strengths': [],
      'Teacher_Recommendations': '',
      'Parent_Feedback': '',
      'Subject_Grades': {},
      'Subject_Marks': {},
      'Total_Marks_Obtained': 0,
      'Total_Possible_Marks': 0,
      'Current_Term': currentTerm,
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    // Create TERM_THREE_RESULTS
    batch.set(academicPerformanceRef.doc('TERM_THREE_RESULTS'), {
      'Term_Name': 'TERM THREE',
      'Overall_Grade': 'N/A',
      'Overall_Percentage': 0.0,
      'Class_Ranking': 0,
      'Subjects_Count': _defaultSubjects[_selectedClass]!.length,
      'Passed_Subjects': 0,
      'Failed_Subjects': 0,
      'Best_Subject': 'N/A',
      'Weakest_Subject': 'N/A',
      'Improvement_Areas': [],
      'Strengths': [],
      'Teacher_Recommendations': '',
      'Parent_Feedback': '',
      'Subject_Grades': {},
      'Subject_Marks': {},
      'Total_Marks_Obtained': 0,
      'Total_Possible_Marks': 0,
      'Current_Term': currentTerm,
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });
  }

  // NEW METHOD: Auto-advance students to next term
  Future<void> _autoAdvanceToNextTerm(String schoolName, String currentAcademicYear, String completedTerm) async {
    try {
      final String nextTerm = _getNextTerm(completedTerm);
      if (nextTerm.isEmpty) {
        // If no next term, advance to next academic year
        await _autoAdvanceToNextAcademicYear(schoolName, currentAcademicYear);
        return;
      }

      // Get all classes
      final QuerySnapshot classesSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(currentAcademicYear)
          .collection('Classes')
          .get();

      final WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
        final String className = classDoc.id;

        // Get all students from completed term
        final QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Academic_Year')
            .doc(currentAcademicYear)
            .collection('Classes')
            .doc(className)
            .collection(completedTerm)
            .doc('Term_Informations')
            .collection('Class_List')
            .get();

        for (QueryDocumentSnapshot studentDoc in studentsSnapshot.docs) {
          final String studentName = studentDoc.id;

          // Copy student data to next term with empty performance data
          await _copyStudentToNextTerm(batch, schoolName, currentAcademicYear, className, studentName, completedTerm, nextTerm);
        }
      }

      await batch.commit();
      debugPrint('Successfully advanced students from $completedTerm to $nextTerm');
    } catch (e) {
      debugPrint('Error advancing to next term: $e');
    }
  }

  // NEW METHOD: Copy student data to next term
  Future<void> _copyStudentToNextTerm(
      WriteBatch batch,
      String schoolName,
      String currentAcademicYear,
      String className,
      String studentName,
      String fromTerm,
      String toTerm,
      ) async {

    final DocumentReference fromStudentRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(className)
        .collection(fromTerm)
        .doc('Term_Informations')
        .collection('Class_List')
        .doc(studentName);

    final DocumentReference toStudentRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(className)
        .collection(toTerm)
        .doc('Term_Informations')
        .collection('Class_List')
        .doc(studentName);

    // Copy Personal Information (unchanged)
    final DocumentSnapshot personalInfoDoc = await fromStudentRef.collection('Personal_Information').doc('Student_Details').get();
    if (personalInfoDoc.exists) {
      final Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;
      personalData['Term_Name'] = toTerm;
      personalData['Last_Updated'] = FieldValue.serverTimestamp();
      batch.set(toStudentRef.collection('Personal_Information').doc('Student_Details'), personalData);
    }

    // Copy Student_Behaviors (reset to N/A for new term)
    final QuerySnapshot behaviorDocs = await fromStudentRef.collection('Student_Behaviors').get();
    for (QueryDocumentSnapshot behaviorDoc in behaviorDocs.docs) {
      final Map<String, dynamic> behaviorData = behaviorDoc.data() as Map<String, dynamic>;

      // Reset all behavior values to N/A for new term
      if (behaviorDoc.id == 'General_Behavior') {
        behaviorData['Overall_Conduct'] = 'N/A';
        behaviorData['Class_Participation'] = 'N/A';
        behaviorData['Punctuality'] = 'N/A';
        behaviorData['Disciplinary_Records'] = [];
        behaviorData['General_Behavior_Notes'] = '';
      } else {
        behaviorData['Subject_Participation'] = 'N/A';
        behaviorData['Homework_Completion'] = 'N/A';
        behaviorData['Class_Attention'] = 'N/A';
        behaviorData['Assignment_Submission'] = 'N/A';
        behaviorData['Subject_Interest'] = 'N/A';
        behaviorData['Cooperation_Level'] = 'N/A';
        behaviorData['Subject_Behavior_Notes'] = '';
        behaviorData['Teacher_Remarks'] = '';
        behaviorData['Improvement_Areas'] = [];
        behaviorData['Strengths'] = [];
      }

      behaviorData['Term_Name'] = toTerm;
      behaviorData['Last_Updated'] = FieldValue.serverTimestamp();
      batch.set(toStudentRef.collection('Student_Behaviors').doc(behaviorDoc.id), behaviorData);
    }

    // Copy Student_Subjects (reset grades and marks)
    final QuerySnapshot subjectDocs = await fromStudentRef.collection('Student_Subjects').get();
    for (QueryDocumentSnapshot subjectDoc in subjectDocs.docs) {
      final Map<String, dynamic> subjectData = subjectDoc.data() as Map<String, dynamic>;

      // Reset performance data
      subjectData['Subject_Grade'] = 'N/A';
      subjectData['Marks_Obtained'] = 0;
      subjectData['Total_Marks'] = 0;
      subjectData['Percentage'] = 0.0;
      subjectData['Term_Name'] = toTerm;
      subjectData['Last_Updated'] = FieldValue.serverTimestamp();

      batch.set(toStudentRef.collection('Student_Subjects').doc(subjectDoc.id), subjectData);
    }

    // Copy Total_Marks (reset to default values)
    final DocumentSnapshot totalMarksDoc = await fromStudentRef.collection('Total_Marks').doc('Marks_Summary').get();
    if (totalMarksDoc.exists) {
      final Map<String, dynamic> totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;

      // Reset all performance data
      totalMarksData['Aggregate_Grade'] = 'N/A';
      totalMarksData['Best_Six_Total_Points'] = 0;
      totalMarksData['Student_Total_Marks'] = '0';
      totalMarksData['Teacher_Total_Marks'] = '0';
      totalMarksData['Total_Marks_Obtained'] = 0;
      totalMarksData['Total_Possible_Marks'] = 0;
      totalMarksData['Overall_Percentage'] = 0.0;
      totalMarksData['Class_Position'] = 0;
      totalMarksData['Subjects_Passed'] = 0;
      totalMarksData['Subjects_Failed'] = 0;
      totalMarksData['Form_Teacher_Remark'] = 'N/A';
      totalMarksData['Head_Teacher_Remark'] = 'N/A';
      totalMarksData['Term_Name'] = toTerm;
      totalMarksData['Last_Updated'] = FieldValue.serverTimestamp();

      batch.set(toStudentRef.collection('Total_Marks').doc('Marks_Summary'), totalMarksData);
    }

    // Copy Academic_Performance (keep previous terms' data, reset current term)
    final QuerySnapshot performanceDocs = await fromStudentRef.collection('Academic_Performance').get();
    for (QueryDocumentSnapshot performanceDoc in performanceDocs.docs) {
      final Map<String, dynamic> performanceData = performanceDoc.data() as Map<String, dynamic>;
      performanceData['Current_Term'] = toTerm;
      performanceData['Last_Updated'] = FieldValue.serverTimestamp();

      batch.set(toStudentRef.collection('Academic_Performance').doc(performanceDoc.id), performanceData);
    }
  }


  // COMPLETE THE _copyStudentToNextAcademicYear METHOD (the missing part)
  Future<void> _copyStudentToNextAcademicYear(
      WriteBatch batch,
      String schoolName,
      String currentAcademicYear,
      String nextAcademicYear,
      String currentClass,
      String nextClass,
      String studentName,
      ) async {

    final DocumentReference fromStudentRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(currentAcademicYear)
        .collection('Classes')
        .doc(currentClass)
        .collection('TERM_THREE')
        .doc('Term_Informations')
        .collection('Class_List')
        .doc(studentName);

    // Create student in all three terms of next academic year
    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final DocumentReference toStudentRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(nextAcademicYear)
          .collection('Classes')
          .doc(nextClass)
          .collection(term)
          .doc('Term_Informations')
          .collection('Class_List')
          .doc(studentName);

      // Copy and update Personal Information
      final DocumentSnapshot personalInfoDoc = await fromStudentRef.collection('Personal_Information').doc('Student_Details').get();
      if (personalInfoDoc.exists) {
        final Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;
        personalData['Student_Class'] = nextClass;
        personalData['Term_Name'] = term;
        personalData['Last_Updated'] = FieldValue.serverTimestamp();
        batch.set(toStudentRef.collection('Personal_Information').doc('Student_Details'), personalData);
      }

      // Create fresh Student_Behaviors for new class subjects
      await _createStudentBehaviors(batch, toStudentRef, term);

      // Create fresh Student_Subjects for new class
      final CollectionReference subjectsRef = toStudentRef.collection('Student_Subjects');
      for (String subject in _defaultSubjects[nextClass]!) {
        batch.set(subjectsRef.doc(subject), {
          'Subject_Name': subject,
          'Subject_Grade': 'N/A',
          'Marks_Obtained': 0,
          'Total_Marks': 0,
          'Percentage': 0.0,
          'Teacher_Assigned': 'N/A',
          'Term_Name': term,
          'Created_At': FieldValue.serverTimestamp(),
          'Last_Updated': FieldValue.serverTimestamp(),
        });
      }

      // Create fresh Total_Marks
      batch.set(toStudentRef.collection('Total_Marks').doc('Marks_Summary'), {
        'Aggregate_Grade': 'N/A',
        'Best_Six_Total_Points': 0,
        'Student_Total_Marks': '0',
        'Teacher_Total_Marks': '0',
        'Total_Marks_Obtained': 0,
        'Total_Possible_Marks': 0,
        'Overall_Percentage': 0.0,
        'Class_Position': 0,
        'Subjects_Passed': 0,
        'Subjects_Failed': 0,
        'Form_Teacher_Remark': 'N/A',
        'Head_Teacher_Remark': 'N/A',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });

      // Create fresh Academic_Performance
      await _createStudentAcademicPerformance(batch, toStudentRef, term);
    }
  }

  // HELPER METHODS YOU NEED TO ADD

  // Get next term
  String _getNextTerm(String currentTerm) {
    switch (currentTerm) {
      case 'TERM_ONE':
        return 'TERM_TWO';
      case 'TERM_TWO':
        return 'TERM_THREE';
      case 'TERM_THREE':
        return ''; // No next term, advance to next academic year
      default:
        return '';
    }
  }

  // Get next academic year
  String _getNextAcademicYear(String currentAcademicYear) {
    // Assuming academic year format is like "2024-2025"
    final List<String> years = currentAcademicYear.split('-');
    if (years.length == 2) {
      final int startYear = int.parse(years[0]) + 1;
      final int endYear = int.parse(years[1]) + 1;
      return '$startYear-$endYear';
    }
    return currentAcademicYear; // Return current if format is unexpected
  }

  // Get next class (Form progression)
  String _getNextClass(String currentClass) {
    switch (currentClass) {
      case 'FORM 1':
        return 'FORM 2';
      case 'FORM 2':
        return 'FORM 3';
      case 'FORM 3':
        return 'FORM 4';
      case 'FORM 4':
        return ''; // No next class, students graduate
      default:
        return '';
    }
  }

  // CREATE NEXT ACADEMIC YEAR STRUCTURE IF IT DOESN'T EXIST
  Future<void> _createNextAcademicYearStructure(String schoolName, String nextAcademicYear) async {
    final WriteBatch batch = _firestore.batch();
    final Map<String, Map<String, String>> termDates = _getTermDates(nextAcademicYear);

    // Create School Information for next academic year
    final DocumentReference schoolInfoRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(nextAcademicYear)
        .collection('School_Information')
        .doc('School_Details');

    if (!(await schoolInfoRef.get()).exists) {
      batch.set(schoolInfoRef, {
        'Upcoming_School_Events': [],
        'Telephone': '',
        'Email': '',
        'Account': '',
        'Next_Term_Date': '',
        'Box_Number': 0,
        'School_Location': '',
        'School_Fees': '',
        'School_Bank_Account': '',
        'Next_Term_Opening_Date': '',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Fees Details for next academic year
    final DocumentReference feesDetailsRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(nextAcademicYear)
        .collection('School_Information')
        .doc('Fees_Details');

    if (!(await feesDetailsRef.get()).exists) {
      batch.set(feesDetailsRef, {
        'Tuition_Fee': 0,
        'Development_Fee': 0,
        'Library_Fee': 0,
        'Sports_Fee': 0,
        'Laboratory_Fee': 0,
        'Other_Fees': 0,
        'Total_Fees': 0,
        'Bank_Account_Number': '',
        'Amount_Paid': 0,
        'Next_Payment_Due': '',
        'Bank_Name': 'N/A',
        'Bank_Account_Name': 'N/A',
        'Airtel_Money': 'N/A',
        'TNM_Mpamba': 'N/A',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }

    // Create class structures for all forms in next academic year
    for (String className in ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4']) {
      await _createClassStructureForNextYear(batch, schoolName, nextAcademicYear, className, termDates);
    }

    await batch.commit();
  }

  // CREATE CLASS STRUCTURE FOR NEXT ACADEMIC YEAR
  Future<void> _createClassStructureForNextYear(
      WriteBatch batch,
      String schoolName,
      String nextAcademicYear,
      String className,
      Map<String, Map<String, String>> termDates,
      ) async {

    // Create each term structure for the class
    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final String termStatus = _getTermStatus(term, termDates, nextAcademicYear);

      // Create Class_Information
      final DocumentReference classInfoRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(nextAcademicYear)
          .collection('Classes')
          .doc(className)
          .collection(term)
          .doc('Term_Informations')
          .collection('Term_Informations')
          .doc('Class_Information');

      if (!(await classInfoRef.get()).exists) {
        Map<String, String> subjectsWithTeachers = {};
        for (String subject in _defaultSubjects[className]!) {
          subjectsWithTeachers[subject] = 'N/A';
        }

        batch.set(classInfoRef, {
          'Class_Name': className,
          'Class_Teacher': 'N/A',
          'Total_Students': 0,
          'Subjects_Offered': subjectsWithTeachers,
          'Academic_Year': nextAcademicYear,
          'Term_Name': term,
          'Created_At': FieldValue.serverTimestamp(),
          'Last_Updated': FieldValue.serverTimestamp(),
        });
      }

      // Create Class_Performance
      final DocumentReference classPerformanceRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(nextAcademicYear)
          .collection('Classes')
          .doc(className)
          .collection(term)
          .doc('Term_Informations')
          .collection('Term_Informations')
          .doc('Class_Performance');

      if (!(await classPerformanceRef.get()).exists) {
        batch.set(classPerformanceRef, {
          'Total_Students': 0,
          'Average_Performance': 0.0,
          'Best_Student': 'N/A',
          'Class_Teacher': 'N/A',
          'Subjects_Offered': _defaultSubjects[className]!,
          'Term_Name': term,
          'Created_At': FieldValue.serverTimestamp(),
          'Last_Updated': FieldValue.serverTimestamp(),
        });
      }

      // Create Teacher_Details
      final DocumentReference teacherDetailsRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(nextAcademicYear)
          .collection('Classes')
          .doc(className)
          .collection(term)
          .doc('Term_Informations')
          .collection('Term_Informations')
          .doc('Teacher_Details');

      if (!(await teacherDetailsRef.get()).exists) {
        Map<String, String> subjectTeachers = {};
        for (String subject in _defaultSubjects[className]!) {
          subjectTeachers[subject] = 'N/A';
        }

        batch.set(teacherDetailsRef, {
          'Form_Teacher': 'N/A',
          'Subject_Teachers': subjectTeachers,
          'Teacher_Contacts': {},
          'Teacher_Remarks': '',
          'Term_Name': term,
          'Created_At': FieldValue.serverTimestamp(),
          'Last_Updated': FieldValue.serverTimestamp(),
        });
      }

      // Create Term_Status
      final DocumentReference termStatusRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(nextAcademicYear)
          .collection('Classes')
          .doc(className)
          .collection(term)
          .doc('Term_Informations')
          .collection('Term_Informations')
          .doc('Term_Status');

      if (!(await termStatusRef.get()).exists) {
        batch.set(termStatusRef, {
          'Term_Name': term,
          'Term_Status': termStatus,
          'Start_Date': termDates[term]!['start_date'],
          'End_Date': termDates[term]!['end_date'],
          'Academic_Year': nextAcademicYear,
          'Current_Term': _getCurrentTerm(),
          'Is_Active': termStatus == 'In Progress',
          'Is_Completed': termStatus == 'Completed',
          'Days_Remaining': _calculateDaysRemaining(termDates[term]!['end_date']!),
          'Created_At': FieldValue.serverTimestamp(),
          'Last_Updated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // UPDATED _autoAdvanceToNextAcademicYear METHOD (to create structure first)
  Future<void> _autoAdvanceToNextAcademicYear(String schoolName, String currentAcademicYear) async {
    try {
      final String nextAcademicYear = _getNextAcademicYear(currentAcademicYear);

      // Create next academic year structure first
      await _createNextAcademicYearStructure(schoolName, nextAcademicYear);

      // Get all classes
      final QuerySnapshot classesSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(currentAcademicYear)
          .collection('Classes')
          .get();

      final WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
        final String currentClass = classDoc.id;
        final String nextClass = _getNextClass(currentClass);

        // Skip FORM 4 students as they graduate
        if (nextClass.isEmpty) {
          debugPrint('FORM 4 students graduated, not advancing further');
          continue;
        }

        // Get all students from TERM_THREE (last term of academic year)
        final QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Academic_Year')
            .doc(currentAcademicYear)
            .collection('Classes')
            .doc(currentClass)
            .collection('TERM_THREE')
            .doc('Term_Informations')
            .collection('Class_List')
            .get();

        for (QueryDocumentSnapshot studentDoc in studentsSnapshot.docs) {
          final String studentName = studentDoc.id;

          // Copy student to next class in next academic year
          await _copyStudentToNextAcademicYear(batch, schoolName, currentAcademicYear, nextAcademicYear, currentClass, nextClass, studentName);
        }
      }

      await batch.commit();
      debugPrint('Successfully advanced students to next academic year: $nextAcademicYear');
    } catch (e) {
      debugPrint('Error advancing to next academic year: $e');
    }
  }

  // METHOD TO MANUALLY TRIGGER TERM END (for testing purposes)
  Future<void> manuallyEndTerm(String schoolName, String academicYear, String termToEnd) async {
    await _autoAdvanceToNextTerm(schoolName, academicYear, termToEnd);
  }

  // METHOD TO MANUALLY TRIGGER ACADEMIC YEAR END (for testing purposes)
  Future<void> manuallyEndAcademicYear(String schoolName, String academicYear) async {
    await _autoAdvanceToNextAcademicYear(schoolName, academicYear);
  }

  // MARK: - UI Helper Methods
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student Details saved successfully!'),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving Student Details: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // MARK: - Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Enter Student Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      elevation: 2,
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlueAccent.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildForm(),
            const SizedBox(height: 40),
            _buildQRCodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildStyledTextFormField(
            controller: _firstNameController,
            labelText: 'First Name',
            validator: (value) => _validateName(value, 'first name'),
          ),
          const SizedBox(height: 16),
          _buildStyledTextFormField(
            controller: _lastNameController,
            labelText: 'Last Name',
            validator: (value) => _validateName(value, 'last name'),
          ),
          const SizedBox(height: 16),
          _buildStyledDropdownField(
            value: _selectedClass,
            labelText: 'Class',
            items: _classes,
            onChanged: (newValue) => setState(() => _selectedClass = newValue),
            validator: _validateClass,
          ),
          const SizedBox(height: 16),
          _buildStyledTextFormField(
            controller: _dobController,
            labelText: 'Date of Birth (DD-MM-YYYY)',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              _DateInputFormatter(),
            ],
            validator: _validateDateOfBirth,
          ),
          const SizedBox(height: 16),
          _buildStyledDropdownField(
            value: _selectedGender,
            labelText: 'Gender',
            items: _genders,
            onChanged: (newValue) => setState(() => _selectedGender = newValue),
            validator: _validateGender,
          ),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: _saveStudentDetails,
            child: const Text(
              'Save & Generate QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    if (_generatedQRCode == null) return const SizedBox.shrink();

    return Column(
      children: [
        const Text(
          'QR Code Generated Successfully!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: _generatedQRCode!,
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Student ID: $_studentID',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Save this QR code for student identification',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStyledDropdownField({
    required String? value,
    required String labelText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) {
      text = text.substring(0, 8);
    }
    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '-';
      }
      formattedText += text[i];
    }
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}