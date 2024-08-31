import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNameList extends StatelessWidget {
  final User? loggedInUser;

  const StudentNameList({Key? key, this.loggedInUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Name of Students'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Students')
            .doc(loggedInUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text('User not found.'));
          }

          var userClass = userSnapshot.data!['form']; // Assuming there's a 'form' field in the user's document

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Students')
                .doc(loggedInUser?.uid)
                .collection('StudentDetails')
                .where('form', isEqualTo: userClass) // Filter for students in the same class as the user
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No students found.'));
              }

              return ListView.separated(
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  var student = snapshot.data!.docs[index];
                  var firstName = student['firstName'];
                  var lastName = student['lastName'];

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        '$firstName $lastName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                      ),
                      onTap: () {
                        // Navigate to the subjects page for the selected student
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentSubjectsPage(
                              studentId: student.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class StudentSubjectsPage extends StatelessWidget {
  final String studentId;

  const StudentSubjectsPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects for Student ID: $studentId'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Students')
            .doc(studentId)
            .collection('Subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No subjects found.'));
          }

          List<String> subjects = [];
          for (var doc in snapshot.data!.docs) {
            subjects.add(doc['subjectName']);
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(subjects[index]),
              );
            },
          );
        },
      ),
    );
  }
}
