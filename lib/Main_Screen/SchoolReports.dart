import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolReports extends StatefulWidget {
  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<List<Map<String, dynamic>>> _fetchSchoolReports() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('SchoolReports')
          .orderBy('studentTotalMarks', descending: true) 
          .get();

      // Map the fetched data into a list of maps
      return querySnapshot.docs.map((doc) {
        return {
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'studentTotalMarks': doc['studentTotalMarks'],
          'teacherTotalMarks': doc['teacherTotalMarks'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching School Reports: $e');
      return [];
    }
  }


  // Save School Reports to Firestore
  Future<void> _saveToSchoolReports(String studentClass, String studentName) async {
    try {
      final studentRef = _firestore
          .collection('Students')
          .doc(studentClass)
          .collection('StudentDetails')
          .doc(studentName);

      final studentSnapshot = await studentRef.get();

      if (studentSnapshot.exists) {
        var data = studentSnapshot.data() as Map<String, dynamic>?;
        var subjects = data?['Subjects'] as List<dynamic>?;

        if (subjects != null) {
          // Calculate total marks for the student
          int studentTotalMarks = subjects.fold<int>(
            0,
                (previousValue, subject) {
              final gradeStr = (subject as Map<String, dynamic>)['grade'] ?? '0';
              final grade = int.tryParse(gradeStr as String) ?? 0;
              return previousValue + grade;
            },
          );

          // Set teacherTotalMarks to a fixed value (e.g., 100)
          const int teacherTotalMarks = 100;

          await _firestore
              .collection('SchoolReports')
              .doc(studentClass)
              .collection('StudentReports')
              .doc(studentName)
              .set({
            'firstName': studentName.split(' ').first,
            'lastName': studentName.split(' ').last,
            'studentTotalMarks': studentTotalMarks, // Calculated based on grades
            'teacherTotalMarks': teacherTotalMarks, // Fixed value for teacher total marks
            'studentId': _auth.currentUser?.uid,
          }, SetOptions(merge: true));
        } else {
          print('Subjects field is null or NOT a list');
        }
      } else {
        print('Student document does NOT exist');
      }
    } catch (e) {
      print('Error saving to School Reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Reports'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSchoolReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          // Data is available and sorted by student marks
          List<Map<String, dynamic>> reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var report = reports[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report['firstName']} ${report['lastName']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'Student Marks: ${report['studentTotalMarks']}',
                          ),
                        ],
                      ),
                      Text(
                        'Teacher Marks: ${report['teacherTotalMarks']}',
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
