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
  String searchQuery = ''; // For filtering subjects

  @override
  void initState() {
    super.initState();
    _initializeDefaultSubjects();
    _checkSavedSelections();
  }

  Future<void> _initializeDefaultSubjects() async {

    final defaultSubjects = {
      'FORM 1': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'COMPUTER SCIENCE'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],

      'FORM 2': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'COMPUTER SCIENCE'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],

      'FORM 3': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'COMPUTER SCIENCE'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],

      'FORM 4': [
        Subject(name: 'AGRICULTURE'),
        Subject(name: 'BIBLE KNOWLEDGE'),
        Subject(name: 'BIOLOGY'),
        Subject(name: 'CHEMISTRY'),
        Subject(name: 'CHICHEWA'),
        Subject(name: 'COMPUTER SCIENCE'),
        Subject(name: 'ENGLISH'),
        Subject(name: 'LIFE SKILLS'),
        Subject(name: 'MATHEMATICS'),
        Subject(name: 'PHYSICS'),
        Subject(name: 'SOCIAL STUDIES'),
      ],
    };


    final studentRef = _firestore
        .collection('Students')
        .doc(widget.studentClass)
        .collection('StudentDetails')
        .doc(widget.studentName);

    DocumentSnapshot docSnapshot = await studentRef.get();

    if (docSnapshot.exists) {
      _fetchSubjects();
    } else {
      final subjectList = defaultSubjects[widget.studentClass] ?? [];
      await studentRef.set({
        'Subjects': subjectList.map((subject) => subject.toMap()).toList(),
      });
      _fetchSubjects();
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final studentRef = _firestore
          .collection('Students')
          .doc(widget.studentClass)
          .collection('StudentDetails')
          .doc(widget.studentName);

      final snapshot = await studentRef.get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        var subjects = data['Subjects'] as List<dynamic>?;

        if (subjects != null) {
          setState(() {
            _subjects = subjects
                .map((subjectData) =>
                Subject.fromMap(subjectData as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateSubjectGrade(Subject subject, String newGrade) async {
    try {
      final studentRef = _firestore
          .collection('Students')
          .doc(widget.studentClass)
          .collection('StudentDetails')
          .doc(widget.studentName);

      // Update the subject's grade
      await studentRef.update({
        'Subjects': _subjects
            .map((sub) => sub.name == subject.name
            ? subject.copyWith(grade: newGrade).toMap()
            : sub.toMap())
            .toList(),
      });

      // Update local state
      setState(() {
        _subjects = _subjects
            .map((sub) =>
        sub.name == subject.name ? subject.copyWith(grade: newGrade) : sub)
            .toList();
      });

      // Save to SchoolReports
      await _saveToSchoolReports();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveToSchoolReports() async {
    try {
      final studentRef = _firestore
          .collection('Students')
          .doc(widget.studentClass)
          .collection('StudentDetails')
          .doc(widget.studentName);

      final studentSnapshot = await studentRef.get();

      if (studentSnapshot.exists) {
        var data = studentSnapshot.data() as Map<String, dynamic>?;
        var subjects = data?['Subjects'] as List<dynamic>?;

        if (subjects != null) {
          // Calculate total marks for the student
          int totalMarks = subjects.fold<int>(
            0,
                (previousValue, subject) {
              final gradeStr = (subject as Map<String, dynamic>)['grade'] ?? '0';
              final grade = int.tryParse(gradeStr) ?? 0;
              return previousValue + grade;
            },
          );

          // Calculate teacherTotalMarks based on the number of grades that are not "N/A"
          int teacherTotalMarks = subjects.where((subject) {
            final gradeStr = (subject as Map<String, dynamic>)['grade'] ?? 'N/A';
            return gradeStr != 'N/A';
          }).length * 100;

          await _firestore
              .collection('SchoolReports')
              .doc(widget.studentClass)
              .collection('StudentReports')
              .doc(widget.studentName)
              .set({
            'firstName': widget.studentName.split(' ').first,
            'lastName': widget.studentName.split(' ').last,
            'grades': subjects,
            'totalMarks': totalMarks,
            'teacherTotalMarks': teacherTotalMarks, // Updated calculation
            'studentId': FirebaseAuth.instance.currentUser?.uid,
          }, SetOptions(merge: true));
        } else {
          print('Subjects field is null or NOT a list');
        }
      } else {
        print('Student document does NOT exist');
      }
    } catch (e) {
      print('Error fetching Student DATA: $e');
    }
  }



  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid; // Get user's ID
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Teacher')
          .doc(userId)
          .get();
      if (doc.exists && doc['classes'] != null && doc['subjects'] != null) {
        setState(() {
          // Load saved subjects for the teacher
          selectedSubjects = List<String>.from(doc['subjects']);
          isSaved = true; // Mark as saved
        });
      }
    }
  }

  void _showSearchDialog() async {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search Subjects'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter Subject Name',
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 10),
              if (searchQuery.isNotEmpty &&
                  _subjects
                      .where((subject) => subject.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                      .isEmpty)
                Text(

                    'Sorry, NO Subject found',

                    style: TextStyle(color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,


                    ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    List<Subject> filteredSubjects = _subjects
        .where((subject) =>
        subject.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    // Get the list of selected subjects for display
    String selectedSubjectsText = selectedSubjects.isEmpty
        ? 'No subjects selected'
        : selectedSubjects.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects for ${widget.studentName}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add the text message here
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'You can only Edit Grade for: $selectedSubjectsText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Display a loading indicator if subjects are being fetched
            if (_subjects.isEmpty)
              Center(child: CircularProgressIndicator())
            else if (filteredSubjects.isEmpty)
              Center(
                child: Text(
                  'Subject NOT Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filteredSubjects.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.blueAccent, thickness: 1.5),
                  itemBuilder: (context, index) {
                    var subject = filteredSubjects[index];

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
                          '${index + 1}. ${subject.name}', // Show numbering
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
                            if (canEdit) // Only show the edit button if the teacher selected the subject
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () async {
                                  String? newGrade = await _showGradeDialog(subject.grade);
                                  if (newGrade != null) {
                                    _updateSubjectGrade(subject, newGrade);
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
              if (gradeController.text.isNotEmpty && !_isValidGrade(gradeController.text))
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),

                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel
              },
              child: Text(

                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                              color: Colors.red
                          ),
              ),
            ),
            TextButton(
              onPressed: () {
                final grade = gradeController.text.trim();
                if (_isValidGrade(grade)) {
                  Navigator.of(context).pop(grade); // Save
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid Grade. Enter a number from 0 up to 100.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },

              child: Text(

                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,

                          )
              ),
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



}

class Subject {
  final String name;
  final String grade;

  Subject({required this.name, this.grade = '_'});

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
      name: map['name'] ?? '',
      grade: map['grade'] ?? '_',
    );
  }
}
