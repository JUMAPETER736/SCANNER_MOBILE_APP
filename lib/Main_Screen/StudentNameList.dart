import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Main_Screen/StudentSubjects.dart';

class StudentNameList extends StatefulWidget {
  final User? loggedInUser;

  const StudentNameList({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _StudentNameListState createState() => _StudentNameListState();
}

class _StudentNameListState extends State<StudentNameList> {
  String? userClass;

  @override
  void initState() {
    super.initState();
    _fetchUserClass();
  }

  Future<void> _fetchUserClass() async {
    if (widget.loggedInUser != null) {
      String userId = widget.loggedInUser!.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

        // Debugging output
        print('Fetched user data: ${userData.toString()}');

        var classData = userData?['classes'];

        // Check the type of classData
        if (classData is List) {
          // If it's a list, take the first element or handle accordingly
          setState(() {
            userClass = classData.isNotEmpty ? classData.first.toString() : 'N/A';
          });
        } else if (classData is String) {
          // If it's a string, use it directly
          setState(() {
            userClass = classData;
          });
        } else {
          // Handle unexpected types
          setState(() {
            userClass = 'Invalid class Data';
          });
        }
      } else {
        setState(() {
          userClass = 'No class assigned. Please complete your profile.';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Name of Students', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(child: Text('No user is logged in.')),
      );
    }

    if (userClass == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Name of Students', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userClass == 'N/A' || userClass == 'No class assigned. Please complete your profile.') {
      return Scaffold(
        appBar: AppBar(
          title: Text('Name of Students', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(child: Text(userClass!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Name of Students', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Students')
              .where('studentClass', isEqualTo: userClass)  // Filter students by studentClass
              .orderBy('lastName', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No students found for your class.'));
            }

            return ListView.separated(
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                var student = snapshot.data!.docs[index];
                var firstName = student.get('firstName') as String? ?? 'N/A';
                var lastName = student.get('lastName') as String? ?? 'N/A';
                var studentClass = student.get('studentClass') as String? ?? 'N/A';

                // Debugging output
                print('Fetched student: firstName=$firstName, lastName=$lastName, studentClass=$studentClass');

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
                    title: Text(
                      '$lastName $firstName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Text(
                      'Class: $studentClass',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
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
        ),
      ),
    );
  }
}
