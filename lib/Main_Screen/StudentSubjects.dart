import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSubjects extends StatelessWidget {
  final String studentId;

  const StudentSubjects({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects for Student ID: $studentId'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Students')
            .doc(studentId)
            .snapshots(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
            return Center(child: Text('Student not found.'));
          }

          // Retrieve student details
          var studentData = studentSnapshot.data!;
          var studentName = studentData['name'] ?? 'Unknown';
          var randomNumber = studentData['randomNumber'] ?? 'N/A';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Name: $studentName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Random Number: $randomNumber',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Students')
                      .doc(studentId)
                      .collection('Subjects')
                      .snapshots(),
                  builder: (context, subjectsSnapshot) {
                    if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!subjectsSnapshot.hasData || subjectsSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No subjects found.'));
                    }

                    return ListView.builder(
                      itemCount: subjectsSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var subjectDoc = subjectsSnapshot.data!.docs[index];
                        var subjectName = subjectDoc['subjectName'] ?? 'Unknown';
                        var grade = subjectDoc['grade'] ?? 'N/A';

                        return ListTile(
                          title: Text(subjectName),
                          subtitle: Text('Grade: $grade'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
