import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentSubjects extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const StudentSubjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  _StudentSubjectsState createState() => _StudentSubjectsState();
}

class _StudentSubjectsState extends State<StudentSubjects> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Subject> _subjects = [];
  List<String> selectedSubjects = []; // Holds the teacher's selected subjects
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultSubjects(widget.studentClass);
    _checkSavedSelections();
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

    final classRef = _firestore.collection('StudentSubjects').doc(className);

    DocumentSnapshot docSnapshot = await classRef.get();
    if (docSnapshot.exists) {
      final existingSubjects =
      (docSnapshot.data() as Map<String, dynamic>)['Subjects'] as List<dynamic>?;
      if (existingSubjects == null || existingSubjects.isEmpty) {
        await classRef.update({
          'Subjects': subjectList.map((subject) => subject.toMap()).toList(),
        });
      }
    } else {
      await classRef.set({
        'Subjects': subjectList.map((subject) => subject.toMap()).toList(),
      });
    }

    _fetchSubjects(className);
  }

  Future<void> _fetchSubjects(String className) async {
    try {
      final snapshot = await _firestore.collection('StudentSubjects').doc(className).get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        var subjects = data['Subjects'] as List<dynamic>?;

        if (subjects != null) {
          setState(() {
            _subjects = subjects
                .map((subjectData) => Subject.fromMap(subjectData as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _updateSubjectGrade(Subject subject, String newGrade) async {
    try {
      final classRef = _firestore.collection('StudentSubjects').doc(widget.studentClass);
      await classRef.update({
        'Subjects': _subjects.map((sub) => sub.name == subject.name
            ? subject.copyWith(grade: newGrade).toMap()
            : sub.toMap()).toList(),
      });

      setState(() {
        _subjects = _subjects.map((sub) => sub.name == subject.name
            ? subject.copyWith(grade: newGrade)
            : sub).toList();
      });
    } catch (e) {
      print(e);
    }
  }

  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid; // Get user's ID
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Teacher').doc(userId).get();
      if (doc.exists && doc['classes'] != null && doc['subjects'] != null) {
        setState(() {
          // Load saved subjects for the teacher
          selectedSubjects = List<String>.from(doc['subjects']);
          isSaved = true; // Mark as saved
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects for ${widget.studentName}', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: _subjects.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.separated(
          itemCount: _subjects.length,
          separatorBuilder: (context, index) => Divider(color: Colors.blueAccent, thickness: 1.5),
          itemBuilder: (context, index) {
            var subject = _subjects[index];

            // Check if the subject is in the teacher's selected subjects
            bool canEdit = selectedSubjects.contains(subject.name);

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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grade: ${subject.grade}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    if (canEdit) // Only show the edit button if the teacher selected the subject
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () async {
                          String? newGrade = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              TextEditingController gradeController =
                              TextEditingController(text: subject.grade);
                              return AlertDialog(
                                title: Text('Edit Grade for ${subject.name} in %'),
                                content: TextField(
                                  controller: gradeController,
                                  decoration: InputDecoration(labelText: 'New Grade (%)'),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(gradeController.text),
                                    child: Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (newGrade != null && newGrade.isNotEmpty) {
                            _updateSubjectGrade(subject, newGrade);
                          }
                        },
                      ),
                  ],
                ),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: Icon(Icons.book, color: Colors.blueAccent),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Subject {
  final String name;
  final String grade;

  Subject({required this.name, this.grade = 'N/A'});

  Subject copyWith({String? name, String? grade}) {
    return Subject(
      name: name ?? this.name,
      grade: grade ?? this.grade,
    );
  }

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
