import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import the toast package

class ClassSelection extends StatefulWidget {
  @override
  _ClassSelectionState createState() => _ClassSelectionState();
}

class _ClassSelectionState extends State<ClassSelection> {
  List<String> selectedClasses = []; // List to hold selected classes
  List<String> selectedSubjects = []; // List to hold selected subjects
  bool isSaved = false; // Track if the selection is saved

  final Map<String, List<String>> classSubjects = {
    'FORM 1': ['MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 2': ['CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 3': ['MATHEMATICS', 'BIBLE KNOWLEDGE', 'AGRICULTURE', 'ENGLISH', 'BIOLOGY', 'CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    'FORM 4': ['CHEMISTRY', 'CHICHEWA', 'PHYSICS', 'BIBLE KNOWLEDGE', 'MATHEMATICS', 'ENGLISH', 'BIOLOGY', 'AGRICULTURE', 'LIFE SKILLS', 'SOCIAL STUDIES'],
    // Add more classes and their corresponding subjects as needed
  };

  @override
  void initState() {
    super.initState();
    _checkSavedSelections();
  }

  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc['classes'] != null && doc['subjects'] != null) {
        setState(() {
          selectedClasses = List<String>.from(doc['classes']);
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
        title: Text('Select Class and Subject'),
      ),
      body: SingleChildScrollView( // Enable scrolling
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Class Selection
            Text(
              'Select Classes (Max 2)',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            ...classSubjects.keys.map((className) {
              return CheckboxListTile(
                title: Text(
                  className,
                  style: TextStyle(color: Colors.black),
                ),
                value: selectedClasses.contains(className),
                onChanged: isSaved
                    ? null // Disable if already saved
                    : (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (selectedClasses.length < 2) {
                        selectedClasses.add(className);
                      } else {
                        _showToast("You can't select more than 2 classes");
                      }
                    } else {
                      selectedClasses.remove(className);
                    }
                  });
                },
                activeColor: Colors.blue,
                checkColor: Colors.white,
              );
            }).toList(),
            SizedBox(height: 20.0),

            // Subject Selection
            Text(
              'Select Subjects (Max 2)',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            ..._getAvailableSubjects().map((subject) {
              return CheckboxListTile(
                title: Text(
                  subject,
                  style: TextStyle(color: Colors.black),
                ),
                value: selectedSubjects.contains(subject),
                onChanged: isSaved
                    ? null // Disable if already saved
                    : (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (selectedSubjects.length < 2) {
                        selectedSubjects.add(subject);
                      } else {
                        _showToast("You can't select more than 2 subjects");
                      }
                    } else {
                      selectedSubjects.remove(subject);
                    }
                  });
                },
                activeColor: Colors.blue,
                checkColor: Colors.white,
              );
            }).toList(),
            SizedBox(height: 20.0),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Change button color here
              ),
              onPressed: (selectedClasses.isNotEmpty && selectedSubjects.isNotEmpty && !isSaved)
                  ? () async {
                await _saveSelection();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassSubjectConfirmation(
                      selectedClasses: selectedClasses,
                      selectedSubjects: selectedSubjects,
                      classSubjects: classSubjects, // Pass classSubjects here
                    ),
                  ),
                );
              }
                  : null, // Disable the button if either selection is null or if already saved
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableSubjects() {
    // Get subjects based on selected classes
    Set<String> availableSubjects = {};
    for (var className in selectedClasses) {
      availableSubjects.addAll(classSubjects[className]!);
    }
    return availableSubjects.toList();
  }

  Future<void> _saveSelection() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'classes': selectedClasses,
          'subjects': selectedSubjects,
        });
        setState(() {
          isSaved = true; // Mark as saved
        });
      } catch (e) {
        print('Error saving classes and subjects: $e');
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

class ClassSubjectConfirmation extends StatelessWidget {
  final List<String> selectedClasses;
  final List<String> selectedSubjects;
  final Map<String, List<String>> classSubjects; // Add classSubjects parameter

  ClassSubjectConfirmation({
    required this.selectedClasses,
    required this.selectedSubjects,
    required this.classSubjects, // Accept it in the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your selection has been saved!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Display each class with its subjects
              ...selectedClasses.map((className) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class: $className',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Subjects: ${selectedSubjects.where((subject) => classSubjects[className]?.contains(subject) ?? false).join(', ')}',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 10),
                  ],
                );
              }).toList(),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Return to the previous page
                },
                child: Text('Back to Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
