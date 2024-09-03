import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSubjects extends StatelessWidget {
  final String studentName;
  final String studentClass;

  const StudentSubjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects for $studentName', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(studentClass)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No subjects found for class $studentClass.'));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            var subjects = data['subjects'];

            if (subjects is List<dynamic>) {
              return ListView.separated(
                itemCount: subjects.length,
                separatorBuilder: (context, index) => Divider(color: Colors.blueAccent, thickness: 1.5),
                itemBuilder: (context, index) {
                  var subjectName = subjects[index] ?? 'N/A';

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
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        subjectName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: Icon(Icons.book, color: Colors.blueAccent),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('Subjects data is not in the expected format.'));
            }
          },
        ),
      ),
    );
  }
}
