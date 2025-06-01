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

  // Enhanced comprehensive position calculation for all students in the class
  Future<void> _calculateSubjectStatsAndPosition(String schoolName, String className) async {
    try {
      print("Starting comprehensive subject stats calculation...");

      final studentsSnapshot = await _firestore
          .collection('Schools/$schoolName/Classes/$className/Student_Details')
          .get();

      Map<String, List<int>> marksPerSubject = {};
      Map<String, List<Map<String, dynamic>>> subjectStudentData = {};

      // Collect all students' marks for each subject
      for (var studentDoc in studentsSnapshot.docs) {
        final studentName = studentDoc.id;

        final subjectsSnapshot = await _firestore
            .collection('Schools/$schoolName/Classes/$className/Student_Details/$studentName/Student_Subjects')
            .get();

        for (var subjectDoc in subjectsSnapshot.docs) {
          final data = subjectDoc.data();
          final subjectName = data['Subject_Name'] ?? subjectDoc.id;
          final gradeStr = data['Subject_Grade']?.toString() ?? 'N/A';

          // Skip students who don't take the subject (N/A grades)
          if (gradeStr == 'N/A' || gradeStr == null || gradeStr.isEmpty) continue;

          int grade = double.tryParse(gradeStr)?.round() ?? 0;

          if (!marksPerSubject.containsKey(subjectName)) {
            marksPerSubject[subjectName] = [];
            subjectStudentData[subjectName] = [];
          }

          marksPerSubject[subjectName]!.add(grade);
          subjectStudentData[subjectName]!.add({
            'studentName': studentName,
            'grade': grade,
          });
        }
      }

      // Calculate positions and update Firestore for each subject
      for (String subjectName in subjectStudentData.keys) {
        var studentList = subjectStudentData[subjectName]!;

        // Sort by grade in descending order
        studentList.sort((a, b) => b['grade'].compareTo(a['grade']));

        // Calculate positions (handle ties properly)
        Map<String, int> positions = {};
        int currentPosition = 1;

        for (int i = 0; i < studentList.length; i++) {
          String currentStudentName = studentList[i]['studentName'];
          int currentGrade = studentList[i]['grade'];

          // Handle ties - if previous grade is different, update position
          if (i > 0 && studentList[i-1]['grade'] != currentGrade) {
            currentPosition = i + 1;
          }

          positions[currentStudentName] = currentPosition;

          // Update the position in Firestore for each student
          try {
            await _firestore
                .doc('Schools/$schoolName/Classes/$className/Student_Details/$currentStudentName/Student_Subjects/$subjectName')
                .update({
              'Subject_Position': currentPosition,
              'Total_Students_Subject': studentList.length, // Only count students who actually take the subject
              'lastUpdated': FieldValue.serverTimestamp(),
            });

            print("Updated position for $currentStudentName in $subjectName: Position $currentPosition of ${studentList.length}");
          } catch (e) {
            print("Error updating position for $currentStudentName in $subjectName: $e");
          }
        }
      }

      print("Comprehensive subject stats calculation completed successfully!");

    } catch (e) {
      print("Error in comprehensive stats calculation: $e");
    }
  }

  // Grading functions for different levels
  String _getJuniorsGrade(int score) {
    if (score >= 85) return 'A';
    if (score >= 75) return 'B';
    if (score >= 65) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  String _getJuniorsRemark(String grade) {
    switch (grade) {
      case 'A': return 'EXCELLENT';
      case 'B': return 'VERY GOOD';
      case 'C': return 'GOOD';
      case 'D': return 'PASS';
      default: return 'FAIL';
    }
  }

  String _getSeniorsGrade(int score) {
    if (score >= 90) return '1';
    if (score >= 80) return '2';
    if (score >= 75) return '3';
    if (score >= 70) return '4';
    if (score >= 65) return '5';
    if (score >= 60) return '6';
    if (score >= 55) return '7';
    if (score >= 50) return '8';
    return '9';
  }

  String _getSeniorsRemark(String grade) {
    switch (grade) {
      case '1': return 'Distinction';
      case '2': return 'Distinction';
      case '3': return 'Strong Credit';
      case '4': return 'Strong Credit';
      case '5': return 'Credit';
      case '6': return 'Weak Credit';
      case '7': return 'Pass';
      case '8': return 'Weak Pass';
      default: return 'Fail';
    }
  }

  // Removed _getSeniorsPoints function as requested

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
                    decoration: InputDecoration(
                      hintText: "Enter grade (0-100)",
                      labelText: "Grade",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        newGrade = value.trim();
                        // Real-time validation
                        if (value.isEmpty) {
                          errorMessage = '';
                        } else if (int.tryParse(value) == null) {
                          errorMessage = 'Please enter a valid numeric grade';
                        } else {
                          int grade = int.parse(value);
                          if (grade < 0) {
                            errorMessage = 'Grade cannot be less than 0';
                          } else if (grade > 100) {
                            errorMessage = 'Grade cannot be greater than 100';
                          } else {
                            errorMessage = '';
                          }
                        }
                      });
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                // Final validation before saving
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

                      // Handle name variations
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
                      String actualStudentName;
                      if (studentSnapshotNormal.exists) {
                        studentRef = studentRefNormal;
                        actualStudentName = studentName;
                      } else if (studentSnapshotReversed.exists) {
                        studentRef = studentRefReversed;
                        actualStudentName = reversedName;
                      } else {
                        print("Student document not found for either name variation");
                        return;
                      }

                      final subjectRef = studentRef.collection('Student_Subjects').doc(subject);
                      int gradeInt = int.parse(newGrade);

                      final subjectSnapshot = await subjectRef.get();
                      Map<String, dynamic> existingData = {};

                      if (subjectSnapshot.exists) {
                        existingData = subjectSnapshot.data() as Map<String, dynamic>? ?? {};
                      }

                      // Determine if student is Senior or Junior based on class
                      bool isSenior = className.toUpperCase() == 'FORM 3' || className.toUpperCase() == 'FORM 4';
                      bool isJunior = className.toUpperCase() == 'FORM 1' || className.toUpperCase() == 'FORM 2';

                      Map<String, dynamic> dataToSave = {
                        'Subject_Grade': newGrade,
                        'Subject_Name': subject, // Ensure subject name is saved
                      };

                      if (isSenior) {
                        // Senior system (FORM 3 & 4) - Removed points logic
                        String gradePoint = _getSeniorsGrade(gradeInt);
                        String remark = _getSeniorsRemark(gradePoint);

                        dataToSave.addAll({
                          'Grade_Point': int.parse(gradePoint),
                          'Grade_Remark': remark,
                        });

                      } else if (isJunior) {
                        // Junior system (FORM 1 & 2)
                        String gradeLetter = _getJuniorsGrade(gradeInt);
                        String remark = _getJuniorsRemark(gradeLetter);

                        dataToSave.addAll({
                          'Grade_Letter': gradeLetter,
                          'Grade_Remark': remark,
                        });
                      }

                      // Merge with existing data and save
                      existingData.addAll(dataToSave);
                      await subjectRef.set(existingData, SetOptions(merge: true));

                      print("Grade updated successfully for $actualStudentName in $subject");

                      // Update cached grade
                      this.setState(() {
                        _subjectGrades[subject] = newGrade;
                      });

                      Navigator.of(context).pop();

                      // *** CRITICAL: Run comprehensive position calculation for entire class ***
                      print("Starting comprehensive position calculation...");
                      await _calculateSubjectStatsAndPosition(schoolName, className);
                      print("Position calculation completed!");

                      // Refresh the main widget state
                      this.setState(() {});

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Grade updated successfully! Positions recalculated for all students.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );

                    }
                  } catch (e) {
                    print('Error updating Subject Grade: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating grade. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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