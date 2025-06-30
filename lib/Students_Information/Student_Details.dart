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

    // 1. School Information Document
    final DocumentReference schoolInfoRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('School_Information')
        .doc('School_Details');

    batch.set(schoolInfoRef, {
      'Telephone': '',
      'Email': '',
      'boxNumber': 0,
      'schoolLocation': '',
      'School_Fees': '',
      'School_Bank_Account': '',
      'Next_Term_Opening_Date': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Fees Details Document (updated with new fields)
    final DocumentReference feesDetailsRef = _firestore
        .collection('Schools')
        .doc(schoolName)
        .collection('School_Information')
        .doc('Fees_Details');

    batch.set(feesDetailsRef, {
      'tuition_fee': 0,
      'development_fee': 0,
      'library_fee': 0,
      'sports_fee': 0,
      'laboratory_fee': 0,
      'other_fees': 0,
      'total_fees': 0,
      'bank_account_number': '',
      'amount_paid': 0,
      'outstanding_balance': 0,
      'next_payment_due': '',
      'bank_name': 'N/A',
      'bank_account_name': 'N/A',
      'bank_account_number': 'N/A',
      'airtel_money': 'N/A',
      'tnm_mpamba': 'N/A',
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Main student document
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

    // 4. Personal information
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

    // 5. Student subjects
    for (String subject in _defaultSubjects[_selectedClass]!) {
      final DocumentReference subjectRef = studentRef
          .collection('Student_Subjects')
          .doc(subject);

      batch.set(subjectRef, {
        'Subject_Name': subject,
        'Subject_Grade': 'N/A',
      });
    }

    // 6. Total marks document
    final DocumentReference totalMarksRef = studentRef
        .collection('TOTAL_MARKS')
        .doc('Marks');

    batch.set(totalMarksRef, {
      'Aggregate_Grade': 'N/A',
      'Best_Six_Total_Points': 0,
      'Student_Total_Marks': '0',
      'Teacher_Total_Marks': '0',
    });

    // 7. Results remarks document
    final DocumentReference resultsRemarksRef = studentRef
        .collection('TOTAL_MARKS')
        .doc('Results_Remarks');

    batch.set(resultsRemarksRef, {
      'Form_Teacher_Remark': 'N/A',
      'Head_Teacher_Remark': 'N/A',
    });

    // 8. Academic Performance Structure
    await _createAcademicPerformanceStructure(batch, studentRef);

    try {
      await batch.commit();
      print("Student, school information, and fees structure saved successfully!");
    } catch (e) {
      print("Error saving data: $e");
      throw e;
    }
  }

  // MARK: - Academic Performance Structure Creation (Updated to reference existing data)
  Future<void> _createAcademicPerformanceStructure(WriteBatch batch, DocumentReference studentRef) async {
    final String currentAcademicYear = _getCurrentAcademicYear();
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
      final DocumentReference termRef = academicPerformanceRef
          .collection(term)
          .doc('Term_Info');

      batch.set(termRef, {
        'term_name': term,
        'start_date': termDates[term]!['start_date'],
        'end_date': termDates[term]!['end_date'],
        'term_status': 'Not Started',
        'created_at': FieldValue.serverTimestamp(),
        // Reference to existing Student_Subjects collection for marks
        'subjects_collection_ref': '../../Student_Subjects',
        'total_marks_ref': '../../TOTAL_MARKS',
      });

      // Create term-specific marks tracking (references existing subjects)
      final DocumentReference termMarksRef = termRef
          .collection('Term_Marks')
          .doc('Marks_Summary');

      batch.set(termMarksRef, {
        'term_name': term,
        // This will reference the Student_Subjects collection for individual subject marks
        'subjects_source': 'Student_Subjects', // Points to existing collection
        'marks_entered': false,
        'marks_verified': false,
        'last_updated': FieldValue.serverTimestamp(),
        'updated_by': _loggedInUser?.email ?? 'system',
      });

      // Create term summary (calculations based on existing data)
      final DocumentReference termSummaryRef = termRef
          .collection('Term_Summary')
          .doc('Summary');

      batch.set(termSummaryRef, {
        'total_marks': 0,
        'average_marks': 0.0,
        'total_subjects': _defaultSubjects[_selectedClass]!.length,
        'subjects_passed': 0,
        'subjects_failed': 0,
        'overall_grade': 'N/A',
        'class_position': 0,
        'form_teacher_remarks': 'N/A',
        'head_teacher_remarks': 'N/A',
        'term_completed': false,
        'completion_date': null,
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
        'total_school_days': 0,
        'days_present': 0,
        'days_absent': 0,
        'attendance_percentage': 0.0,
        'late_arrivals': 0,
        'early_departures': 0,
        'last_updated': FieldValue.serverTimestamp(),
      });
    }

    // Create Academic Year Summary
    final DocumentReference yearSummaryRef = academicPerformanceRef
        .collection('Year_Summary')
        .doc('Academic_Summary');

    batch.set(yearSummaryRef, {
      'academic_year': currentAcademicYear,
      'total_terms': 3,
      'completed_terms': 0,
      'overall_average': 0.0,
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
    });

    print("Academic Performance structure created for academic year: $currentAcademicYear");
    print("Structure references existing collections: Personal_Information, Student_Subjects, TOTAL_MARKS");
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