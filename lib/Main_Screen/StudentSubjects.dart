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
        child: FutureBuilder<void>(
          future: _initializeDefaultSubjects(studentClass),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('StudentSubjects')
                  .doc(studentClass)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('No subjects found for Class $studentClass.'));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                var subjects = data['Subjects'] as List<dynamic>?;

                if (subjects != null) {
                  List<Subject> subjectList = subjects
                      .map((subjectData) => Subject.fromMap(subjectData as Map<String, dynamic>))
                      .toList();

                  subjectList.sort((a, b) => a.name.compareTo(b.name));

                  return ListView.separated(
                    itemCount: subjectList.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.blueAccent, thickness: 1.5),
                    itemBuilder: (context, index) {
                      var subject = subjectList[index];
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
                            subject.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          trailing: Text(
                            'Grade: ${subject.grade}',
                            style: TextStyle(
                              fontSize: 16,
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
                  return Center(child: Text('Subjects data is NOT in the expected format.'));
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _initializeDefaultSubjects(String className) async {
    final subjects = {
      'FORM 1': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],
      'FORM 2': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],
      'FORM 3': [
        Subject(name: 'BIOLOGY'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'MATHEMATICS'),
      ],
      'FORM 4': [
        Subject(name: 'BIOLOGY'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'MATHEMATICS'),
      ],
    };

    final subjectList = subjects[className] ?? [];

    final classRef = FirebaseFirestore.instance.collection('StudentSubjects').doc(className);

    // Get current document data
    DocumentSnapshot docSnapshot = await classRef.get();
    if (docSnapshot.exists) {
      // Update existing document if subjects do not exist
      final existingSubjects = (docSnapshot.data() as Map<String, dynamic>)['Subjects'] as List<dynamic>?;
      if (existingSubjects == null || existingSubjects.isEmpty) {
        await classRef.update({
          'Subjects': subjectList.map((subject) => subject.toMap()).toList(),
        });
      }
    } else {
      // Create new document with subjects
      await classRef.set({
        'Subjects': subjectList.map((subject) => subject.toMap()).toList(),
      });
    }
  }
}

class Subject {
  final String name;
  final String grade;

  Subject({required this.name, this.grade = 'N/A'});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      name: map['name'] ?? 'N/A',
      grade: map['grade'] ?? 'N/A',
    );
  }
}
