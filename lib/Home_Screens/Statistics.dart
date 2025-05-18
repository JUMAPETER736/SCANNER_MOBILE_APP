import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String schoolName = '';
  String className = '';
  Map<String, Map<String, dynamic>> subjectStats = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User is not logged in.");
      }

      final teacherDoc = await _firestore.collection('Teachers_Details').doc(
          currentUser.email).get();

      if (!teacherDoc.exists) {
        throw Exception("Teacher details not found.");
      }

      schoolName = (teacherDoc['school'] ?? '').toString().trim();
      className = (teacherDoc['classes'] ?? '').toString().trim();

      if (schoolName.isEmpty || className.isEmpty) {
        throw Exception("School or class is missing in your profile.");
      }

      // Get all students in the class
      final studentsSnapshot = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .get();

      // Initialize subject statistics map
      subjectStats.clear();

      // Loop through each student
      for (var studentDoc in studentsSnapshot.docs) {
        String studentFullName = studentDoc.id;

        // Get all subjects for this student
        final subjectSnapshot = await studentDoc.reference.collection(
            'Student_Subjects').get();

        // Process each subject for this student
        for (var subjectDoc in subjectSnapshot.docs) {
          String subject = subjectDoc.id;
          String? gradeStr = subjectDoc.data()['Subject_Grade'] as String?;

          // Initialize subject entry if it doesn't exist
          if (!subjectStats.containsKey(subject)) {
            subjectStats[subject] = {
              'PASS': 0,
              'FAIL': 0,
              'total': 0,
              'students': {
                'PASS': [],
                'FAIL': []
              }
            };
          }

          // Increment total students for this subject
          subjectStats[subject]!['total'] = subjectStats[subject]!['total'] + 1;

          // Process grade if available
          if (gradeStr != null && gradeStr.isNotEmpty) {
            int? grade = int.tryParse(gradeStr.trim());
            if (grade != null) {
              if (grade >= 50) {
                // Pass
                subjectStats[subject]!['PASS'] =
                    subjectStats[subject]!['PASS'] + 1;
                (subjectStats[subject]!['students']['PASS'] as List).add(
                    studentFullName);
              } else {
                // Fail
                subjectStats[subject]!['FAIL'] =
                    subjectStats[subject]!['FAIL'] + 1;
                (subjectStats[subject]!['students']['FAIL'] as List).add(
                    studentFullName);
              }
            }
          }
        }
      }

      setState(() {
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading statistics: $e';
        isLoading = false;
      });
    }
  }

  Widget buildSubjectCard(String subject, Map<String, dynamic> stats) {
    final int passCount = stats['PASS'] as int;
    final int failCount = stats['FAIL'] as int;
    final int totalCount = stats['total'] as int;

    // Calculate percentages
    final double passPercentage = totalCount > 0 ? (passCount / totalCount) *
        100 : 0;
    final double failPercentage = totalCount > 0 ? (failCount / totalCount) *
        100 : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      )),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Total: $totalCount",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("PASS",
                            style: TextStyle(
                                color: Colors.green, fontWeight: FontWeight
                                .bold)),
                        Text("$passCount (${passPercentage.toStringAsFixed(
                            1)}%)",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("FAIL",
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight
                                .bold)),
                        Text("$failCount (${failPercentage.toStringAsFixed(
                            1)}%)",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text("View Students",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              children: [
                if ((stats['students']['PASS'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 8),
                        child: Text("Passing Students:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green
                            )
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (stats['students']['PASS'] as List).length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Text(
                                (stats['students']['PASS'] as List)[index]),
                          );
                        },
                      ),
                    ],
                  ),

                if ((stats['students']['FAIL'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 8),
                        child: Text("Failing Students:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red
                            )
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (stats['students']['FAIL'] as List).length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Text(
                                (stats['students']['FAIL'] as List)[index]),
                          );
                        },
                      ),
                    ],
                  ),
              ],
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
        title: Text('Statistics'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : subjectStats.isEmpty
          ? const Center(child: Text("No subject data available"))
          : RefreshIndicator(
        onRefresh: loadStatistics,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Class Statistics Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ...subjectStats.entries.map((entry) {
              final subject = entry.key;
              final stats = entry.value;
              return buildSubjectCard(subject, stats);
            }).toList(),
          ],
        ),
      ),
    );
  }
}