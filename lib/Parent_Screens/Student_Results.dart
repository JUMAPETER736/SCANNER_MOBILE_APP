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
  String? expandedAcademicYear;

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

      // Optimize: Use fewer years and batch requests
      List<String> years = [];
      DateTime now = DateTime.now();
      int currentYear = now.year;

      if (now.month < 9) {
        currentYear -= 1;
      }

      // Check only current and previous 2 academic years for faster loading
      for (int i = 0; i < 3; i++) {
        int year = currentYear - i;
        String academicYear = "${year}_${year + 1}";
        years.add(academicYear);
      }

      // Optimize: Use batch operations and parallel requests
      Map<String, Map<String, Map<String, dynamic>>> allResults = {};
      List<String> formClasses = ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'];

      // Use Future.wait for parallel processing
      List<Future<Map<String, dynamic>>> yearFutures = years.map((year) async {
        Map<String, Map<String, dynamic>> yearResults = {};

        // Process all form classes in parallel for each year
        List<Future<void>> classFutures = formClasses.map((formClass) async {
          String studentPath = 'Schools/$_schoolName/Classes/$formClass/Student_Details/$_studentName';

          try {
            // Check if student exists in this class
            DocumentSnapshot studentDoc = await _firestore.doc(studentPath).get();

            if (studentDoc.exists) {
              // Fetch all terms for this class and year in parallel
              Map<String, dynamic> classResults = await _fetchTermsForClassOptimized(year, formClass, studentPath);
              if (classResults.isNotEmpty) {
                yearResults[formClass] = classResults;
              }
            }
          } catch (e) {
            print("Error checking student in $formClass for $year: $e");
          }
        }).toList();

        await Future.wait(classFutures);
        return {year: yearResults};
      }).toList();

      // Wait for all years to complete
      List<Map<String, dynamic>> yearResults = await Future.wait(yearFutures);

      // Combine results
      for (var yearResult in yearResults) {
        String year = yearResult.keys.first;
        Map<String, Map<String, dynamic>> data = yearResult[year];
        if (data.isNotEmpty) {
          allResults[year] = data;
        }
      }

      List<String> availableYears = allResults.keys.toList();
      availableYears.sort((a, b) => b.compareTo(a)); // Most recent first

      setState(() {
        availableAcademicYears = availableYears;
        academicYearResults = allResults;
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

  Future<Map<String, dynamic>> _fetchTermsForClassOptimized(String academicYear, String className, String studentPath) async {
    Map<String, dynamic> classResults = {};

    try {
      List<String> terms = ['TERM_ONE', 'TERM_TWO', 'TERM_THREE'];

      // Use Future.wait to fetch all terms in parallel
      List<Future<Map<String, dynamic>>> termFutures = terms.map((term) async {
        // Check if Academic_Performance structure exists for this academic year
        String academicPerformancePath = '$studentPath/Academic_Performance/$academicYear';

        try {
          // First check if the academic performance document exists
          DocumentSnapshot academicPerfDoc = await _firestore.doc(academicPerformancePath).get();

          if (academicPerfDoc.exists) {
            // Check if the term collection exists
            String termPath = '$academicPerformancePath/$term/Term_Info';
            DocumentSnapshot termDoc = await _firestore.doc(termPath).get();

            if (termDoc.exists) {
              // Term exists, fetch the data
              Map<String, dynamic> termData = await _fetchTermDataOptimized(studentPath, academicYear, term);
              if (termData.isNotEmpty) {
                return {term: termData};
              }
            }
          }

          // If Academic_Performance doesn't exist, check the old structure
          String oldTermPath = '$studentPath/Academic_Performance/$academicYear/$term/Term_Info';
          DocumentSnapshot termSummaryDoc = await _firestore
              .doc('$oldTermPath/Term_Summary/Summary')
              .get();

          if (termSummaryDoc.exists) {
            Map<String, dynamic> termData = await _fetchTermDataOptimized(studentPath, academicYear, term);
            if (termData.isNotEmpty) {
              return {term: termData};
            }
          }
        } catch (e) {
          print("Error checking term $term: $e");
        }
        return <String, dynamic>{};
      }).toList();

      List<Map<String, dynamic>> termResults = await Future.wait(termFutures);

      for (var termResult in termResults) {
        if (termResult.isNotEmpty) {
          String term = termResult.keys.first;
          Map<String, dynamic> data = termResult[term];
          if (data.isNotEmpty) {
            classResults[term] = data;
          }
        }
      }
    } catch (e) {
      print("Error fetching terms for class $className: $e");
    }

    return classResults;
  }

  Future<Map<String, dynamic>> _fetchTermDataOptimized(String studentPath, String academicYear, String term) async {
    Map<String, dynamic> termData = {};

    try {
      // Try the new Academic_Performance structure first
      String newTermPath = '$studentPath/Academic_Performance/$academicYear/$term/Term_Info';

      // Use Future.wait to fetch all data in parallel
      List<Future<dynamic>> dataFutures = [
        // Fetch subjects from Student_Subjects collection
        _firestore.collection('$studentPath/Student_Subjects').get(),
        // Try to fetch from new structure first
        _firestore.doc('$newTermPath/Term_Summary/Summary').get(),
        // Fetch total marks
        _firestore.doc('$studentPath/TOTAL_MARKS/Marks').get(),
        // Fetch remarks
        _firestore.doc('$studentPath/TOTAL_MARKS/Results_Remarks').get(),
        // Try to fetch term marks from new structure
        _firestore.doc('$newTermPath/Term_Marks/Marks_Summary').get(),
      ];

      List<dynamic> results = await Future.wait(dataFutures);

      QuerySnapshot subjectsSnapshot = results[0] as QuerySnapshot;
      DocumentSnapshot termSummaryDoc = results[1] as DocumentSnapshot;
      DocumentSnapshot totalMarksDoc = results[2] as DocumentSnapshot;
      DocumentSnapshot remarksDoc = results[3] as DocumentSnapshot;
      DocumentSnapshot termMarksDoc = results[4] as DocumentSnapshot;

      // If new structure doesn't exist, try old structure
      if (!termSummaryDoc.exists) {
        String oldTermPath = '$studentPath/Academic_Performance/$academicYear/$term/Term_Info';
        termSummaryDoc = await _firestore.doc('$oldTermPath/Term_Summary/Summary').get();
      }

      // Process subjects with proper position data
      List<Map<String, dynamic>> subjects = [];
      for (var doc in subjectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle both numeric and string values for scores
        int score = 0;
        String scoreStr = data['Subject_Grade']?.toString() ?? 'N/A';

        if (scoreStr != 'N/A' && scoreStr.isNotEmpty) {
          score = double.tryParse(scoreStr)?.round() ?? 0;
        }

        // Get position data from the document
        int position = 0;
        if (data['Subject_Position'] != null && data['Subject_Position'].toString() != 'N/A') {
          position = int.tryParse(data['Subject_Position'].toString()) ?? 0;
        }

        int totalStudents = 0;
        if (data['Total_Students_Subject'] != null && data['Total_Students_Subject'].toString() != 'N/A') {
          totalStudents = int.tryParse(data['Total_Students_Subject'].toString()) ?? 0;
        }

        String gradeLetter = data['Grade_Letter'] ?? 'N/A';
        if (gradeLetter == 'N/A' && scoreStr != 'N/A') {
          gradeLetter = _getGradeFromPercentage(score.toDouble());
        }

        subjects.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'score': scoreStr == 'N/A' ? 'N/A' : score,
          'position': position == 0 ? 'N/A' : position,
          'totalStudents': totalStudents == 0 ? 'N/A' : totalStudents,
          'gradeLetter': gradeLetter,
        });
      }

      // Process term summary data
      Map<String, dynamic> termSummary = {};
      if (termSummaryDoc.exists) {
        final data = termSummaryDoc.data() as Map<String, dynamic>;
        termSummary = data;
      }

      // Process total marks data
      Map<String, dynamic> totalMarks = {};
      if (totalMarksDoc.exists) {
        final data = totalMarksDoc.data() as Map<String, dynamic>;
        totalMarks = data;
      }

      // Process remarks data
      Map<String, dynamic> remarks = {};
      if (remarksDoc.exists) {
        final data = remarksDoc.data() as Map<String, dynamic>;
        remarks = data;
      }

      // Process term marks data if available
      Map<String, dynamic> termMarks = {};
      if (termMarksDoc.exists) {
        final data = termMarksDoc.data() as Map<String, dynamic>;
        termMarks = data;
      }

      // Combine all marks data
      Map<String, dynamic> combinedMarks = {
        ...totalMarks,
        ...termSummary,
        ...termMarks,
      };

      // Only include terms that have some data (even if N/A)
      if (subjects.isNotEmpty || termSummary.isNotEmpty || totalMarks.isNotEmpty || remarks.isNotEmpty) {
        termData = {
          'subjects': subjects,
          'totalMarks': combinedMarks,
          'remarks': remarks,
        };
      }
    } catch (e) {
      print("Error fetching term data for $term: $e");
      // Return empty map on error
      return {};
    }

    return termData;
  }

  String _formatAcademicYearForDisplay(String year) {
    if (year.contains('_')) {
      List<String> parts = year.split('_');
      if (parts.length == 2) {
        return '${parts[0]} - ${parts[1]}';
      }
    }
    return year;
  }

  String _formatAcademicYear(String year) {
    return _formatAcademicYearForDisplay(year);
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

  Widget _buildStudentInfoHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'ACADEMIC PERFORMANCE',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.person, color: Colors.blueAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName ?? widget.studentName,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Current Class: ${_studentClass ?? 'N/A'}',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.school, color: Colors.blueAccent, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _schoolName ?? 'Unknown School',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
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
                color: Colors.blueAccent,
              ),
            ),
          ),
          ...availableAcademicYears.map((year) {
            bool isExpanded = expandedAcademicYear == year;
            return Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent, width: 1),
                    color: Colors.white,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (expandedAcademicYear == year) {
                          expandedAcademicYear = null;
                          selectedTerm = null;
                        } else {
                          expandedAcademicYear = year;
                          selectedAcademicYear = year;
                          selectedTerm = null;
                        }
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatAcademicYear(year),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isExpanded) _buildTermsRow(year),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTermsRow(String academicYear) {
    if (!academicYearResults.containsKey(academicYear)) {
      return SizedBox.shrink();
    }

    Map<String, Map<String, dynamic>> yearData = academicYearResults[academicYear]!;
    String firstClassName = yearData.keys.first;
    Map<String, dynamic> classData = yearData[firstClassName]!;

    List<String> availableTerms = classData.keys.toList();
    availableTerms.sort();

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: availableTerms.map((term) {
          bool isSelected = selectedTerm == term;
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTerm = isSelected ? null : term;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatTermName(term),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTermDetails() {
    if (selectedAcademicYear == null || selectedTerm == null ||
        !academicYearResults.containsKey(selectedAcademicYear)) {
      return SizedBox.shrink();
    }

    Map<String, Map<String, dynamic>> yearData = academicYearResults[selectedAcademicYear]!;
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
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
          Container(
            color: Colors.white,
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
    );
  }

  // Replace your _buildSubjectsTable method with this:

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
          decoration: BoxDecoration(),
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

          // Handle position and totalStudents as strings
          String position = subject['position'].toString();
          String totalStudents = subject['totalStudents'].toString();

          String positionText = (position != 'N/A' && totalStudents != 'N/A')
              ? '$position/$totalStudents'
              : 'N/A';

          return TableRow(
            children: [
              _tableCell(subject['subject'] ?? 'Unknown'),
              _tableCell(subject['score'].toString()),
              _tableCell(grade),
              _tableCell(positionText),
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
    return Container(
      padding: EdgeInsets.all(8),
      color: isHeader ? Colors.grey[300] : Colors.white,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Academic History'),
        backgroundColor: Colors.blueAccent,
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
              _buildStudentInfoHeader(),
              if (availableAcademicYears.isNotEmpty) ...[
                _buildAcademicYearsList(),
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