import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Juniors_Class_Performance extends StatefulWidget {
  final String schoolName;
  final String className;

  const Juniors_Class_Performance({
    required this.schoolName,
    required this.className,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_Class_PerformanceState createState() => _Juniors_Class_PerformanceState();
}

class _Juniors_Class_PerformanceState extends State<Juniors_Class_Performance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> subjects = [];
  List<String> teacherClasses = [];
  String selectedClass = '';
  Map<String, dynamic> subjectPerformance = {};
  Map<String, dynamic> classPerformance = {
    'totalStudents': 0,
    'classPassRate': 0,
    'totalClassPassed': 0,
    'totalClassFailed': 0,
  };
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    selectedClass = widget.className;
    _fetchTeacherClasses();
  }

  Future<void> _fetchTeacherClasses() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
      return;
    }

    userEmail = user.email;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();
      if (!userDoc.exists || userDoc['school'] != widget.schoolName) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'You do not have access to this school.';
        });
        return;
      }

      List<String> classes = List<String>.from(userDoc['classes'] ?? []);
      setState(() {
        teacherClasses = classes;
      });

      await _fetchClassData();
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data: $e';
      });
    }
  }

  Future<void> _onClassSelected(String className) async {
    if (className != selectedClass) {
      setState(() {
        selectedClass = className;
        isLoading = true;
        subjects = [];
        subjectPerformance = {};
        classPerformance = {
          'totalStudents': 0,
          'classPassRate': 0,
          'totalClassPassed': 0,
          'totalClassFailed': 0,
        };
      });
      await _fetchClassData();
    }
  }

  Future<void> _fetchClassData() async {
    try {
      // Fetch data concurrently for better performance
      await Future.wait([
        _fetchClassSummary(),
        _fetchSubjectPerformance(),
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data: $e';
      });
    }
  }

  Future<void> _fetchClassSummary() async {
    try {
      final String classPath = 'Schools/${widget.schoolName}/Classes/$selectedClass/Class_Performance/Class_Summary';

      DocumentSnapshot classSummaryDoc = await _firestore.doc(classPath).get();

      if (classSummaryDoc.exists) {
        final data = classSummaryDoc.data() as Map<String, dynamic>;
        setState(() {
          classPerformance = {
            'totalStudents': data['Total_Students'] ?? 0,
            'classPassRate': data['Class_Pass_Rate'] ?? 0,
            'totalClassPassed': data['Total_Class_Passed'] ?? 0,
            'totalClassFailed': data['Total_Class_Failed'] ?? 0,
          };
        });
      } else {
        // If no performance data exists, show empty state
        setState(() {
          classPerformance = {
            'totalStudents': 0,
            'classPassRate': 0,
            'totalClassPassed': 0,
            'totalClassFailed': 0,
          };
        });
      }
    } catch (e) {
      print("Error fetching class summary: $e");
      throw Exception("Failed to fetch class summary: $e");
    }
  }

  Future<void> _fetchSubjectPerformance() async {
    try {
      final String subjectPerformancePath = 'Schools/${widget.schoolName}/Classes/$selectedClass/Class_Performance/Subject_Performance/Subject_Perfomance';

      QuerySnapshot subjectPerformanceSnapshot = await _firestore.collection(subjectPerformancePath).get();

      Map<String, dynamic> tempSubjectPerformance = {};
      List<String> fetchedSubjects = [];

      for (var doc in subjectPerformanceSnapshot.docs) {
        String subjectName = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        fetchedSubjects.add(subjectName);
        tempSubjectPerformance[subjectName] = {
          'totalStudents': data['Total_Students'] ?? 0,
          'totalPass': data['Total_Pass'] ?? 0,
          'totalFail': data['Total_Fail'] ?? 0,
          'passRate': data['Pass_Rate'] ?? 0,
        };
      }

      setState(() {
        subjects = fetchedSubjects;
        subjectPerformance = tempSubjectPerformance;
      });
    } catch (e) {
      print("Error fetching subject performance: $e");
      throw Exception("Failed to fetch subject performance: $e");
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.blue[600]!, Colors.cyan[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.schoolName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'RESULTS STATISTICS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Class',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teacherClasses.length,
              itemBuilder: (context, index) {
                final className = teacherClasses[index];
                final isSelected = className == selectedClass;

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => _onClassSelected(className),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.indigo[600] : Colors.grey[200],
                        border: Border.all(
                          color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          className,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSummary() {
    // Check if data exists
    final bool hasData = classPerformance['totalStudents'] > 0;

    if (!hasData) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: Colors.orange[600],
            ),
            SizedBox(height: 12),
            Text(
              'No Performance Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Performance data for this class has not been calculated yet.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLASS SUMMARY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Students',
                  classPerformance['totalStudents'].toString(),
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Pass Rate',
                  '${classPerformance['classPassRate']}%',
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Passed',
                  classPerformance['totalClassPassed'].toString(),
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Failed',
                  classPerformance['totalClassFailed'].toString(),
                  Icons.cancel_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color[600], size: 20),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceTable() {
    // Check if subject data exists
    if (subjects.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.subject_outlined,
              size: 40,
              color: Colors.orange[600],
            ),
            SizedBox(height: 12),
            Text(
              'No Subject Performance Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Subject performance data for this class has not been calculated yet.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUBJECT PERFORMANCE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Subject',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Pass',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Fail',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Pass %',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Data Rows
                ...subjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subject = entry.value;
                  final performance = subjectPerformance[subject] ?? {
                    'totalStudents': 0,
                    'passRate': 0,
                    'totalPass': 0,
                    'totalFail': 0,
                  };

                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            subject,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            performance['totalStudents'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              performance['totalPass'].toString(),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              performance['totalFail'].toString(),
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${performance['passRate']}%',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'PERFORMANCE ANALYTICS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _fetchClassData();
            },
            tooltip: 'Refresh Data',
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
              strokeWidth: 4,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Performance Data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red[400],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage ?? 'An unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchClassData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            _buildClassSelector(),
            _buildClassSummary(),
            _buildSubjectPerformanceTable(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}