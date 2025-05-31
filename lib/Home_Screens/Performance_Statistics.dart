import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../School_Report/Juniors_Class_Performance.dart';
import '../School_Report/Seniors_Class_Performance.dart';

class Performance_Statistics extends StatefulWidget {
  const Performance_Statistics({Key? key}) : super(key: key);

  @override
  _Performance_StatisticsState createState() => _Performance_StatisticsState();
}

class _Performance_StatisticsState extends State<Performance_Statistics> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  String? schoolName;
  List<String> teacherClasses = [];
  String? selectedClass;
  bool isLoading = true;
  bool isLoadingStats = false;
  Map<String, dynamic>? classStats;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  // Load teacher data and initialize the first class
  Future<void> _loadTeacherData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in.");

      final teacherDoc = await _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email)
          .get();

      if (!teacherDoc.exists) throw Exception("Teacher record not found.");

      final school = (teacherDoc['school'] ?? '').toString().trim();
      final classes = teacherDoc['classes'] as List?;

      if (school.isEmpty || classes == null || classes.isEmpty) {
        throw Exception("Missing school or class information.");
      }

      setState(() {
        schoolName = school;
        teacherClasses = classes.map((c) => c.toString().trim()).toList();
        selectedClass = teacherClasses.first;
        isLoading = false;
      });

      // Load statistics for the first class
      if (selectedClass != null) {
        await _loadClassStatistics(selectedClass!);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  // Load statistics for the selected class
  Future<void> _loadClassStatistics(String className) async {
    setState(() {
      isLoadingStats = true;
      classStats = null;
    });

    try {
      final formLevel = _extractFormLevel(className);
      final collectionName = _getCollectionName(formLevel);

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('school', isEqualTo: schoolName)
          .where('class', isEqualTo: className)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          classStats = null;
          isLoadingStats = false;
        });
        return;
      }

      final stats = _calculateStatistics(querySnapshot.docs);

      setState(() {
        classStats = stats;
        isLoadingStats = false;
      });

    } catch (e) {
      setState(() {
        classStats = null;
        isLoadingStats = false;
      });
      _showErrorSnackBar('Error loading statistics: ${e.toString()}');
    }
  }

  // Calculate statistics from exam results
  Map<String, dynamic> _calculateStatistics(List<QueryDocumentSnapshot> docs) {
    Map<String, List<double>> subjectMarks = {};
    int totalStudents = docs.length;

    // Collect marks by subject
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final subjects = data['subjects'] as Map<String, dynamic>? ?? {};

      subjects.forEach((subject, mark) {
        if (mark is num) {
          subjectMarks.putIfAbsent(subject, () => []).add(mark.toDouble());
        }
      });
    }

    // Calculate subject averages
    Map<String, double> subjectAverages = {};
    double totalMarks = 0;
    int subjectCount = 0;

    subjectMarks.forEach((subject, marks) {
      double average = marks.reduce((a, b) => a + b) / marks.length;
      subjectAverages[subject] = average;
      totalMarks += average;
      subjectCount++;
    });

    double overallAverage = subjectCount > 0 ? totalMarks / subjectCount : 0;

    return {
      'totalStudents': totalStudents,
      'overallAverage': overallAverage,
      'subjectAverages': subjectAverages,
      'highestSubject': subjectAverages.isNotEmpty
          ? subjectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
      'lowestSubject': subjectAverages.isNotEmpty
          ? subjectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key
          : 'N/A',
    };
  }

  // Extract form level from class name
  String _extractFormLevel(String className) {
    final upper = className.toUpperCase();
    if (upper.contains('FORM 1') || upper.contains('FORM1') || upper.startsWith('1')) return 'FORM 1';
    if (upper.contains('FORM 2') || upper.contains('FORM2') || upper.startsWith('2')) return 'FORM 2';
    if (upper.contains('FORM 3') || upper.contains('FORM3') || upper.startsWith('3')) return 'FORM 3';
    if (upper.contains('FORM 4') || upper.contains('FORM4') || upper.startsWith('4')) return 'FORM 4';
    return 'UNKNOWN';
  }

  // Get collection name based on form level
  String _getCollectionName(String formLevel) {
    return (formLevel == 'FORM 1' || formLevel == 'FORM 2')
        ? 'Juniors_Exam_Results'
        : 'Seniors_Exam_Results';
  }

  // Get color based on form level
  Color _getFormLevelColor(String formLevel) {
    switch (formLevel) {
      case 'FORM 1': return Colors.green;
      case 'FORM 2': return Colors.blue;
      case 'FORM 3': return Colors.orange;
      case 'FORM 4': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle class selection
  void _onClassSelected(String className) {
    setState(() {
      selectedClass = className;
    });
    _loadClassStatistics(className);
  }

  // Navigate to detailed report
  void _navigateToDetailedReport() {
    if (schoolName == null || selectedClass == null) return;

    final formLevel = _extractFormLevel(selectedClass!);
    Widget destinationPage;

    if (formLevel == 'FORM 1' || formLevel == 'FORM 2') {
      destinationPage = Juniors_Class_Performance(
        schoolName: schoolName!,
        className: selectedClass!,
      );
    } else if (formLevel == 'FORM 3' || formLevel == 'FORM 4') {
      destinationPage = Seniors_Class_Performance(
        schoolName: schoolName!,
        className: selectedClass!,
      );
    } else {
      _showErrorSnackBar('Unrecognized class level: $selectedClass');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildGradientDecoration(),
        child: _buildBody(),
      ),
    );
  }

  // Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        isLoading ? 'Performance Statistics' : schoolName ?? 'Performance Statistics',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
    );
  }

  // Build gradient decoration
  BoxDecoration _buildGradientDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blueAccent, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Build main body
  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (schoolName == null || teacherClasses.isEmpty) {
      return _buildNoClassesScreen();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildClassSelector(),
          const SizedBox(height: 20),
          Expanded(
            child: selectedClass != null
                ? _buildPerformanceContent()
                : _buildSelectClassPrompt(),
          ),
        ],
      ),
    );
  }

  // Build loading screen
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading teacher data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build no classes screen
  Widget _buildNoClassesScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'No classes assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact your administrator to assign classes.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build class selector
  Widget _buildClassSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: teacherClasses.map((classItem) {
          final isSelected = classItem == selectedClass;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ElevatedButton(
              onPressed: () => _onClassSelected(classItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                classItem,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build select class prompt
  Widget _buildSelectClassPrompt() {
    return const Center(
      child: Text(
        'Please select a class',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  // Build performance content
  Widget _buildPerformanceContent() {
    if (isLoadingStats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Loading statistics...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildClassHeader(),
          const SizedBox(height: 16),
          if (classStats == null)
            _buildNoDataCard()
          else ...[
            _buildStatisticsCards(),
            const SizedBox(height: 16),
            _buildSubjectPerformanceCard(),
            const SizedBox(height: 16),
            _buildDetailedReportButton(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Build class header
  Widget _buildClassHeader() {
    final formLevel = _extractFormLevel(selectedClass!);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 32,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedClass!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFormLevelColor(formLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getFormLevelColor(formLevel),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      formLevel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getFormLevelColor(formLevel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build no data card
  Widget _buildNoDataCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No exam results found for this class',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build statistics cards
  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Students',
                '${classStats!['totalStudents']}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Class Average',
                '${classStats!['overallAverage'].toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Best Subject',
                '${classStats!['highestSubject']}',
                Icons.star,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Needs Focus',
                '${classStats!['lowestSubject']}',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build individual stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build subject performance card
  Widget _buildSubjectPerformanceCard() {
    final subjectAverages = classStats!['subjectAverages'] as Map<String, double>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.subject, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Subject Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...subjectAverages.entries
                .map((entry) => _buildSubjectBar(entry.key, entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }

  // Build subject performance bar
  Widget _buildSubjectBar(String subject, double average) {
    final percentage = (average / 100).clamp(0.0, 1.0);
    final barColor = average >= 70 ? Colors.green :
    average >= 50 ? Colors.orange : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${average.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build detailed report button
  Widget _buildDetailedReportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToDetailedReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 20),
            SizedBox(width: 8),
            Text(
              'View Detailed Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}