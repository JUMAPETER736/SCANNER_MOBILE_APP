

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Student_Results extends StatefulWidget {
  final String studentFullName;

  const Student_Results({
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Student_ResultsState createState() => _Student_ResultsState();
}

class _Student_ResultsState extends State<Student_Results> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data variables
  Map<String, Map<String, Map<String, dynamic>>> academicYearResults = {};
  List<String> availableAcademicYears = [];
  String? selectedAcademicYear;
  String? userSchool;

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
    await _getTeacherSchool();
    if (userSchool != null) {
      await _fetchStudentAcademicYears();
    }
  }

  Future<void> _getTeacherSchool() async {
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

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('Teachers_Details')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'User details not found.';
        });
        return;
      }

      userSchool = userDoc['school'];
      if (userSchool == null) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a school before accessing results.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error fetching user details: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchStudentAcademicYears() async {
    try {
      setState(() => isLoading = true);

      // Get all academic years for this student
      QuerySnapshot academicYearsSnapshot = await _firestore
          .collection('Schools/$userSchool/Academic_Years')
          .get();

      List<String> years = [];
      Map<String, Map<String, Map<String, dynamic>>> allResults = {};

      for (var yearDoc in academicYearsSnapshot.docs) {
        String academicYear = yearDoc.id;
        years.add(academicYear);

        // Get all classes for this academic year
        QuerySnapshot classesSnapshot = await _firestore
            .collection('Schools/$userSchool/Academic_Years/$academicYear/Classes')
            .get();

        Map<String, Map<String, dynamic>> yearResults = {};

        for (var classDoc in classesSnapshot.docs) {
          String className = classDoc.id;

          // Check if student exists in this class
          DocumentSnapshot studentDoc = await _firestore
              .doc('Schools/$userSchool/Academic_Years/$academicYear/Classes/$className/Student_Details/${widget.studentFullName}')
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

      // Sort years in descending order (most recent first)
      years.sort((a, b) => b.compareTo(a));

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
        String basePath = 'Schools/$userSchool/Academic_Years/$academicYear/Classes/$className/Student_Details/${widget.studentFullName}/Terms/$term';

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
      case 'TERM_ONE': return 'TERM 1';
      case 'TERM_TWO': return 'TERM 2';
      case 'TERM_THREE': return 'TERM 3';
      default: return term;
    }
  }

  Widget _buildAcademicYearSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Academic Year:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAcademicYear,
                isExpanded: true,
                hint: Text('Select Academic Year'),
                padding: EdgeInsets.symmetric(horizontal: 12),
                items: availableAcademicYears.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedAcademicYear = newValue;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    if (selectedAcademicYear == null ||
        !academicYearResults.containsKey(selectedAcademicYear)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No results found for ${selectedAcademicYear ?? 'selected year'}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    Map<String, Map<String, dynamic>> yearData = academicYearResults[selectedAcademicYear]!;

    return Column(
      children: yearData.entries.map((classEntry) {
        String className = classEntry.key;
        Map<String, dynamic> classData = classEntry.value;

        return _buildClassCard(className, classData);
      }).toList(),
    );
  }

  Widget _buildClassCard(String className, Map<String, dynamic> classData) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              'CLASS: $className',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...classData.entries.map((termEntry) {
            String termKey = termEntry.key;
            Map<String, dynamic> termData = termEntry.value;
            return _buildTermSection(termKey, termData);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTermSection(String termKey, Map<String, dynamic> termData) {
    List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(termData['subjects'] ?? []);
    Map<String, dynamic> totalMarks = termData['totalMarks'] ?? {};
    Map<String, dynamic> remarks = termData['remarks'] ?? {};

    return ExpansionTile(
      title: Text(
        _formatTermName(termKey),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        'Total: ${totalMarks['Student_Total_Marks'] ?? 0} | Position: ${totalMarks['Student_Class_Position'] ?? 'N/A'}',
        style: TextStyle(color: Colors.grey[600]),
      ),
      children: [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentFullName} - Academic History'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
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
          ? Center(
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
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (availableAcademicYears.isNotEmpty) ...[
                _buildAcademicYearSelector(),
                _buildResultsContent(),
              ] else ...[
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No academic records found for ${widget.studentFullName}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
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