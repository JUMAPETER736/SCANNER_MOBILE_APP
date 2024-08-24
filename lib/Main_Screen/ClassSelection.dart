import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSelection extends StatefulWidget {
  @override
  _ClassSelectionState createState() => _ClassSelectionState();
}

class _ClassSelectionState extends State<ClassSelection> {
  String? selectedClass; // Variable to hold selected class
  String? selectedSubject; // Variable to hold selected subject

  final Map<String, List<String>> classSubjects = {

    'FORM 1': ['MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 2': ['MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 3': ['MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 4': ['MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    // Add more classes and their corresponding subjects as needed
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Class and Subject'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/done.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              stops: [0.5, 1],
              colors: [
                Colors.black.withOpacity(.9),
                Colors.black.withOpacity(.2),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dropdown for selecting class
              DropdownButton<String>(
                value: selectedClass,
                hint: Text(
                  'Select a Class',
                  style: TextStyle(color: Colors.white),
                ),
                dropdownColor: Colors.black,
                iconEnabledColor: Colors.white,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedClass = newValue;
                    selectedSubject = null; // Reset subject selection
                  });
                },
                items: classSubjects.keys.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.0),

              // Dropdown for selecting subject
              DropdownButton<String>(
                value: selectedSubject,
                hint: Text(
                  'Select a Subject',
                  style: TextStyle(color: Colors.white),
                ),
                dropdownColor: Colors.black,
                iconEnabledColor: Colors.white,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                items: selectedClass != null
                    ? classSubjects[selectedClass]!.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList()
                    : [],
              ),
              SizedBox(height: 20.0),

              // Save Button
              ElevatedButton(
                onPressed: (selectedClass != null && selectedSubject != null)
                    ? () async {
                  await _saveSelection();
                  Navigator.pop(context); // Return to the previous page
                }
                    : null, // Disable the button if either selection is null
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSelection() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'class': selectedClass,
          'subject': selectedSubject,
        });
      } catch (e) {
        print('Error saving class and subject: $e');
      }
    }
  }
}
