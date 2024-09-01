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
    String userId = user.uid; // Get user's ID instead of email
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && doc['classes'] != null && doc['subjects'] != null) {
      setState(() {
        selectedClasses = List<String>.from(doc['classes']);
        selectedSubjects = List<String>.from(doc['subjects']);
        isSaved = true; // Mark as saved
      });
    }
  }
}

Future<void> _saveSelection() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String userId = user.uid; // Use user ID for the document reference
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'classes': selectedClasses,
        'subjects': selectedSubjects,
      }, SetOptions(merge: true)); // Use merge to update existing data
      setState(() {
        isSaved = true; // Mark as saved
      });
      _showToast("Selections saved Successfully!"); // Show success message
    } catch (e) {
      print('Error saving Classes and Subjects: $e');
      _showToast("Error saving Selections."); // Show error message
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
              'Selected Classes',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            if (isSaved) 
              Text(
                selectedClasses.join(', '), // Display saved classes
                style: TextStyle(color: Colors.black, fontSize: 18),
              )
            else 
              ...classSubjects.keys.map((className) {
                return CheckboxListTile(
                  title: Text(
                    className,
                    style: TextStyle(color: Colors.black),
                  ),
                  value: selectedClasses.contains(className),
                  onChanged: (isSaved || selectedClasses.length >= 1 && selectedClasses.contains(className))
                      ? null // Disable if already saved or if it's already selected
                      : (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (selectedClasses.length < 1) {
                          selectedClasses.add(className);
                        } else {
                          _showToast("You can't select more than 1 class");
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
              'Selected Subjects',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            if (isSaved) 
              Text(
                selectedSubjects.join(', '), // Display saved subjects
                style: TextStyle(color: Colors.black, fontSize: 18),
              )
            else 
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
            if (!isSaved) // Show save button only if not saved
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Set button color to blue
                ),
                onPressed: (selectedClasses.isNotEmpty && selectedSubjects.isNotEmpty)
                    ? () async {
                  await _saveSelection();
                }
                    : null, // Disable the button if either selection is null
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.black), // Set text color to black
                ),
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



  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      textColor: Colors.blue,
      fontSize: 16.0,
    );
  }
}
