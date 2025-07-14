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
      setState(() {
        _loggedInUser = user;
      });
    }
  }

  // MARK: - Academic Year Helper Methods
  String _getCurrentAcademicYear() {
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;
    return currentMonth >= 9
        ? '${currentYear}_${currentYear + 1}'
        : '${currentYear - 1}_$currentYear';
  }

  String _getCurrentTerm() {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    if (currentMonth >= 9 && currentMonth <= 12) {
      return 'TERM_ONE';
    } else if (currentMonth >= 1 && currentMonth <= 4) {
      return 'TERM_TWO';
    } else {
      return 'TERM_THREE';
    }
  }

  Map<String, Map<String, String>> _getTermDates(String academicYear) {
    final List<String> yearParts = academicYear.split('_');
    final int startYear = int.parse(yearParts[0]);
    final int endYear = int.parse(yearParts[1]);
    return {
      'TERM_ONE': {
        'start_date': '$startYear-09-01',
        'end_date': '$startYear-12-15',
      },
      'TERM_TWO': {
        'start_date': '$endYear-01-15',
        'end_date': '$endYear-04-30',
      },
      'TERM_THREE': {
        'start_date': '$endYear-05-15',
        'end_date': '$endYear-08-31',
      },
    };
  }

  String _getTermStatus(String term, Map<String, Map<String, String>> termDates) {
    final DateTime now = DateTime.now();
    final String endDateStr = termDates[term]!['end_date']!;
    final DateTime endDate = DateTime.parse(endDateStr);
    final String currentTerm = _getCurrentTerm();
    if (term == currentTerm) {
      return 'In Progress';
    } else if (now.isAfter(endDate)) {
      return 'Completed';
    } else {
      return 'Upcoming';
    }
  }

  int _calculateDaysRemaining(String endDateStr) {
    final DateTime now = DateTime.now();
    final DateTime endDate = DateTime.parse(endDateStr);
    return now.isAfter(endDate) ? 0 : endDate.difference(now).inDays;
  }

  // MARK: - Utility Methods
  String _generateStudentID() {
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    final String second = now.second.toString().padLeft(2, '0');
    return 'STU_${year}${month}${day}_${hour}${minute}${second}';
  }

  int _calculateAge(String dob) {
    try {
      final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      final DateTime birthDate = dateFormat.parseStrict(dob);
      final DateTime currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // MARK: - Validation Methods
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the student\'s $fieldName';
    }
    if (value.trim().length < 2) {
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
    if (value == null || value.trim().isEmpty) {
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
      _studentFullName =
      '${_lastNameController.text.trim().toUpperCase()} ${_firstNameController.text.trim().toUpperCase()}';
      _studentID = _generateStudentID();
      final String schoolName = await _getSchoolName();
      final String currentAcademicYear = _getCurrentAcademicYear();
      final Map<String, Map<String, String>> termDates = _getTermDates(currentAcademicYear);

      final WriteBatch batch = _firestore.batch();
      await _initializeSchoolInfo(batch, schoolName, currentAcademicYear);
      await _initializeFeesDetails(batch, schoolName, currentAcademicYear);
      await _createTermBasedStructure(batch, schoolName, currentAcademicYear, termDates);
      await _updateTotalStudentsCountOnSave(batch, schoolName, _selectedClass!);
      await batch.commit();

      setState(() {
        _generatedQRCode = _studentID;
      });

      _hideLoadingDialog();
      _showSuccessMessage();
      _cleanupControllers();
    } catch (e) {
      _hideLoadingDialog();
      _showErrorMessage(e.toString());
    }
  }

  Future<String> _getSchoolName() async {
    final teacherEmail = _loggedInUser?.email;
    if (teacherEmail == null) throw Exception('No logged-in user');
    final teacherDetails = await _firestore
        .collection('Teachers_Details')
        .doc(teacherEmail)
        .get();
    if (!teacherDetails.exists) throw Exception('Teacher details not found');
    return teacherDetails['school'] as String;
  }

  Future<void> _initializeSchoolInfo(WriteBatch batch, String schoolName, String currentAcademicYear) async {
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
  }

  Future<void> _initializeFeesDetails(WriteBatch batch, String schoolName, String currentAcademicYear) async {
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
  }

  Future<void> _createTermBasedStructure(
      WriteBatch batch, String schoolName, String currentAcademicYear, Map<String, Map<String, String>> termDates) async {
    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final String termStatus = _getTermStatus(term, termDates);
      await _createTermInformations(batch, schoolName, currentAcademicYear, term, termStatus, termDates);
      await _createClassList(batch, schoolName, currentAcademicYear, term, termStatus, termDates);
    }
  }

  Future<void> _createTermInformations(WriteBatch batch, String schoolName, String currentAcademicYear, String term,
      String termStatus, Map<String, Map<String, String>> termDates) async {
    await _createClassInformation(batch, schoolName, currentAcademicYear, term);
    await _createClassPerformance(batch, schoolName, currentAcademicYear, term);
    await _createTeacherDetails(batch, schoolName, currentAcademicYear, term);
    await _createTermStatus(batch, schoolName, currentAcademicYear, term, termStatus, termDates);
  }

  Future<void> _createClassInformation(WriteBatch batch, String schoolName, String currentAcademicYear, String term) async {
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
      Map<String, String> subjectsWithTeachers = {
        for (String subject in _defaultSubjects[_selectedClass]!) subject: 'N/A'
      };
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
  }

  Future<void> _createClassPerformance(WriteBatch batch, String schoolName, String currentAcademicYear, String term) async {
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
        'Subjects_Offered': _defaultSubjects[_selectedClass],
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createTeacherDetails(WriteBatch batch, String schoolName, String currentAcademicYear, String term) async {
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
      Map<String, String> subjectTeachers = {
        for (String subject in _defaultSubjects[_selectedClass]!) subject: 'N/A'
      };
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
  }

  Future<void> _createTermStatus(WriteBatch batch, String schoolName, String currentAcademicYear, String term,
      String termStatus, Map<String, Map<String, String>> termDates) async {
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

  Future<void> _createClassList(WriteBatch batch, String schoolName, String currentAcademicYear, String term,
      String termStatus, Map<String, Map<String, String>> termDates) async {
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

    await _createPersonalInformation(batch, studentRef, term);
    await _createStudentBehaviors(batch, studentRef, term);
    await _createStudentSubjects(batch, studentRef, term);
    await _createEndOfTerm(batch, studentRef, term);
    await _createMidTerm(batch, studentRef, term);
    await _createTest(batch, studentRef, term);
    await _createTotalMarks(batch, studentRef, term);
    await _createStudentAcademicPerformance(batch, studentRef, term);
  }

  Future<void> _createPersonalInformation(WriteBatch batch, DocumentReference studentRef, String term) async {
    batch.set(studentRef.collection('Personal_Information').doc('Student_Details'), {
      'First_Name': _firstNameController.text.trim().toUpperCase(),
      'Last_Name': _lastNameController.text.trim().toUpperCase(),
      'Full_Name': _studentFullName,
      'Student_Class': _selectedClass,
      'Student_DOB': _dobController.text.trim(),
      'Student_Age': _calculateAge(_dobController.text.trim()).toString(),
      'Student_Gender': _selectedGender,
      'Student_ID': _studentID,
      'Term_Name': term,
      'Created_By': _loggedInUser?.email ?? '',
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _createStudentBehaviors(WriteBatch batch, DocumentReference studentRef, String term) async {
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

    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(studentRef.collection('Student_Behaviors').doc(subject), {
        'Subject_Name': subject,
        'Subject_Participation': 'N/A',
        'Homework_Completion': 'N/A',
        'Class_Attention': 'N/A',
        'Assignment_Submission': 'N/A',
        'Subject_Interest': 'N/A',
        'Cooperation_Level': 'N/A',
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

  Future<void> _createStudentSubjects(WriteBatch batch, DocumentReference studentRef, String term) async {
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
  }

  Future<void> _createEndOfTerm(WriteBatch batch, DocumentReference studentRef, String term) async {
    final CollectionReference endOfTermRef = studentRef.collection('End_of_Term');
    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(endOfTermRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Exam_Date': '',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createMidTerm(WriteBatch batch, DocumentReference studentRef, String term) async {
    final CollectionReference midTermRef = studentRef.collection('Mid_Term');
    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(midTermRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Exam_Date': '',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createTest(WriteBatch batch, DocumentReference studentRef, String term) async {
    final CollectionReference testRef = studentRef.collection('Test');
    for (String subject in _defaultSubjects[_selectedClass]!) {
      batch.set(testRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Test_Date': '',
        'Test_Type': 'Regular Test',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createTotalMarks(WriteBatch batch, DocumentReference studentRef, String term) async {
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
  }

  Future<void> _createStudentAcademicPerformance(WriteBatch batch, DocumentReference studentRef, String currentTerm) async {
    final CollectionReference academicPerformanceRef = studentRef.collection('Academic_Performance');
    final Map<String, dynamic> performanceTemplate = {
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
    };

    for (var termResult in [
      {'Term_Name': 'TERM ONE', 'doc_id': 'TERM_ONE_RESULTS'},
      {'Term_Name': 'TERM TWO', 'doc_id': 'TERM_TWO_RESULTS'},
      {'Term_Name': 'TERM THREE', 'doc_id': 'TERM_THREE_RESULTS'},
    ]) {
      Map<String, dynamic> termData = Map.from(performanceTemplate);
      termData['Term_Name'] = termResult['Term_Name'];
      batch.set(academicPerformanceRef.doc(termResult['doc_id']), termData);
    }
  }

  Future<void> _updateTotalStudentsCountOnSave(WriteBatch batch, String schoolName, String className) async {
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

      batch.update(classInfoRef, {
        'Total_Students': FieldValue.increment(1),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  // MARK: - Copy Operations
  Future<void> _copyStudentToNextAcademicYear(
      String schoolName, String currentAcademicYear, String currentClass, String studentName) async {
    try {
      _showLoadingDialog();
      final String nextAcademicYear = _getNextAcademicYear(currentAcademicYear);
      final String? nextClass = _getNextClass(currentClass);
      if (nextClass == null) {
        _hideLoadingDialog();
        _showErrorMessage('No next class available for $currentClass');
        return;
      }

      final WriteBatch batch = _firestore.batch();
      await _initializeSchoolInfo(batch, schoolName, nextAcademicYear);
      await _initializeFeesDetails(batch, schoolName, nextAcademicYear);
      final Map<String, Map<String, String>> termDates = _getTermDates(nextAcademicYear);

      final DocumentReference fromStudentRef = _getStudentReference(
          schoolName, currentAcademicYear, currentClass, 'TERM_THREE', studentName);
      final DocumentReference toStudentRef = _getStudentReference(
          schoolName, nextAcademicYear, nextClass, 'TERM_ONE', studentName);

      await _createPersonalInformationForNewYear(batch, fromStudentRef, toStudentRef, nextClass);
      await _createStudentBehaviorsForNewYear(batch, toStudentRef, nextClass);
      await _createStudentSubjectsForNewYear(batch, toStudentRef, nextClass, 'TERM_ONE');
      await _createEndOfTermForNewYear(batch, toStudentRef, nextClass, 'TERM_ONE');
      await _createMidTermForNewYear(batch, toStudentRef, nextClass, 'TERM_ONE');
      await _createTestForNewYear(batch, toStudentRef, nextClass, 'TERM_ONE');
      await _createTotalMarksForNewYear(batch, toStudentRef);
      await _createStudentAcademicPerformance(batch, toStudentRef, 'TERM_ONE');
      await _updateTotalStudentsCountOnSave(batch, schoolName, nextClass);

      await batch.commit();
      _hideLoadingDialog();
      _showSuccessMessage();
    } catch (e) {
      _hideLoadingDialog();
      _showErrorMessage('Error copying student to next academic year: $e');
    }
  }

  Future<void> _copyClassListToNextTerm(
      String schoolName, String academicYear, String className, String fromTerm) async {
    try {
      _showLoadingDialog();
      final String? toTerm = _getNextTerm(fromTerm);
      if (toTerm == null) {
        _hideLoadingDialog();
        _showErrorMessage('No next term available for $fromTerm');
        return;
      }

      final WriteBatch batch = _firestore.batch();
      final Map<String, Map<String, String>> termDates = _getTermDates(academicYear);
      final String termStatus = _getTermStatus(toTerm, termDates);

      // Initialize term structure for the next term
      await _createClassInformation(batch, schoolName, academicYear, toTerm);
      await _createClassPerformance(batch, schoolName, academicYear, toTerm);
      await _createTeacherDetails(batch, schoolName, academicYear, toTerm);
      await _createTermStatus(batch, schoolName, academicYear, toTerm, termStatus, termDates);

      // Get all students in the current term's class list
      final QuerySnapshot studentDocs = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Academic_Year')
          .doc(academicYear)
          .collection('Classes')
          .doc(className)
          .collection(fromTerm)
          .doc('Term_Informations')
          .collection('Class_List')
          .get();

      for (QueryDocumentSnapshot studentDoc in studentDocs.docs) {
        final String studentName = studentDoc.id;
        final DocumentReference fromStudentRef = _getStudentReference(
            schoolName, academicYear, className, fromTerm, studentName);
        final DocumentReference toStudentRef = _getStudentReference(
            schoolName, academicYear, className, toTerm, studentName);

        await _copyPersonalInformation(batch, fromStudentRef, toStudentRef, toTerm);
        await _copyStudentBehaviors(batch, fromStudentRef, toStudentRef, toTerm);
        await _copyAndResetSubjectCollection(batch, fromStudentRef, toStudentRef, 'Student_Subjects', toTerm);
        await _copyAndResetSubjectCollection(batch, fromStudentRef, toStudentRef, 'End_of_Term', toTerm);
        await _copyAndResetSubjectCollection(batch, fromStudentRef, toStudentRef, 'Mid_Term', toTerm);
        await _copyAndResetSubjectCollection(batch, fromStudentRef, toStudentRef, 'Test', toTerm);
        await _copyTotalMarks(batch, fromStudentRef, toStudentRef, toTerm);
        await _copyAcademicPerformance(batch, fromStudentRef, toStudentRef, toTerm);
      }

      await _updateTotalStudentsCountOnSave(batch, schoolName, className);
      await batch.commit();
      _hideLoadingDialog();
      _showSuccessMessage();
    } catch (e) {
      _hideLoadingDialog();
      _showErrorMessage('Error copying class list to next term: $e');
    }
  }

// Helper methods for copy operations
  String _getNextAcademicYear(String currentAcademicYear) {
    final List<String> years = currentAcademicYear.split('_');
    final int startYear = int.parse(years[0]);
    return '${startYear + 1}_${startYear + 2}';
  }

  String? _getNextClass(String currentClass) {
    switch (currentClass) {
      case 'FORM 1':
        return 'FORM 2';
      case 'FORM 2':
        return 'FORM 3';
      case 'FORM 3':
        return 'FORM 4';
      case 'FORM 4':
        return null; // No next class for FORM 4
      default:
        return null;
    }
  }

  String? _getNextTerm(String currentTerm) {
    switch (currentTerm) {
      case 'TERM_ONE':
        return 'TERM_TWO';
      case 'TERM_TWO':
        return 'TERM_THREE';
      case 'TERM_THREE':
        return null; // No next term in the same academic year
      default:
        return null;
    }
  }

  Future<void> _copyPersonalInformation(
      WriteBatch batch, DocumentReference fromStudentRef, DocumentReference toStudentRef, String toTerm) async {
    final DocumentSnapshot personalInfoDoc =
    await fromStudentRef.collection('Personal_Information').doc('Student_Details').get();
    if (personalInfoDoc.exists) {
      final Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;
      personalData['Term_Name'] = toTerm;
      personalData['Last_Updated'] = FieldValue.serverTimestamp();
      batch.set(toStudentRef.collection('Personal_Information').doc('Student_Details'), personalData);
    }
  }

  Future<void> _createPersonalInformationForNewYear(
      WriteBatch batch, DocumentReference fromStudentRef, DocumentReference toStudentRef, String nextClass) async {
    final DocumentSnapshot personalInfoDoc =
    await fromStudentRef.collection('Personal_Information').doc('Student_Details').get();
    if (personalInfoDoc.exists) {
      final Map<String, dynamic> personalData = personalInfoDoc.data() as Map<String, dynamic>;
      personalData['Student_Class'] = nextClass;
      personalData['Term_Name'] = 'TERM_ONE';
      personalData['Last_Updated'] = FieldValue.serverTimestamp();
      batch.set(toStudentRef.collection('Personal_Information').doc('Student_Details'), personalData);
    }
  }

  Future<void> _copyStudentBehaviors(
      WriteBatch batch, DocumentReference fromStudentRef, DocumentReference toStudentRef, String toTerm) async {
    final QuerySnapshot behaviorDocs = await fromStudentRef.collection('Student_Behaviors').get();
    for (QueryDocumentSnapshot behaviorDoc in behaviorDocs.docs) {
      final Map<String, dynamic> behaviorData = behaviorDoc.data() as Map<String, dynamic>;
      _resetBehaviorData(behaviorData, behaviorDoc.id, toTerm);
      batch.set(toStudentRef.collection('Student_Behaviors').doc(behaviorDoc.id), behaviorData);
    }
  }

  Future<void> _createStudentBehaviorsForNewYear(
      WriteBatch batch, DocumentReference toStudentRef, String nextClass) async {
    batch.set(toStudentRef.collection('Student_Behaviors').doc('General_Behavior'), {
      'Overall_Conduct': 'N/A',
      'Class_Participation': 'N/A',
      'Punctuality': 'N/A',
      'Disciplinary_Records': [],
      'General_Behavior_Notes': '',
      'Term_Name': 'TERM_ONE',
      'Created_By': _loggedInUser?.email ?? '',
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });

    for (String subject in _defaultSubjects[nextClass]!) {
      batch.set(toStudentRef.collection('Student_Behaviors').doc(subject), {
        'Subject_Name': subject,
        'Subject_Participation': 'N/A',
        'Homework_Completion': 'N/A',
        'Class_Attention': 'N/A',
        'Assignment_Submission': 'N/A',
        'Subject_Interest': 'N/A',
        'Cooperation_Level': _loggedInUser?.email ?? '',
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _copyAndResetSubjectCollection(WriteBatch batch, DocumentReference fromStudentRef,
      DocumentReference toStudentRef, String collectionName, String toTerm) async {
    final QuerySnapshot subjectDocs = await fromStudentRef.collection(collectionName).get();
    for (QueryDocumentSnapshot subjectDoc in subjectDocs.docs) {
      final Map<String, dynamic> subjectData = subjectDoc.data() as Map<String, dynamic>;
      _resetSubjectData(subjectData, collectionName, toTerm);
      batch.set(toStudentRef.collection(collectionName).doc(subjectDoc.id), subjectData);
    }
  }

  Future<void> _createStudentSubjectsForNewYear(
      WriteBatch batch, DocumentReference studentRef, String nextClass, String term) async {
    final CollectionReference subjectsRef = studentRef.collection('Student_Subjects');
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
  }

  Future<void> _createEndOfTermForNewYear(
      WriteBatch batch, DocumentReference studentRef, String nextClass, String term) async {
    final CollectionReference endOfTermRef = studentRef.collection('End_of_Term');
    for (String subject in _defaultSubjects[nextClass]!) {
      batch.set(endOfTermRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Exam_Date': '',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createMidTermForNewYear(
      WriteBatch batch, DocumentReference studentRef, String nextClass, String term) async {
    final CollectionReference midTermRef = studentRef.collection('Mid_Term');
    for (String subject in _defaultSubjects[nextClass]!) {
      batch.set(midTermRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Exam_Date': '',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createTestForNewYear(
      WriteBatch batch, DocumentReference studentRef, String nextClass, String term) async {
    final CollectionReference testRef = studentRef.collection('Test');
    for (String subject in _defaultSubjects[nextClass]!) {
      batch.set(testRef.doc(subject), {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
        'Marks_Obtained': 0,
        'Total_Marks': 0,
        'Percentage': 0.0,
        'Teacher_Assigned': 'N/A',
        'Test_Date': '',
        'Test_Type': 'Regular Test',
        'Comments': '',
        'Term_Name': term,
        'Created_At': FieldValue.serverTimestamp(),
        'Last_Updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createTotalMarksForNewYear(WriteBatch batch, DocumentReference studentRef) async {
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
      'Term_Name': 'TERM_ONE',
      'Created_At': FieldValue.serverTimestamp(),
      'Last_Updated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _copyTotalMarks(
      WriteBatch batch, DocumentReference fromStudentRef, DocumentReference toStudentRef, String toTerm) async {
    final DocumentSnapshot totalMarksDoc =
    await fromStudentRef.collection('Total_Marks').doc('Marks_Summary').get();
    if (totalMarksDoc.exists) {
      final Map<String, dynamic> totalMarksData = totalMarksDoc.data() as Map<String, dynamic>;
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
  }

  Future<void> _copyAcademicPerformance(
      WriteBatch batch, DocumentReference fromStudentRef, DocumentReference toStudentRef, String toTerm) async {
    final QuerySnapshot academicDocs = await fromStudentRef.collection('Academic_Performance').get();
    for (QueryDocumentSnapshot academicDoc in academicDocs.docs) {
      final Map<String, dynamic> academicData = academicDoc.data() as Map<String, dynamic>;
      academicData['Overall_Grade'] = 'N/A';
      academicData['Overall_Percentage'] = 0.0;
      academicData['Class_Ranking'] = 0;
      academicData['Passed_Subjects'] = 0;
      academicData['Failed_Subjects'] = 0;
      academicData['Best_Subject'] = 'N/A';
      academicData['Weakest_Subject'] = 'N/A';
      academicData['Improvement_Areas'] = [];
      academicData['Strengths'] = [];
      academicData['Teacher_Recommendations'] = '';
      academicData['Parent_Feedback'] = '';
      academicData['Subject_Grades'] = {};
      academicData['Subject_Marks'] = {};
      academicData['Total_Marks_Obtained'] = 0;
      academicData['Total_Possible_Marks'] = 0;
      academicData['Current_Term'] = toTerm;
      academicData['Last_Updated'] = FieldValue.serverTimestamp();
      batch.set(toStudentRef.collection('Academic_Performance').doc(academicDoc.id), academicData);
    }
  }

  void _resetBehaviorData(Map<String, dynamic> behaviorData, String docId, String termName) {
    if (docId == 'General_Behavior') {
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
    behaviorData['Term_Name'] = termName;
    behaviorData['Last_Updated'] = FieldValue.serverTimestamp();
  }

  void _resetSubjectData(Map<String, dynamic> subjectData, String collectionName, String toTerm) {
    subjectData['Subject_Grade'] = 'N/A';
    subjectData['Marks_Obtained'] = 0;
    subjectData['Total_Marks'] = 0;
    subjectData['Percentage'] = 0.0;
    subjectData['Teacher_Assigned'] = 'N/A';
    subjectData['Term_Name'] = toTerm;
    subjectData['Last_Updated'] = FieldValue.serverTimestamp();
    switch (collectionName) {
      case 'End_of_Term':
      case 'Mid_Term':
        subjectData['Exam_Date'] = '';
        subjectData['Comments'] = '';
        break;
      case 'Test':
        subjectData['Test_Date'] = '';
        subjectData['Test_Type'] = 'Regular Test';
        subjectData['Comments'] = '';
        break;
    }
  }

  DocumentReference _getStudentReference(
      String schoolName, String academicYear, String className, String term, String studentName) {
    return _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Academic_Year')
        .doc(academicYear)
        .collection('Classes')
        .doc(className)
        .collection(term)
        .doc('Term_Informations')
        .collection('Class_List')
        .doc(studentName);
  }

  void _cleanupControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _dobController.clear();
    setState(() {
      _selectedGender = null;
      _selectedClass = null;
      _generatedQRCode = null;
      _studentID = null;
      _studentFullName = null;
    });
  }

  // MARK: - UI Helper Methods
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
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
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            onPressed: _saveStudentDetails,
            child: const Text(
              'Save & Generate QR Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Save this QR code for student identification',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
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