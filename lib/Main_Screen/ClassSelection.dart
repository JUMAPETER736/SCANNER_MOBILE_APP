import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClassSelection extends StatefulWidget {
  @override
  _ClassSelectionState createState() => _ClassSelectionState();
}

class _ClassSelectionState extends State<ClassSelection> {
  List<String> selectedClasses = [];
  List<String> selectedSubjects = [];
  bool isSaved = false;

  // Define the classSubjects in Firestore
  final List<String> classes = ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'];

  final Map<String, List<String>> classSubjects = {

    'FORM 1':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 2':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 3':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 4':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES']


  };

  @override
  void initState() {
    super.initState();
    _initializeFirestoreData(); // Initialize Firestore data
    _checkSavedSelections();
  }

  // Initialize Firestore with class subjects
  void _initializeFirestoreData() async {
    try {
      for (var className in classes) {
        // Check if the class already exists
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('classSubjects').doc(className).get();
        if (!doc.exists) {
          // If it doesn't exist, create it
          await FirebaseFirestore.instance.collection('classSubjects').doc(className).set({
            'subjects': classSubjects[className],
          });
        }
      }
      print('Firestore initialized with class subjects.');
    } catch (e) {
      print('Error initializing Firestore data: $e');
    }
  }

  // Check saved selections from Firestore
  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid; // Get user's ID
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Teacher').doc(userId).get();
      if (doc.exists && doc['classes'] != null && doc['subjects'] != null) {
        setState(() {
          selectedClasses = List<String>.from(doc['classes']);
          selectedSubjects = List<String>.from(doc['subjects']);
          isSaved = true; // Mark as saved
        });
      }
    }
  }

  // Save selected classes and subjects to Firestore
  Future<void> _saveSelection() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String teacherId = user.uid; // Use user ID for the document reference
      try {
        await FirebaseFirestore.instance.collection('Teacher').doc(teacherId).set({
          'classes': selectedClasses,
          'subjects': selectedSubjects,
        }, SetOptions(merge: true)); // Use merge to update existing data
        setState(() {
          isSaved = true; // Mark as saved
        });
        _showToast("Selections saved Successfully!"); // Show success message
      } catch (e) {
        print('Error saving classes and subjects: $e');
        _showToast("Error saving selections."); // Show error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selected Class and Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView( // Enable scrolling
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Selection
                Container(
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
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Classes',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (isSaved)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            selectedClasses.join(', '), // Display saved classes
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        )
                      else
                        ...classes.map((className) {
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CheckboxListTile(
                              title: Text(
                                className,
                                style: TextStyle(color: Colors.black, fontSize: 18),
                              ),
                              value: selectedClasses.contains(className),
                              onChanged: isSaved ? null // Disable if already saved
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
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),

                // Subject Selection
                Container(
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
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Subjects',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (isSaved)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            selectedSubjects.join(', '), // Display saved subjects
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        )
                      else
                        ..._getAvailableSubjects().map((subject) {
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CheckboxListTile(
                              title: Text(
                                subject,
                                style: TextStyle(color: Colors.black, fontSize: 18),
                              ),
                              value: selectedSubjects.contains(subject),
                              onChanged: isSaved // Disable if already saved
                                  ? null
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
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),

                // Save Button
                if (!isSaved) // Show save button only if not saved
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveSelection,
                      child: Text('Save Selections', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get available subjects based on the selected class
  List<String> _getAvailableSubjects() {
    if (selectedClasses.isEmpty) {
      return [];
    } else {
      return classSubjects[selectedClasses[0]] ?? [];
    }
  }

  // Show a toast message
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
