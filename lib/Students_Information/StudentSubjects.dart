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
  List<String> _subjects = [];
  bool isLoading = true;

  Future<void> _fetchSubjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userRef = _firestore
            .collection('Teachers_Details')
            .doc(currentUser.email);

        final docSnapshot = await userRef.get();

        if (docSnapshot.exists) {
          String schoolName = docSnapshot['school']; // Fetch school dynamically
          String className = widget.studentClass; // Use student class dynamically

          // Create the dynamic path for all students' subjects
          final classRef = _firestore
              .collection('Schools')
              .doc(schoolName) // Use dynamic school name
              .collection('Classes')
              .doc(className) // Use dynamic class (e.g., FORM 1)
              .collection('Student_Details');

          final classSnapshot = await classRef.get();
          Set<String> allSubjectsSet = {}; // Use a Set to avoid duplicates

          for (var studentDoc in classSnapshot.docs) {
            final studentName = studentDoc.id; // Get the student's name
            final studentSubjectRef = studentDoc.reference
                .collection('Student_Subjects'); // Fetch the student's subjects

            final subjectSnapshot = await studentSubjectRef.get();
            for (var subjectDoc in subjectSnapshot.docs) {
              // Add the subject to the Set (automatically removes duplicates)
              allSubjectsSet.add(subjectDoc['Subject_Name'].toString());
            }
          }

          // Convert the Set to a List and update the UI
          setState(() {
            _subjects = allSubjectsSet.toList(); // Convert Set to List
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        isLoading = false;
      });
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
        child: ListView.builder(
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
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
                  '${index + 1}. ${_subjects[index]}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


