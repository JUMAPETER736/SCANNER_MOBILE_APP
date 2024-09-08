import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Students_Information/StudentSubjects.dart';

class StudentNameList extends StatelessWidget {
  final User? loggedInUser;

  const StudentNameList({Key? key, this.loggedInUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Name of Students',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Text('No user is logged in.'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Teacher')
          .doc(loggedInUser!.uid)
          .get(),
      builder: (context, teacherSnapshot) {
        if (teacherSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Name of Students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blueAccent,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!teacherSnapshot.hasData || !teacherSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Name of Students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blueAccent,
            ),
            body: Center(child: Text('Teacher Data not found.')),
          );
        }

        // Handle the case where teacherClass might be a list or a string
        var teacherData = teacherSnapshot.data!.data() as Map<String, dynamic>;
        var classes = teacherData['classes'] as List<dynamic>? ?? [];
        var teacherClass = classes.isNotEmpty ? classes[0] : 'N/A';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              ' $teacherClass STUDENTS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Students')
                  .doc(teacherClass)
                  .collection('StudentDetails')
                  .orderBy('lastName', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No Students found.'));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var student = snapshot.data!.docs[index];
                    var firstName = student['firstName'] ?? 'N/A';
                    var lastName = student['lastName'] ?? 'N/A';
                    var studentClass = student['studentClass'] ?? 'N/A';

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
                        title: Text(
                          '$lastName $firstName', // Display last name first
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
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
                              builder: (context) => StudentSubjects(

                                studentName: '$lastName $firstName', // Pass last name first
                                studentClass: studentClass,
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
      },
    );
  }
}
