import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Log_In_And_Register_Screens/Login_Page.dart'; // Import for ParentDataManager

class Student_Results extends StatefulWidget {
  static const String id = 'student_school_results';

  final String schoolName;
  final String className;
  final String studentClass;
  final String studentName;

  const Student_Results({
    Key? key,
    required this.schoolName,
    required this.className,
    required this.studentClass,
    required this.studentName,
  }) : super(key: key);

  @override
  _Student_ResultsState createState() => _Student_ResultsState();
}

class _Student_ResultsState extends State<Student_Results> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data variables
  Map<String, Map<String, Map<String, dynamic>>> academicYearResults = {};
  List<String> availableAcademicYears = [];
  String? selectedAcademicYear;
  String? selectedTerm;

  // Parent data from ParentDataManager
  String? _schoolName;
  String? _studentName;
  String? _studentClass;

  // State variables
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadParentData();
    if (_schoolName != null) {
      await _fetchStudentAcademicYears();
    }
  }

  Future<void> _loadParentData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      // Load data from ParentDataManager
      await ParentDataManager().loadFromPreferences();

      setState(() {
        _schoolName = ParentDataManager().schoolName;
        _studentName = ParentDataManager().studentName;
        _studentClass = ParentDataManager().studentClass;
      });

      print('🎓 Parent Data Loaded for Results:');
      print('School: $_schoolName');
      print('Student: $_studentName');
      print('Class: $_studentClass');

      if (_schoolName == null || _schoolName!.isEmpty) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'No school data found. Please login again.';
        });
        return;
      }

    } catch (e) {
      print('❌ Error loading parent data: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error loading parent data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchStudentAcademicYears() async {
    try {
      setState(() => isLoading = true);

      // Get all academic years for this student using school from ParentDataManager
      QuerySnapshot academicYearsSnapshot = await _firestore
          .collection('Schools/$_schoolName/Academic_Years')
          .get();

      List<String> years = [];
      Map<String, Map<String, Map<String, dynamic>>> allResults = {};

      for (var yearDoc in academicYearsSnapshot.docs) {
        String academicYear = yearDoc.id;
        years.add(academicYear);

        // Get all classes for this academic year
        QuerySnapshot classesSnapshot = await _firestore
            .collection('Schools/$_schoolName/Academic_Years/$academicYear/Classes')
            .get();

        Map<String, Map<String, dynamic>> yearResults = {};

        for (var classDoc in classesSnapshot.docs) {
          String className = classDoc.id;

          // Check if student exists in this class
          DocumentSnapshot studentDoc = await _firestore
              .doc('Schools/$_schoolName/Academic_Years/$academicYear/Classes/$className/Student_Details/${_studentName}')
              .get();

          if (studentDoc.exists) {
            // Fetch all terms for this class
            Map<String, dynamic> classResults = await _fetchTermsForClass(academicYear, className);
            if (classResults.isNotEmpty) {
              yearResults[className] = classResults;
            }
          }
        }

        if (yearResults.isNotEmpty) {
          allResults[academicYear] = yearResults;
        }
      }

      // Sort years in descending order (most recent first) and limit to 4
      years.sort((a, b) => b.compareTo(a));
      if (years.length > 4) {
        years = years.take(4).toList();
      }

      setState(() {
        availableAcademicYears = years;
        academicYearResults = allResults;
        if (years.isNotEmpty) {
          selectedAcademicYear = years.first;
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching academic years: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error fetching student results: ${e.toString()}';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchTermsForClass(String academicYear, String className) async {
    Map<String, dynamic> classResults = {};

    try {
      List<String> terms = ['TERM_ONE', 'TERM_TWO', 'TERM_THREE'];

      for (String term in terms) {
        String basePath = 'Schools/$_schoolName/Academic_Years/$academicYear/Classes/$className/Student_Details/${_studentName}/Terms/$term';

        // Check if term data exists
        DocumentSnapshot termCheck = await _firestore
            .doc('$basePath/TOTAL_MARKS/Marks')
            .get();

        if (termCheck.exists) {
          Map<String, dynamic> termData = await _fetchTermData(basePath);
          if (termData.isNotEmpty) {
            classResults[term] = termData;
          }
        }
      }
    } catch (e) {
      print("Error fetching terms for class $className: $e");
    }

    return classResults;
  }

  Future<Map<String, dynamic>> _fetchTermData(String basePath) async {
    Map<String, dynamic> termData = {};

    try {
      // Fetch subjects
      QuerySnapshot subjectsSnapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get();

      List<Map<String, dynamic>> subjects = [];
      for (var doc in subjectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        int score = 0;
        if (data['Subject_Grade'] != null) {
          score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
        }

        subjects.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': score,
          'position': (data['Subject_Position'] as num?)?.toInt() ?? 0,
          'totalStudents': (data['Total_Students_Subject'] as num?)?.toInt() ?? 0,
          'gradeLetter': data['Grade_Letter']?.toString() ?? _getGradeFromPercentage(score.toDouble()),
        });
      }

      // Fetch total marks
      DocumentSnapshot totalMarksDoc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Marks')
          .get();

      Map<String, dynamic> totalMarks = {};
      if (totalMarksDoc.exists) {
        totalMarks = totalMarksDoc.data() as Map<String, dynamic>;
      }

      // Fetch remarks
      DocumentSnapshot remarksDoc = await _firestore
          .doc('$basePath/TOTAL_MARKS/Results_Remarks')
          .get();

      Map<String, dynamic> remarks = {};
      if (remarksDoc.exists) {
        remarks = remarksDoc.data() as Map<String, dynamic>;
      }

      termData = {
        'subjects': subjects,
        'totalMarks': totalMarks,
        'remarks': remarks,
      };
    } catch (e) {
      print("Error fetching term data: $e");
    }

    return termData;
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 85) return 'A';
    if (percentage >= 75) return 'B';
    if (percentage >= 65) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  String _getRemarkFromGrade(String grade) {
    switch (grade) {
      case 'A': return 'EXCELLENT';
      case 'B': return 'VERY GOOD';
      case 'C': return 'GOOD';
      case 'D': return 'PASS';
      default: return 'FAIL';
    }
  }

  String _formatTermName(String term) {
    switch (term) {
      case 'TERM_ONE': return 'TERM ONE';
      case 'TERM_TWO': return 'TERM TWO';
      case 'TERM_THREE': return 'TERM THREE';
      default: return term;
    }
  }

  String _formatAcademicYear(String year) {
    // Convert format like "2024" to "2024 - 2025"
    try {
      int startYear = int.parse(year);
      int endYear = startYear + 1;
      return '$startYear - $endYear';
    } catch (e) {
      return year; // Return original if parsing fails
    }
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Academic Performance Header
              Center(
                child: Text(
                  'ACADEMIC PERFORMANCE',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName ?? widget.studentName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Current Class: ${_studentClass ?? 'N/A'}',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _schoolName ?? 'Unknown School',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicYearsList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Academic Years:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          ...availableAcademicYears.map((year) {
            bool isSelected = selectedAcademicYear == year;
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: isSelected ? 4 : 2,
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      selectedAcademicYear = year;
                      selectedTerm = null; // Reset term selection
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatAcademicYear(year),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.blue.shade600,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTermsList() {
    if (selectedAcademicYear == null ||
        !academicYearResults.containsKey(selectedAcademicYear)) {
      return SizedBox.shrink();
    }

    Map<String, Map<String, dynamic>> yearData = academicYearResults[selectedAcademicYear]!;

    // Get the first class data (assuming one class per year for now)
    String firstClassName = yearData.keys.first;
    Map<String, dynamic> classData = yearData[firstClassName]!;

    List<String> availableTerms = classData.keys.toList();
    availableTerms.sort(); // Sort terms in order

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12, top: 16),
            child: Text(
              'Terms for ${_formatAcademicYear(selectedAcademicYear!)}:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          ...availableTerms.map((term) {
            bool isSelected = selectedTerm == term;
            return Container(
              margin: EdgeInsets.only(bottom: 6),
              child: Card(
                elevation: isSelected ? 3 : 1,
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? Colors.blue.shade400 : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      selectedTerm = term;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.book,
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatTermName(term),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTermDetails() {
    if (selectedAcademicYear == null || selectedTerm == null ||
        !academicYearResults.containsKey(selectedAcademicYear)) {
      return SizedBox.shrink();
    }

    Map<String, Map<String, dynamic>> yearData = academicYearResults[selectedAcademicYear]!;

    // Get the first class data (assuming one class per year for now)
    String firstClassName = yearData.keys.first;
    Map<String, dynamic> classData = yearData[firstClassName]!;

    if (!classData.containsKey(selectedTerm)) {
      return SizedBox.shrink();
    }

    Map<String, dynamic> termData = classData[selectedTerm]!;
    List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(termData['subjects'] ?? []);
    Map<String, dynamic> totalMarks = termData['totalMarks'] ?? {};
    Map<String, dynamic> remarks = termData['remarks'] ?? {};

    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_formatTermName(selectedTerm!)} RESULTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatAcademicYear(selectedAcademicYear!),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSubjectsTable(subjects),
                  SizedBox(height: 16),
                  _buildSummaryInfo(totalMarks),
                  SizedBox(height: 16),
                  _buildRemarksSection(remarks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsTable(List<Map<String, dynamic>> subjects) {
    if (subjects.isEmpty) {
      return Text('No subjects data available');
    }

    return Table(
      border: TableBorder.all(),
      columnWidths: {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            _tableCell('SUBJECT', isHeader: true),
            _tableCell('MARKS %', isHeader: true),
            _tableCell('GRADE', isHeader: true),
            _tableCell('POSITION', isHeader: true),
            _tableCell('COMMENT', isHeader: true),
          ],
        ),
        ...subjects.map((subject) {
          String grade = subject['gradeLetter'] ?? 'F';
          String comment = _getRemarkFromGrade(grade);

          return TableRow(
            children: [
              _tableCell(subject['subject'] ?? 'Unknown'),
              _tableCell(subject['score']?.toString() ?? '0'),
              _tableCell(grade),
              _tableCell('${subject['position'] ?? 0}/${subject['totalStudents'] ?? 0}'),
              _tableCell(comment),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryInfo(Map<String, dynamic> totalMarks) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Marks: ${totalMarks['Student_Total_Marks'] ?? 0}'),
              Text('Position: ${totalMarks['Student_Class_Position'] ?? 'N/A'}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Average Grade: ${totalMarks['Average_Grade_Letter'] ?? 'N/A'}'),
              Text('Out of: ${totalMarks['Total_Class_Students_Number'] ?? 'N/A'}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Average %: ${totalMarks['Average_Percentage']?.toStringAsFixed(1) ?? 'N/A'}'),
              Text(
                'Status: ${totalMarks['JCE_Status'] ?? 'N/A'}',
                style: TextStyle(
                  color: (totalMarks['JCE_Status'] == 'PASS') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection(Map<String, dynamic> remarks) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REMARKS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Form Teacher: ${remarks['Form_Teacher_Remark'] ?? 'N/A'}',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Head Teacher: ${remarks['Head_Teacher_Remark'] ?? 'N/A'}',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error Loading Results',
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
          if (errorMessage?.contains('login') == true) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_studentName ?? widget.studentName} - Academic History'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _initializeData();
            },
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
            Text('Loading academic history...'),
          ],
        ),
      )
          : hasError
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStudentInfoCard(),
              if (availableAcademicYears.isNotEmpty) ...[
                _buildAcademicYearsList(),
                if (selectedAcademicYear != null) _buildTermsList(),
                if (selectedTerm != null) _buildTermDetails(),
              ] else ...[
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No academic records found for ${_studentName ?? widget.studentName}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'School: ${_schoolName ?? 'Unknown'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}