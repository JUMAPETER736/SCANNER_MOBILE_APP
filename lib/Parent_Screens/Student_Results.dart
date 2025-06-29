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

  // Term date mappings
  Map<String, Map<String, String>> termDates = {
    'TERM_ONE': {
      'start_date': '01-09-2024',
      'end_date': '31-12-2024',
    },
    'TERM_TWO': {
      'start_date': '01-01-2025',
      'end_date': '20-03-2025',
    },
    'TERM_THREE': {
      'start_date': '01-04-2025',
      'end_date': '30-08-2025',
    },
  };

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

      // Always create entries for all terms, even if no data exists
      for (String term in terms) {
        try {
          Map<String, dynamic> termData = await _fetchTermDataOptimized(studentPath, academicYear, term);

          // If no data exists, create default structure with N/A values
          if (termData.isEmpty) {
            termData = _createDefaultTermData();
          }

          // Add term dates to the data
          termData['term_dates'] = termDates[term] ?? {
            'start_date': 'N/A',
            'end_date': 'N/A',
          };

          classResults[term] = termData;
        } catch (e) {
          print("Error fetching term $term: $e");
          // Create default data even on error
          classResults[term] = {
            ..._createDefaultTermData(),
            'term_dates': termDates[term] ?? {
              'start_date': 'N/A',
              'end_date': 'N/A',
            },
          };
        }
      }
    } catch (e) {
      print("Error fetching terms for class $className: $e");
    }

    return classResults;
  }

  Map<String, dynamic> _createDefaultTermData() {
    return {
      'subjects': <Map<String, dynamic>>[],
      'totalMarks': {
        'Student_Total_Marks': 'N/A',
        'Student_Class_Position': 'N/A',
        'Average_Grade_Letter': 'N/A',
        'Total_Class_Students_Number': 'N/A',
        'Average_Percentage': 'N/A',
        'JCE_Status': 'N/A',
      },
      'remarks': {
        'Form_Teacher_Remark': 'N/A',
        'Head_Teacher_Remark': 'N/A',
      },
    };
  }

  Future<Map<String, dynamic>> _fetchTermDataOptimized(String studentPath, String academicYear, String term) async {
    Map<String, dynamic> termData = {};

    try {
      String termPath = '$studentPath/Academic_Performance/$academicYear/$term/Term_Info';

      // Use Future.wait to fetch all data in parallel
      List<Future<dynamic>> dataFutures = [
        // Fetch subjects
        _firestore.collection('$studentPath/Student_Subjects').get(),
        // Fetch term summary
        _firestore.doc('$termPath/Term_Summary/Summary').get(),
        // Fetch total marks
        _firestore.doc('$studentPath/TOTAL_MARKS/Marks').get(),
        // Fetch remarks
        _firestore.doc('$studentPath/TOTAL_MARKS/Results_Remarks').get(),
      ];

      List<dynamic> results = await Future.wait(dataFutures);

      QuerySnapshot subjectsSnapshot = results[0] as QuerySnapshot;
      DocumentSnapshot termSummaryDoc = results[1] as DocumentSnapshot;
      DocumentSnapshot totalMarksDoc = results[2] as DocumentSnapshot;
      DocumentSnapshot remarksDoc = results[3] as DocumentSnapshot;

      // Process subjects with proper position data and N/A defaults
      List<Map<String, dynamic>> subjects = [];
      if (subjectsSnapshot.docs.isNotEmpty) {
        for (var doc in subjectsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Handle score with N/A default
          String scoreStr = 'N/A';
          int score = 0;
          if (data['Subject_Grade'] != null && data['Subject_Grade'] != 'N/A' && data['Subject_Grade'] != '') {
            score = double.tryParse(data['Subject_Grade'].toString())?.round() ?? 0;
            scoreStr = score.toString();
          }

          // Get position data from the document with N/A defaults
          String position = data['Subject_Position']?.toString() ?? 'N/A';
          String totalStudents = data['Total_Students_Subject']?.toString() ?? 'N/A';
          String gradeLetter = data['Grade_Letter'] ?? (score > 0 ? _getGradeFromPercentage(score.toDouble()) : 'N/A');

          subjects.add({
            'subject': data['Subject_Name'] ?? doc.id,
            'score': scoreStr,
            'position': position,
            'totalStudents': totalStudents,
            'gradeLetter': gradeLetter,
          });
        }
      }

      // Process other data with N/A defaults
      Map<String, dynamic> termSummary = {};
      if (termSummaryDoc.exists) {
        termSummary = termSummaryDoc.data() as Map<String, dynamic>;
      }

      Map<String, dynamic> totalMarks = {};
      if (totalMarksDoc.exists) {
        totalMarks = totalMarksDoc.data() as Map<String, dynamic>;
      }

      Map<String, dynamic> remarks = {};
      if (remarksDoc.exists) {
        remarks = remarksDoc.data() as Map<String, dynamic>;
      }

      // Combine marks with N/A defaults
      Map<String, dynamic> combinedMarks = {
        'Student_Total_Marks': totalMarks['Student_Total_Marks'] ?? termSummary['Student_Total_Marks'] ?? 'N/A',
        'Student_Class_Position': totalMarks['Student_Class_Position'] ?? termSummary['Student_Class_Position'] ?? 'N/A',
        'Average_Grade_Letter': totalMarks['Average_Grade_Letter'] ?? termSummary['Average_Grade_Letter'] ?? 'N/A',
        'Total_Class_Students_Number': totalMarks['Total_Class_Students_Number'] ?? termSummary['Total_Class_Students_Number'] ?? 'N/A',
        'Average_Percentage': totalMarks['Average_Percentage'] ?? termSummary['Average_Percentage'] ?? 'N/A',
        'JCE_Status': totalMarks['JCE_Status'] ?? termSummary['JCE_Status'] ?? 'N/A',
      };

      // Remarks with N/A defaults
      Map<String, dynamic> processedRemarks = {
        'Form_Teacher_Remark': remarks['Form_Teacher_Remark'] ?? 'N/A',
        'Head_Teacher_Remark': remarks['Head_Teacher_Remark'] ?? 'N/A',
      };

      termData = {
        'subjects': subjects,
        'totalMarks': combinedMarks,
        'remarks': processedRemarks,
      };
    } catch (e) {
      print("Error fetching term data for $term: $e");
      // Return empty map, will be handled by calling function
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
      case 'N/A': return 'N/A';
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
                fontWeight: FontWeight.bold,
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

    // Always show all three terms
    List<String> allTerms = ['TERM_ONE', 'TERM_TWO', 'TERM_THREE'];

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: allTerms.map((term) {
          bool isSelected = selectedTerm == term;
          bool hasData = classData.containsKey(term) &&
              classData[term]['subjects'] != null &&
              (classData[term]['subjects'] as List).isNotEmpty;

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
                      color: hasData ? Colors.blueAccent : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTermName(term),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : (hasData ? Colors.blueAccent : Colors.grey[600]),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!hasData) ...[
                        SizedBox(height: 2),
                        Text(
                          'No Data',
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected ? Colors.white70 : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
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
    Map<String, dynamic> termDatesInfo = termData['term_dates'] ?? {};

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
                if (termDatesInfo.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    '${termDatesInfo['start_date']} to ${termDatesInfo['end_date']}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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

  Widget _buildSubjectsTable(List<Map<String, dynamic>> subjects) {
    // If no subjects data, show default N/A table
    if (subjects.isEmpty) {
      subjects = [
        {
          'subject': 'No subjects available',
          'score': 'N/A',
          'position': 'N/A',
          'totalStudents': 'N/A',
          'gradeLetter': 'N/A',
        }
      ];
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
          String grade = subject['gradeLetter'] ?? 'N/A';
          String comment = _getRemarkFromGrade(grade);
          String position = subject['position']?.toString() ?? 'N/A';
          String totalStudents = subject['totalStudents']?.toString() ?? 'N/A';
          String positionText = (position != 'N/A' && totalStudents != 'N/A') ? '$position/$totalStudents' : 'N/A';

          return TableRow(
            children: [
              _tableCell(subject['subject'] ?? 'Unknown'),
              _tableCell(subject['score']?.toString() ?? 'N/A'),
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
              Text('Total Marks: ${totalMarks['Student_Total_Marks'] ?? 'N/A'}'),
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
              Text('Average %: ${_formatAverage(totalMarks['Average_Percentage'])}'),
              Text(
                'Status: ${totalMarks['JCE_Status'] ?? 'N/A'}',
                style: TextStyle(
                  color: (totalMarks['JCE_Status'] == 'PASS') ? Colors.green :
                  (totalMarks['JCE_Status'] == 'N/A') ? Colors.grey : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAverage(dynamic average) {
    if (average == null || average == 'N/A') return 'N/A';
    if (average is num) {
      return average.toStringAsFixed(1);
    }
    return average.toString();
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
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
          color: isHeader ? Colors.blueAccent : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  hasError = false;
                  errorMessage = null;
                });
                _initializeData();
              },
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          SizedBox(height: 16),
          Text(
            'Loading student results...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              color: Colors.grey[600],
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No Academic Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No academic performance data is available for this student.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _initializeData();
              },
              child: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasError)
                  _buildErrorState()
                else if (isLoading)
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildLoadingState(),
                  )
                else if (availableAcademicYears.isEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildNoResultsState(),
                    )
                  else ...[
                      _buildStudentInfoHeader(),
                      _buildAcademicYearsList(),
                      if (selectedTerm != null) _buildTermDetails(),
                    ],
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}