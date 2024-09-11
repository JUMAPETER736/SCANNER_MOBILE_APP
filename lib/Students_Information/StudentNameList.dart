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
  String? teacherClass;
  bool _hasSelectedClass = false; // To check if the class and subjects are selected

  @override
  void initState() {
    super.initState();
    _checkTeacherSelection();
  }

  // Method to check if the teacher has selected a class and subjects
  void _checkTeacherSelection() async {
    if (widget.loggedInUser != null) {
      var teacherSnapshot = await FirebaseFirestore.instance
          .collection('Teacher')
          .doc(widget.loggedInUser!.uid)
          .get();

      if (teacherSnapshot.exists) {
        var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
        var classes = teacherData['classes'] as List<dynamic>? ?? [];
        if (classes.isNotEmpty) {
          setState(() {
            teacherClass = classes[0];
            _hasSelectedClass = true;
          });
        }
      }
    }
  }

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
        title: Text(
          _hasSelectedClass ? ' $teacherClass STUDENTS' : 'Name of Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: _hasSelectedClass
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
        child: _hasSelectedClass
            ? StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Students')
              .doc(teacherClass!)
              .collection('StudentDetails')
              .orderBy('lastName', descending: false)
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
                      color: Colors.red),
                ),
              );
            }

            var filteredDocs = snapshot.data!.docs.where((doc) {
              var firstName = doc['firstName'] ?? '';
              var lastName = doc['lastName'] ?? '';
              var studentGender = doc['studentGender'] ?? '';
              return firstName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
                  lastName.toLowerCase().contains(_searchQuery.toLowerCase());
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
                var firstName = student['firstName'] ?? 'N/A';
                var lastName = student['lastName'] ?? 'N/A';
                var studentGender = student['studentGender'] ?? 'N/A';
                var studentClass = student['studentClass'] ?? 'N/A';

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
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),

                    leading: Text(
                      '${index + 1}', // Displaying just the number
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),

                    title: Text(
                      '${lastName.toUpperCase()} ${firstName.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),

                    subtitle: Text( // Display the student's gender here
                      'Gender: $studentGender',
                      style: TextStyle(
                        fontSize: 16,
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
                            studentName: '$lastName $firstName',
                            studentGender: '$studentGender', // Passing gender to the next screen
                            studentClass: studentClass,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );



          },
        )
            : Center(
          child: Text(
            'Please select Class & Subject First',
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

  // Method to show search dialog
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
