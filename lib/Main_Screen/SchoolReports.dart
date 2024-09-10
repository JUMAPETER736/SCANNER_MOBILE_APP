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
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
        };
      }).toList();

      if (allReports.isEmpty) {
        print('No documents found for class $_userClass');
      } else {
        print('Documents found: ${allReports.length}');
      }

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
            return Center(child: Text('No Student DATA found'));
          }

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
                        ],
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
