import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Student_Subjects extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const Student_Subjects({
    Key? key,
    required this.studentName,
    required this.studentClass,
  }) : super(key: key);

  @override
  _Student_SubjectsState createState() => _Student_SubjectsState();
}

class _Student_SubjectsState extends State<Student_Subjects> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _subjects = [];
  List<String> _userSubjects = [];
  List<String> _userClasses = [];
  Map<String, String> _subjectGrades = {}; // Cache grades
  bool isLoading = true;

  Future<void> _fetchSubjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Use a single query to get teacher details
      final userDoc = await _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email)
          .get();

      if (!userDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      String schoolName = userData['school'] ?? '';
      String className = widget.studentClass;

      // Fetch user's subjects and classes in parallel
      List<String> userSubjectsList = List<String>.from(userData['subjects'] ?? []);
      List<String> userClassesList = List<String>.from(userData['classes'] ?? []);

      // Use batch operations for better performance
      final batch = _firestore.batch();

      // Get specific student's subjects directly instead of querying all students
      final studentSubjectsRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details')
          .doc(widget.studentName)
          .collection('Student_Subjects');

      final studentSubjectsSnapshot = await studentSubjectsRef.get();

      Set<String> subjectsSet = {};
      Map<String, String> gradesMap = {};

      // Process student's subjects and grades in a single loop
      for (var doc in studentSubjectsSnapshot.docs) {
        String subjectName = doc['Subject_Name']?.toString() ?? doc.id;
        String grade = doc['Subject_Grade']?.toString() ?? '';

        subjectsSet.add(subjectName);
        if (grade.isNotEmpty) {
          gradesMap[subjectName] = grade;
        }
      }

      // If no subjects found for this student, fetch from class level (fallback)
      if (subjectsSet.isEmpty) {
        final classRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details');

        final classSnapshot = await classRef.limit(5).get(); // Limit to improve performance

        for (var studentDoc in classSnapshot.docs) {
          final subjectSnapshot = await studentDoc.reference
              .collection('Student_Subjects')
              .limit(10) // Limit subjects per student
              .get();

          for (var subjectDoc in subjectSnapshot.docs) {
            subjectsSet.add(subjectDoc['Subject_Name']?.toString() ?? subjectDoc.id);
          }

          // Break after finding some subjects to improve performance
          if (subjectsSet.isNotEmpty) break;
        }
      }

      setState(() {
        _subjects = subjectsSet.toList()..sort(); // Sort for consistent display
        _userSubjects = userSubjectsList;
        _userClasses = userClassesList;
        _subjectGrades = gradesMap;
        isLoading = false;
      });

      print("All subjects: $_subjects");
      print("User's assigned Subjects: $_userSubjects");
      print("User's assigned Classes: $_userClasses");
      print("Current student class: ${widget.studentClass}");
    } catch (e) {
      print('Error fetching Subjects: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to check if teacher can edit this subject
  bool _canEditSubject(String subject) {
    // Check if the current class is in teacher's assigned classes
    if (!_userClasses.contains(widget.studentClass)) {
      return false;
    }

    // If teacher has only one class, they can edit all their assigned subjects
    if (_userClasses.length == 1) {
      return _userSubjects.contains(subject);
    }

    // For multiple classes, use index-based matching (original logic)
    int classIndex = _userClasses.indexOf(widget.studentClass);

    // Check if there's a subject at the same index position
    if (classIndex < _userSubjects.length) {
      String subjectAtSameIndex = _userSubjects[classIndex];
      return subjectAtSameIndex == subject;
    }

    return false;
  }

  // Optimized grade fetching - use cached data first
  Future<String> _fetchGradeForSubject(String subject) async {
    // Return cached grade if available
    if (_subjectGrades.containsKey(subject)) {
      return _subjectGrades[subject]!;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'N/A';

      final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        String schoolName = docSnapshot['school'] ?? '';
        String className = widget.studentClass;

        final gradeRef = _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(className)
            .collection('Student_Details')
            .doc(widget.studentName)
            .collection('Student_Subjects')
            .doc(subject);

        final gradeSnapshot = await gradeRef.get();

        if (gradeSnapshot.exists) {
          final grade = gradeSnapshot['Subject_Grade'];
          if (grade != null && grade.isNotEmpty) {
            print("Fetched Grade for $subject: $grade");
            // Cache the grade
            _subjectGrades[subject] = grade.toString();
            return grade.toString();
          }
        }
      }
    } catch (e) {
      print('Error fetching Grade for Subject: $e');
    }
    return '';
  }

  Future<void> _updateGrade(String subject) async {
    String newGrade = '';
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Grade for $subject'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(hintText: "Enter new Grade"),
                    onChanged: (value) {
                      setState(() {
                        newGrade = value.trim();
                        errorMessage = '';
                      });
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                // Validation for grade input
                if (newGrade.isEmpty || int.tryParse(newGrade) == null) {
                  setState(() {
                    errorMessage = 'Please enter a valid grade (numeric value)';
                  });
                } else if (int.parse(newGrade) < 0) {
                  setState(() {
                    errorMessage = 'Grade cannot be less than 0';
                  });
                } else if (int.parse(newGrade) > 100) {
                  setState(() {
                    errorMessage = 'Grade cannot be greater than 100';
                  });
                } else {
                  try {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;

                    final userRef = _firestore.collection('Teachers_Details').doc(currentUser.email);
                    final docSnapshot = await userRef.get();

                    if (docSnapshot.exists) {
                      String schoolName = (docSnapshot['school'] ?? '').trim();
                      String className = widget.studentClass.trim();
                      String studentName = widget.studentName.trim();

                      List<String> nameParts = studentName.split(" ");
                      String reversedName = nameParts.length == 2
                          ? "${nameParts[1]} ${nameParts[0]}"
                          : studentName;

                      final studentRefNormal = _firestore
                          .collection('Schools')
                          .doc(schoolName)
                          .collection('Classes')
                          .doc(className)
                          .collection('Student_Details')
                          .doc(studentName);

                      final studentRefReversed = _firestore
                          .collection('Schools')
                          .doc(schoolName)
                          .collection('Classes')
                          .doc(className)
                          .collection('Student_Details')
                          .doc(reversedName);

                      final studentSnapshotNormal = await studentRefNormal.get();
                      final studentSnapshotReversed = await studentRefReversed.get();

                      DocumentReference studentRef;
                      if (studentSnapshotNormal.exists) {
                        studentRef = studentRefNormal;
                      } else if (studentSnapshotReversed.exists) {
                        studentRef = studentRefReversed;
                      } else {
                        return;
                      }

                      final subjectRef = studentRef.collection('Student_Subjects').doc(subject);
                      int gradeInt = int.parse(newGrade);

                      final subjectSnapshot = await subjectRef.get();
                      Map<String, dynamic> existingData = {};

                      if (subjectSnapshot.exists) {
                        existingData = subjectSnapshot.data() as Map<String, dynamic>? ?? {};
                      }

                      // Check if it's FORM 3 or FORM 4 (Seniors)
                      if (className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4') {
                        int gradePoint;

                        if (gradeInt >= 90) {
                          gradePoint = 1;
                        } else if (gradeInt >= 80) {
                          gradePoint = 2;
                        } else if (gradeInt >= 75) {
                          gradePoint = 3;
                        } else if (gradeInt >= 70) {
                          gradePoint = 4;
                        } else if (gradeInt >= 65) {
                          gradePoint = 5;
                        } else if (gradeInt >= 60) {
                          gradePoint = 6;
                        } else if (gradeInt >= 55) {
                          gradePoint = 7;
                        } else if (gradeInt >= 50) {
                          gradePoint = 8;
                        } else {
                          gradePoint = 9;
                        }

                        Map<String, int> positionData = await _calculateSubjectPosition(schoolName, className, subject, gradeInt);

                        Map<String, dynamic> dataToSave = {
                          'Subject_Grade': newGrade,
                          'Grade_Point': gradePoint,
                          'Subject_Position': positionData['position'],
                          'Total_Students_Subject': positionData['total'],
                        };

                        existingData.addAll(dataToSave);
                        await subjectRef.set(existingData, SetOptions(merge: true));

                      } else if (className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2') {
                        String gradeLetter;

                        if (gradeInt >= 85) {
                          gradeLetter = 'A';
                        } else if (gradeInt >= 75) {
                          gradeLetter = 'B';
                        } else if (gradeInt >= 65) {
                          gradeLetter = 'C';
                        } else if (gradeInt >= 50) {
                          gradeLetter = 'D';
                        } else {
                          gradeLetter = 'F';
                        }

                        Map<String, int> positionData = await _calculateSubjectPosition(schoolName, className, subject, gradeInt);

                        Map<String, dynamic> dataToSave = {
                          'Subject_Grade': newGrade,
                          'Grade_Letter': gradeLetter,
                          'Subject_Position': positionData['position'],
                          'Total_Students_Subject': positionData['total'],
                        };

                        existingData.addAll(dataToSave);
                        await subjectRef.set(existingData, SetOptions(merge: true));
                      }

                      // Update cached grade
                      setState(() {
                        _subjectGrades[subject] = newGrade;
                      });

                      Navigator.of(context).pop();

                      // Refresh the main widget state
                      this.setState(() {});
                    }
                  } catch (e) {
                    print('Error updating Subject Grade and Grade Point: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _calculateSubjectPosition(
      String schoolName, String className, String subject, int newGrade) async {

    try {
      final classRef = _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(className)
          .collection('Student_Details');

      final studentsSnapshot = await classRef.get();

      List<int> subjectGrades = [];
      int totalStudentsWithSubject = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        final subjectRef = studentDoc.reference.collection('Student_Subjects').doc(subject);
        final subjectSnapshot = await subjectRef.get();

        if (subjectSnapshot.exists) {
          final gradeData = subjectSnapshot.data();
          if (gradeData != null && gradeData['Subject_Grade'] != null) {
            int grade = int.tryParse(gradeData['Subject_Grade'].toString()) ?? 0;
            subjectGrades.add(grade);
            totalStudentsWithSubject++;
          }
        }
      }

      subjectGrades.add(newGrade);
      totalStudentsWithSubject++;

      subjectGrades.sort((a, b) => b.compareTo(a));

      int position = 1;
      for (int i = 0; i < subjectGrades.length; i++) {
        if (subjectGrades[i] == newGrade) {
          position = i + 1;
          break;
        }
      }

      return {
        'position': position,
        'total': totalStudentsWithSubject,
      };

    } catch (e) {
      print('Error calculating subject position: $e');
      return {
        'position': 1,
        'total': 1,
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects for ${widget.studentName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent, // Changed to blue color
          strokeWidth: 3.0,
        ),
      )
          : _subjects.isEmpty
          ? const Center(
        child: Text(
          'No Subjects Available.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            bool canEditThisSubject = _canEditSubject(_subjects[index]);
            String subject = _subjects[index];

            // Use cached grade if available, otherwise show loading
            String grade = _subjectGrades[subject] ?? '';

            if (grade.isEmpty) {
              // Load grade asynchronously and update cache
              _fetchGradeForSubject(subject).then((fetchedGrade) {
                if (fetchedGrade.isNotEmpty && mounted) {
                  setState(() {
                    _subjectGrades[subject] = fetchedGrade;
                  });
                }
              });
              grade = 'Loading...'; // Show loading state
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  '${index + 1}. $subject',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                subtitle: Text(
                  'Grade: ${grade.isEmpty || grade == 'Loading...' ? (grade == 'Loading...' ? grade : 'N/A') : grade}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: grade == 'Loading...' ? Colors.blue : Colors.black54,
                  ),
                ),
                trailing: canEditThisSubject
                    ? IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blueAccent,
                  iconSize: 20,
                  onPressed: () {
                    _updateGrade(subject);
                  },
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}