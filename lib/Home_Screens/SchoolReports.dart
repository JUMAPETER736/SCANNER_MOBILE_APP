import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Students_Information/StudentSubjectGrade.dart';

class SchoolReports extends StatefulWidget {
  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userClass;

  @override
  void initState() {
    super.initState();
    _getUserClass();
  }

  Future<void> _getUserClass() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('Teacher').doc(user.uid).get();
        if (userDoc.exists) {
          var classes = userDoc['classes'] as List<dynamic>? ?? [];
          if (classes.isNotEmpty) {
            setState(() {
              _userClass = classes[0]; // Assume the first class is selected
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching user class: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSchoolReports() async {
    if (_userClass == null) {
      return [];
    }

    try {
      List<Map<String, dynamic>> allReports = [];

      QuerySnapshot reportQuerySnapshot = await _firestore
          .collection('SchoolReports')
          .doc(_userClass!)
          .collection('StudentReports')
          .get();

      allReports = reportQuerySnapshot.docs.map((doc) {
        return {
          'studentId': doc.id, // Assuming the document ID is the studentId
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'totalMarks': doc['totalMarks'] ?? 0,
          'teacherTotalMarks': doc['teacherTotalMarks'] ?? 0,
        };
      }).toList();

      if (allReports.isEmpty) {
        print('No documents found for Class $_userClass');
      } else {
        print('Documents found: ${allReports.length}');
      }

      // Sort the reports by totalMarks in descending order
      allReports.sort((a, b) => (b['totalMarks'] as int).compareTo(a['totalMarks'] as int));

      return allReports;
    } catch (e) {
      print('Error fetching School Reports: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            _userClass != null ? '$_userClass SCHOOL REPORTS' : 'Loading...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchSchoolReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching DATA',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No School Reports found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              );
            }

            List<Map<String, dynamic>> reports = snapshot.data!;

            return ListView.separated(
              itemCount: reports.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var report = reports[index];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Text(
                      '${index + 1}', // Displaying just the number
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      '${report['lastName'].toUpperCase()} ${report['firstName'].toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total Marks: ${report['totalMarks']} / ${report['teacherTotalMarks']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward,
                      color: Colors.blueAccent,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentSubjectGrade(
                            studentId: report['studentId'], // Pass the studentId
                            firstName: report['firstName'],
                            lastName: report['lastName'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}