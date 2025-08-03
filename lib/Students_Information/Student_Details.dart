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

  // School Information
  String? schoolFees;
  String? schoolBankAccount;
  String? nextTermOpeningDate;
  String? userEmail;
  String? schoolName;
  String? schoolPhone;
  String? schoolEmail;
  String? formTeacherRemarks;
  String? headTeacherRemarks;
  int boxNumber = 0;
  String schoolLocation = 'N/A';

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
      'CHEMISTRY', 'CHICHEWA', 'COMPUTER SCIENCE', 'ENGLISH', 'GEOGRAPHY',
      'HISTORY', 'HOME ECONOMICS', 'LIFE & SOCIAL', 'MATHEMATICS', 'PHYSICS'
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
      // September onwards = start of new academic year
      startYear = now.year;
      endYear = now.year + 1;
    } else {
      // January to August = continuation of academic year that started previous year
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
      return 'TERM_ONE'; // Default fallback
    }
  }

  // Helper method to check if a term is in the past
  bool _isTermInPast(String term) {
    final String currentTerm = _getCurrentTerm();

    // Define term order
    const List<String> termOrder = ['TERM_ONE', 'TERM_TWO', 'TERM_THREE'];

    final int currentTermIndex = termOrder.indexOf(currentTerm);
    final int checkTermIndex = termOrder.indexOf(term);

    return checkTermIndex < currentTermIndex;
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

      _studentFullName = '${_lastNameController.text.trim().toUpperCase()}'
          ' ${_firstNameController.text.trim().toUpperCase()}';
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

    // Main student document
    final DocumentReference studentRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('Classes')
        .doc(_selectedClass)
        .collection('Student_Details')
        .doc(_studentFullName);

    batch.set(studentRef, {
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Personal information
    final DocumentReference personalInfoRef = studentRef
        .collection('Personal_Information')
        .doc('Registered_Information');

    batch.set(personalInfoRef, {
      'firstName': _firstNameController.text.trim().toUpperCase(),
      'lastName': _lastNameController.text.trim().toUpperCase(),
      'studentClass': _selectedClass!,
      'studentDOB': _dobController.text.trim(),
      'studentAge': _calculateAge(_dobController.text.trim()).toString(),
      'studentGender': _selectedGender!,
      'studentID': _studentID!,
      'createdBy': _loggedInUser?.email ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Student subjects
    for (String subject in _defaultSubjects[_selectedClass]!) {
      final DocumentReference subjectRef = studentRef
          .collection('Student_Subjects')
          .doc(subject);

      batch.set(subjectRef, {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
      });
    }

    // Total marks document
    final DocumentReference totalMarksRef = studentRef
        .collection('TOTAL_MARKS')
        .doc('Marks');

    batch.set(totalMarksRef, {
      'Aggregate_Grade': 'N/A',
      'Best_Six_Total_Points': 0,
      'Student_Total_Marks': '0',
      'Teacher_Total_Marks': '0',
    });

    // Results remarks document
    final DocumentReference resultsRemarksRef = studentRef
        .collection('TOTAL_MARKS')
        .doc('Results_Remarks');

    batch.set(resultsRemarksRef, {
      'Form_Teacher_Remark': 'N/A',
      'Head_Teacher_Remark': 'N/A',
    });

    // Academic Performance Structure
    await _createAcademicPerformanceStructure(batch, studentRef);

    try {
      await batch.commit();
      print("Student data saved successfully!");
    } catch (e) {
      print("Error saving student data: $e");
      throw e;
    }
  }

  Future<void> _createAcademicPerformanceStructure(WriteBatch batch, DocumentReference studentRef) async {
    final String currentAcademicYear = _getCurrentAcademicYear();
    final String currentTerm = _getCurrentTerm();
    final Map<String, Map<String, String>> termDates = _getTermDates(currentAcademicYear);

    // Create Academic_Performance document
    final DocumentReference academicPerformanceRef = studentRef
        .collection('Academic_Performance')
        .doc(currentAcademicYear);

    batch.set(academicPerformanceRef, {
      'academic_year': currentAcademicYear,
      'created_at': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
      // References to existing collections
      'personal_info_ref': 'Personal_Information/Registered_Information',
      'subjects_ref': 'Student_Subjects',
      'total_marks_ref': 'TOTAL_MARKS',
    });

    // Create structure for each term
    for (String term in ['TERM_ONE', 'TERM_TWO', 'TERM_THREE']) {
      final bool isPastTerm = _isTermInPast(term);
      final bool isCurrentTerm = term == currentTerm;

      final DocumentReference termRef = academicPerformanceRef
          .collection(term)
          .doc('Term_Info');

      batch.set(termRef, {
        'term_name': term,
        'start_date': termDates[term]!['start_date'],
        'end_date': termDates[term]!['end_date'],
        'term_status': isPastTerm ? 'Completed' : isCurrentTerm ? 'Current' : 'Not Started',
        'created_at': FieldValue.serverTimestamp(),
        // Reference to existing Student_Subjects collection for marks
        'subjects_collection_ref': '../../Student_Subjects',
        'total_marks_ref': '../../TOTAL_MARKS',
      });

      // Create Student_Behavior document inside Term_Info
      final DocumentReference studentBehaviorRef = termRef
          .collection('Student_Behavior')
          .doc('Behavior_Records');

      batch.set(studentBehaviorRef, {
        'conduct': isPastTerm ? 'N/A' : 'N/A',
        'class_participation': isPastTerm ? 'N/A' : 'N/A',
        'punctuality': isPastTerm ? 'N/A' : 'N/A',
        'disciplinary_records': isPastTerm ? [] : [],
        'behavior_notes': isPastTerm ? 'N/A' : 'N/A',
        'term_name': term,
        'academic_year': currentAcademicYear,
        'last_updated': FieldValue.serverTimestamp(),
        'updated_by': isPastTerm ? 'system' : (_loggedInUser?.email ?? 'system'),
        'behavior_status': isPastTerm ? 'Past Term - No Records' : 'Not Evaluated',
      });

      // Create Student_Fees document for all terms (UPDATED STRUCTURE)
      // Note: UI will show current term only, but all terms need fee structure
      if (isCurrentTerm || isPastTerm) {
        // Create school-level fee structure (keep existing)
        final DocumentReference schoolFeesRef = termRef
            .collection('School_Fees_Structure')
            .doc('Fee_Structure');

        batch.set(schoolFeesRef, {
          'term_name': term,
          'academic_year': currentAcademicYear,
          'class': _selectedClass!,

          // School Fee Structure (amounts set by school)
          'tuition_fee': '0',
          'examination_fee': '0',
          'library_fee': '0',
          'laboratory_fee': '0',
          'sports_fee': '0',
          'development_fee': '0',
          'transport_fee': '0',
          'meal_fee': '0',
          'uniform_fee': '0',
          'stationery_fee': '0',
          'other_fees': '0',
          'total_school_fees': '0',

          // School settings
          'payment_due_date': termDates[term]!['end_date'],
          'late_payment_penalty': '0',
          'discount_policies': 'N/A',

          // Timestamps
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
          'updated_by': _loggedInUser?.email ?? 'system',

          'fee_structure_notes': 'Fee structure to be updated by admin/finance department',
        });

        // Create STUDENT-LEVEL fee payment tracking (NEW LOCATION)
        final DocumentReference studentFeesRef = studentRef
            .collection('Student_Fee_Payments')
            .doc(currentAcademicYear)
            .collection(term)
            .doc('Payment_Records');

        batch.set(studentFeesRef, {
          'student_id': _studentID!,
          'student_name': _studentFullName,
          'student_class': _selectedClass!,
          'term_name': term,
          'academic_year': currentAcademicYear,

          // Individual Payment Records (what student has paid)
          'tuition_fee_paid': '0',
          'examination_fee_paid': '0',
          'library_fee_paid': '0',
          'laboratory_fee_paid': '0',
          'sports_fee_paid': '0',
          'development_fee_paid': '0',
          'transport_fee_paid': '0',
          'meal_fee_paid': '0',
          'uniform_fee_paid': '0',
          'stationery_fee_paid': '0',
          'other_fees_paid': '0',

          // Remaining amounts (what student still owes)
          'tuition_fee_remaining': '0',
          'examination_fee_remaining': '0',
          'library_fee_remaining': '0',
          'laboratory_fee_remaining': '0',
          'sports_fee_remaining': '0',
          'development_fee_remaining': '0',
          'transport_fee_remaining': '0',
          'meal_fee_remaining': '0',
          'uniform_fee_remaining': '0',
          'stationery_fee_remaining': '0',
          'other_fees_remaining': '0',

          // Summary totals
          'total_amount_paid': '0',
          'total_amount_remaining': '0',
          'total_fees_assigned': '0',
          'payment_status': 'Not Paid',

          // Payment tracking
          'last_payment_date': null,
          'last_payment_amount': '0',
          'payment_method': 'N/A',
          'receipt_number': 'N/A',
          'payment_percentage': '0.0',

          // Timestamps and tracking
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
          'updated_by': _loggedInUser?.email ?? 'system',

          // Student-specific information
          'parent_guardian_name': 'N/A',
          'parent_guardian_phone': 'N/A',
          'parent_guardian_email': 'N/A',
          'billing_address': 'N/A',

          // Payment plan and special cases
          'payment_plan_active': 'false',
          'payment_plan_details': 'N/A',
          'discount_applied': '0',
          'discount_reason': 'N/A',
          'penalty_applied': '0',
          'penalty_reason': 'N/A',

          // Notes and remarks
          'payment_notes': isPastTerm
              ? 'Payment record for completed term - fees may have been paid'
              : 'Initial payment record created for new student',
          'admin_remarks': isPastTerm
              ? 'Past term - verify payment status with finance department'
              : 'Awaiting fee assignment from school fee structure',
          'special_instructions': 'N/A',

          // Reference to school fee structure
          'school_fee_structure_ref': 'Academic_Performance/$currentAcademicYear/$term/School_Fees_Structure/Fee_Structure',
        });

        // Create Payment History for student
        final DocumentReference studentPaymentHistoryRef = studentFeesRef
            .collection('Individual_Payment_History')
            .doc('Payment_Transactions');

        batch.set(studentPaymentHistoryRef, {
          'student_id': _studentID!,
          'term_name': term,
          'academic_year': currentAcademicYear,
          'payment_transactions': [],
          'total_transactions': '0',
          'total_amount_paid': '0',
          'first_payment_date': null,
          'last_payment_date': null,
          'payment_history_notes': 'No payments recorded yet',
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });

        // Create Student Fee Summary for CURRENT TERM only (term-specific)
        final DocumentReference studentFeeSummaryRef = studentRef
            .collection('Student_Fee_Payments')
            .doc(currentAcademicYear)
            .collection(term)
            .doc('Term_Fee_Summary');

        batch.set(studentFeeSummaryRef, {
          'student_id': _studentID!,
          'student_name': _studentFullName,
          'student_class': _selectedClass!,
          'term_name': term,
          'academic_year': currentAcademicYear,

          // Term-specific totals
          'term_total_fees': '0',
          'term_total_paid': '0',
          'term_total_remaining': '0',
          'term_payment_percentage': '0.0',

          // Term payment status
          'term_payment_status': 'Not Started',
          'payment_deadline': termDates[term]!['end_date'],
          'is_payment_overdue': 'false',
          'days_overdue': '0',

          // Term payment tracking
          'first_payment_date_for_term': null,
          'last_payment_date_for_term': null,
          'total_payment_transactions_for_term': '0',
          'payment_completion_date': null,

          // Term-specific notes
          'term_payment_notes': 'Term fee tracking initialized for $term',
          'payment_reminders_sent': '0',
          'parent_notifications_sent': '0',

          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      }

      // Create term-specific marks tracking
      final DocumentReference termMarksRef = termRef
          .collection('Term_Marks')
          .doc('Marks_Summary');

      batch.set(termMarksRef, {
        'term_name': term,
        'subjects_source': 'Student_Subjects',
        'marks_entered': isPastTerm,
        'marks_verified': isPastTerm,
        'last_updated': FieldValue.serverTimestamp(),
        'updated_by': isPastTerm ? 'system' : (_loggedInUser?.email ?? 'system'),
      });

      // Create individual subject marks for past terms
      if (isPastTerm) {
        for (String subject in _defaultSubjects[_selectedClass]!) {
          final DocumentReference subjectMarksRef = termMarksRef
              .collection('Subject_Marks')
              .doc(subject);

          batch.set(subjectMarksRef, {
            'subject_name': subject,
            'marks_obtained': 'N/A',
            'total_marks': 'N/A',
            'percentage': 'N/A',
            'grade': 'N/A',
            'remarks': 'N/A',
            'teacher_comment': 'N/A',
            'last_updated': FieldValue.serverTimestamp(),
            'updated_by': 'system',
          });
        }
      }

      // Create term summary
      final DocumentReference termSummaryRef = termRef
          .collection('Term_Summary')
          .doc('Summary');

      batch.set(termSummaryRef, {
        'total_marks': isPastTerm ? 'N/A' : 0,
        'average_marks': isPastTerm ? 'N/A' : 0.0,
        'total_subjects': _defaultSubjects[_selectedClass]!.length,
        'subjects_passed': isPastTerm ? 'N/A' : 0,
        'subjects_failed': isPastTerm ? 'N/A' : 0,
        'overall_grade': 'N/A',
        'class_position': isPastTerm ? 'N/A' : 0,
        'form_teacher_remarks': 'N/A',
        'head_teacher_remarks': 'N/A',
        'term_completed': isPastTerm,
        'completion_date': isPastTerm ? termDates[term]!['end_date'] : null,
        'last_updated': FieldValue.serverTimestamp(),
        // References for calculations
        'calculated_from_subjects': 'Student_Subjects',
        'total_marks_source': 'TOTAL_MARKS',
      });

      // Create attendance structure for each term
      final DocumentReference attendanceRef = termRef
          .collection('Attendance')
          .doc('Attendance_Summary');

      batch.set(attendanceRef, {
        'total_school_days': isPastTerm ? 'N/A' : 0,
        'days_present': isPastTerm ? 'N/A' : 0,
        'days_absent': isPastTerm ? 'N/A' : 0,
        'attendance_percentage': isPastTerm ? 'N/A' : 0.0,
        'late_arrivals': isPastTerm ? 'N/A' : 0,
        'early_departures': isPastTerm ? 'N/A' : 0,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Create detailed attendance records for past terms
      if (isPastTerm) {
        final DocumentReference attendanceDetailsRef = attendanceRef
            .collection('Attendance_Details')
            .doc('Daily_Records');

        batch.set(attendanceDetailsRef, {
          'term_name': term,
          'attendance_records': 'N/A',
          'daily_attendance': 'N/A',
          'weekly_summary': 'N/A',
          'monthly_summary': 'N/A',
          'notes': 'Records not available for past terms',
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    }

    // Create Academic Year Summary
    final DocumentReference yearSummaryRef = academicPerformanceRef
        .collection('Year_Summary')
        .doc('Academic_Summary');

    batch.set(yearSummaryRef, {
      'academic_year': currentAcademicYear,
      'total_terms': 3,
      'completed_terms': 2, // TERM_ONE and TERM_TWO are completed
      'overall_average': 'N/A',
      'best_term': 'N/A',
      'weakest_term': 'N/A',
      'year_grade': 'N/A',
      'promoted_to_next_class': false,
      'promotion_status': 'Pending',
      'year_completed': false,
      'completion_date': null,
      'last_updated': FieldValue.serverTimestamp(),
      // References for year-end calculations
      'personal_info_source': 'Personal_Information',
      'subjects_source': 'Student_Subjects',
      'total_marks_source': 'TOTAL_MARKS',
      'past_terms_note': 'TERM_ONE and TERM_TWO marks initialized with N/A values',
      'behavior_tracking_note': 'Student behavior tracking included for all terms',
      'fees_tracking_note': 'Student fees tracking included for current term only',
    });

    print("Academic Performance structure created for academic year: $currentAcademicYear");
    print("Past terms (TERM_ONE and TERM_TWO) initialized with N/A values");
    print("Student Behavior tracking added for all terms");
    print("Student Fees tracking added for current term: $currentTerm");
    print("Structure references existing collections: Personal_Information, Student_Subjects, TOTAL_MARKS");
    print("Updated Student Fees structure with separate school fee structure and student payment tracking");
  }

  Future<void> _updateTotalStudentsCountOnSave(String school, String studentClass) async {
    try {
      final DocumentReference classInfoRef = _firestore
          .collection('Schools')
          .doc(school)
          .collection('Classes')
          .doc(studentClass)
          .collection('Class_Info')
          .doc('Info');

      final DocumentSnapshot classInfoDoc = await classInfoRef.get();

      if (classInfoDoc.exists) {
        final Map<String, dynamic> classData = classInfoDoc.data() as Map<String, dynamic>;
        final int currentCount = classData['totalStudents'] ?? 0;
        final int newCount = currentCount + 1;

        await classInfoRef.update({
          'totalStudents': newCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _totalClassStudentsNumber = newCount;
          });
        }
      } else {
        final QuerySnapshot studentsSnapshot = await _firestore
            .collection('Schools')
            .doc(school)
            .collection('Classes')
            .doc(studentClass)
            .collection('Student_Details')
            .get();

        final int totalCount = studentsSnapshot.docs.length;

        await classInfoRef.set({
          'totalStudents': totalCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _totalClassStudentsNumber = totalCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating total students count on save: $e');
    }
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
          fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w400,
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
                fontSize: 15,
                fontWeight: FontWeight.w400,
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

// Date Input Formatter Class
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;

    // Remove any non-digit characters
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 8 digits (DDMMYYYY)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Format the text with dashes
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