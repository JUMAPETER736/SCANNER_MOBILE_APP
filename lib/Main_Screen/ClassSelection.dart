import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          child: SingleChildScrollView( // Enable scrolling
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Class Selection
                Text(
                  'Select Classes (Max 2)',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                ...classSubjects.keys.map((className) {
                  return CheckboxListTile(
                    title: Text(
                      className,
                      style: TextStyle(color: Colors.white),
                    ),
                    value: selectedClasses.contains(className),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (selectedClasses.length < 2) {
                            selectedClasses.add(className);
                          }
                        } else {
                          selectedClasses.remove(className);
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  );
                }).toList(),
                SizedBox(height: 20.0),

                // Subject Selection
                Text(
                  'Select Subjects (Max 2)',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                ..._getAvailableSubjects().map((subject) {
                  return CheckboxListTile(
                    title: Text(
                      subject,
                      style: TextStyle(color: Colors.white),
                    ),
                    value: selectedSubjects.contains(subject),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (selectedSubjects.length < 2) {
                            selectedSubjects.add(subject);
                          }
                        } else {
                          selectedSubjects.remove(subject);
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  );
                }).toList(),
                SizedBox(height: 20.0),

                // Save Button
                ElevatedButton(
                  onPressed: (selectedClasses.isNotEmpty && selectedSubjects.isNotEmpty && !isSaved)
                      ? () async {
                    await _saveSelection();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassSubjectConfirmation(
                          selectedClasses: selectedClasses,
                          selectedSubjects: selectedSubjects,
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
}

class ClassSubjectConfirmation extends StatelessWidget {
  final List<String> selectedClasses;
  final List<String> selectedSubjects;

  ClassSubjectConfirmation({required this.selectedClasses, required this.selectedSubjects});

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
              Text(
                'Classes: ${selectedClasses.join(', ')}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Text(
                'Subjects: ${selectedSubjects.join(', ')}',
                style: TextStyle(fontSize: 20),
              ),
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
