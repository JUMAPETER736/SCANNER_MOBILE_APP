import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentSubjects extends StatefulWidget {
  final String studentName;
  final String studentClass;
  final String studentGender;

  const StudentSubjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
    required this.studentGender,
  }) : super(key: key);

  @override
  _StudentSubjectsState createState() => _StudentSubjectsState();
}

class _StudentSubjectsState extends State<StudentSubjects> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Subject> _subjects = [];
  List<String> _loggedInUserSubjects = []; // Store the subjects taken by the logged-in user
  bool isLoading = true;
  String searchQuery = '';

  // Fetch subjects for the student from Firestore and exclude 'TOTAL_MARKS'
  Future<void> _fetchSubjects() async {
    try {
      final studentRef = _firestore
          .collection('Students_Details')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Student_Subjects');

      final snapshot = await studentRef.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _subjects = snapshot.docs
<<<<<<< HEAD
              .map((doc) => Subject.fromMap(doc.data()))
=======
              .map((doc) => Subject.fromMap(doc.data() as Map<String, dynamic>))
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
              .where((subject) => subject.name != 'TOTAL_MARKS') // Exclude TOTAL_MARKS
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch the logged-in user's subjects
  Future<void> _fetchLoggedInUserSubjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userRef = _firestore
            .collection('Teachers_Details')
            .doc(currentUser.email); // Assume the teacher is logged in by email

        final docSnapshot = await userRef.get();

        if (docSnapshot.exists) {
          setState(() {
            _loggedInUserSubjects = List<String>.from(docSnapshot['subjects']); // Retrieve subjects the user teaches
          });
        }
      }
    } catch (e) {
      print('Error fetching logged-in user subjects: $e');
    }
  }

  // Update the subject grade
  Future<void> _updateSubjectGrade(Subject subject, String newGrade) async {
    try {
      final subjectRef = _firestore
          .collection('Students_Details')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Student_Subjects')
          .doc(subject.name);

      await subjectRef.update({'Subject_Grade': newGrade});

      setState(() {
        _subjects = _subjects.map((sub) {
          return sub.name == subject.name
              ? subject.copyWith(grade: newGrade)
              : sub;
        }).toList();
      });
    } catch (e) {
      print('Error updating subject grade: $e');
    }
  }

  // Show grade input dialog
  Future<String?> _showGradeDialog(String currentGrade) async {
    TextEditingController gradeController = TextEditingController();
    gradeController.text = currentGrade == '_' ? '' : currentGrade;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Grade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter Grade',
                  suffixText: '%',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                final grade = gradeController.text.trim();
                if (_isValidGrade(grade)) {
                  Navigator.of(context).pop(grade);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Invalid Grade. Enter a number from 0 up to 100.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Save', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  bool _isValidGrade(String grade) {
    final int? value = int.tryParse(grade);
    return value != null && value >= 0 && value <= 100;
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchLoggedInUserSubjects(); // Fetch the logged-in user's subjects
  }

  @override
  Widget build(BuildContext context) {
    List<Subject> filteredSubjects = _subjects
        .where((subject) =>
        subject.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    String editableSubjectsText = _loggedInUserSubjects.isEmpty
        ? 'No subjects available for editing'
        : 'Subjects you can Edit: ${_loggedInUserSubjects.join(', ')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects for ${widget.studentName}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? Center(
        child: Text(
          'No subjects available.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                editableSubjectsText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSubjects.length,
                itemBuilder: (context, index) {
                  var subject = filteredSubjects[index];
                  bool canEdit = _loggedInUserSubjects
                      .contains(subject.name); // Check if user can edit

                  return Container(
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
                        '${index + 1}. ${subject.name}',
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
                            'Grade: ${subject.grade == '0' ? '_' : subject.grade}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          if (canEdit)
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () async {
                                String? newGrade =
                                await _showGradeDialog(
                                    subject.grade);
                                if (newGrade != null) {
                                  _updateSubjectGrade(
                                      subject, newGrade);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Subject {
  final String name;
  final String grade;

  Subject({
    required this.name,
    required this.grade,
  });

  factory Subject.fromMap(Map<String, dynamic> data) {
    return Subject(
      name: data['Subject_Name'] ?? 'Unknown',
      grade: data['Subject_Grade'] ?? 'N/A',
    );
  }

  Subject copyWith({
    String? name,
    String? grade,
  }) {
    return Subject(
      name: name ?? this.name,
      grade: grade ?? this.grade,
    );
  }
}
