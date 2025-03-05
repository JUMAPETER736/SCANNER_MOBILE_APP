import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Students_Information/StudentSubjects.dart';

class StudentNameList extends StatefulWidget {
  final User? loggedInUser;

  const StudentNameList({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _StudentNameListState createState() => _StudentNameListState();
}

class _StudentNameListState extends State<StudentNameList> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
<<<<<<< HEAD
  String? teacherSchool;
  String? teacherClass;
  bool _hasSelectedCriteria = false;
=======
  String? teacherClass;
  bool _hasSelectedClass = false;
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a

  @override
  void initState() {
    super.initState();
    _checkTeacherSelection();
  }

<<<<<<< HEAD
  // Method to check if the teacher has selected school and class
=======
  // Method to check if the teacher has selected a class
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
  void _checkTeacherSelection() async {
    if (widget.loggedInUser != null) {
      var teacherSnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(widget.loggedInUser!.email)
          .get();

      if (teacherSnapshot.exists) {
        var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
<<<<<<< HEAD
        var school = teacherData['school'];
        var classes = teacherData['classes'] as List<dynamic>? ?? [];

        if (school != null && classes.isNotEmpty) {
          setState(() {
            teacherSchool = school;
            teacherClass = classes[0]; // Set the first selected class
            _hasSelectedCriteria = true;
=======
        var classes = teacherData['classes'] as List<dynamic>? ?? [];
        if (classes.isNotEmpty) {
          setState(() {
            teacherClass = classes[0]; // Set the first selected class
            _hasSelectedClass = true;
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
          });
        }
      }
    }
  }

<<<<<<< HEAD
  // Method to create collections if they do not exist
  Future<void> _createCollectionsIfNotExist(String school, String teacherClass, String studentName) async {
    // Check if the teacher's data exists and create the collection if needed
    var teacherDoc = FirebaseFirestore.instance.collection('Teachers_Details').doc(widget.loggedInUser!.email);
    if (!(await teacherDoc.get()).exists) {
      await teacherDoc.set({
        'school': school,
        'classes': [teacherClass], // Add initial class
      });
    }

    // Create the school and class if they do not exist
    var schoolDoc = FirebaseFirestore.instance.collection('Schools').doc(school);
    var classDoc = schoolDoc.collection('Classes').doc(teacherClass);

    // Create the student data in the Students collection
    var studentsCollection = classDoc.collection('Students');
    await studentsCollection.doc(studentName).set({
      'name': studentName,
      'gender': 'N/A', // You can update this based on actual student info
    });
  }

=======
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
  @override
  Widget build(BuildContext context) {
    if (widget.loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Name of Students',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Text('No user is logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        title: _hasSelectedCriteria
            ? Text(
          '$teacherSchool',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Name of Students',
=======
        title: Text(
          _hasSelectedClass ? '$teacherClass STUDENTS' : 'Name of Students',
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
<<<<<<< HEAD
        actions: _hasSelectedCriteria
=======
        actions: _hasSelectedClass
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
            ? [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog(context);
            },
          ),
        ]
            : [],
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
<<<<<<< HEAD
        child: _hasSelectedCriteria
            ? Column(
          children: [
            Text(
              'Class: $teacherClass',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Schools')
                  .doc(teacherSchool) // Get the teacher's assigned school
                  .collection('Classes')
                  .doc(teacherClass) // Get the teacher's assigned class
                  .collection('Students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
=======
        child: _hasSelectedClass
            ? StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Students_Details')
              .doc(teacherClass!)
              .collection('Student_Details')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No Student found.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );
            }

            // Get the list of students
            var studentDocs = snapshot.data!.docs;
            List<Map<String, dynamic>> students = [];

            for (var studentDoc in studentDocs) {
              var studentName = studentDoc.id; // Student full name
              students.add({
                'name': studentName,
                'reference': studentDoc.reference,
              });
            }

            // Retrieve first and last names for each student
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _getStudentNames(students),
              builder: (context, namesSnapshot) {
                if (namesSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!namesSnapshot.hasData || namesSnapshot.data!.isEmpty) {
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
                  return Center(
                    child: Text(
                      'No Student found.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  );
                }

<<<<<<< HEAD
                // Get the list of students
                var studentDocs = snapshot.data!.docs;
                List<Map<String, dynamic>> students = [];

                for (var studentDoc in studentDocs) {
                  var studentName = studentDoc.id; // Student full name
                  students.add({
                    'name': studentName,
                    'reference': studentDoc.reference,
                  });
                }

                // Retrieve first and last names for each student
                return FutureBuilder<List<Map<String, dynamic>>>( // FutureBuilder to fetch the names
                  future: _getStudentNames(students),
                  builder: (context, namesSnapshot) {
                    if (namesSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!namesSnapshot.hasData || namesSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No Student found.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    // Filtered documents based on search query
                    var filteredDocs = namesSnapshot.data!.where((student) {
                      var fullName = student['fullName'] ?? '';
                      return fullName.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Show "Student NOT found" if the filtered list is empty
                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'Student NOT found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredDocs.length,
                      separatorBuilder: (context, index) => SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        var student = filteredDocs[index];
                        var fullName = student['fullName'] ?? 'N/A';
                        var studentGender = student['gender'] ?? 'N/A';

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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            title: Text(
                              fullName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            subtitle: Text(
                              'Gender: $studentGender',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward,
                              color: Colors.blueAccent,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentSubjects(
                                    studentName: fullName,
                                    studentClass: teacherClass!,
                                    studentGender: studentGender,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
=======
                // Filtered documents based on search query
                var filteredDocs = namesSnapshot.data!.where((student) {
                  var fullName = student['fullName'] ?? '';
                  return fullName.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                // Show "Student NOT found" if the filtered list is empty
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'Student NOT found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var student = filteredDocs[index];
                    var fullName = student['fullName'] ?? 'N/A';
                    var studentGender = student['gender'] ?? 'N/A';

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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Text(
                          '${index + 1}.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          fullName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        subtitle: Text(
                          'Gender: $studentGender',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward,
                          color: Colors.blueAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentSubjects(
                                studentName: fullName,
                                studentClass: teacherClass!,
                                studentGender: studentGender,
                              ),
                            ),
                          );
                        },
                      ),
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
                    );
                  },
                );
              },
<<<<<<< HEAD
            )


          ],
        )
            : Center(
          child: Text(
            'Please select Class First',
=======
            );
          },
        )
            : Center(
          child: Text(
            'Please select Class & Subject First',
>>>>>>> 4ef2bc86fe37fd22bcf55155557159ec4d7cb64a
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  // Fetch first and last names from Firestore
  Future<List<Map<String, dynamic>>> _getStudentNames(List<Map<String, dynamic>> students) async {
    List<Map<String, dynamic>> studentNames = [];

    for (var student in students) {
      var studentRef = student['reference'];
      var personalInfoDoc = await studentRef.collection('Personal_Information').doc('Registered_Information').get();
      if (personalInfoDoc.exists) {
        var personalInfo = personalInfoDoc.data() as Map<String, dynamic>;
        var firstName = personalInfo['firstName'] ?? 'N/A';
        var lastName = personalInfo['lastName'] ?? 'N/A';
        var gender = personalInfo['studentGender'] ?? 'N/A';

        studentNames.add({
          'fullName': '$lastName $firstName',
          'gender': gender,
        });
      }
    }
    return studentNames;
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search Student'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter first or last name',
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _searchQuery = _searchController.text;
                });
              },
              child: Text(
                'Search',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
