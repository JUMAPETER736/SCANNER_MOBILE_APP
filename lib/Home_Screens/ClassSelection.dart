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
  String? selectedSchool;
  bool isSaved = false;

  List<String> unavailableClasses = [];
  List<String> unavailableSubjects = [];

  // Define the classSubjects in Firestore
  final List<String> schools = [

    'Balaka Secondary School',
    'Bandawe Boys Secondary School',
    'Blantyre Secondary School',
    'Bwaila Secondary School',
    'Chaminade Boys Secondary School',
    'Chayamba Secondary School',
    'Chikwawa Catholic Secondary School',
    'Chikwawa Secondary School',
    'Chilumba Boys Secondary School',
    'Chipasula Secondary School',
    'Chipoka Secondary School',
    'Chiradzulu Secondary School',
    'Chitipa Secondary School',
    'Dedza Boys Secondary School',
    'Dowa Secondary School',
    'Dzenza Secondary School',
    'Ekwendeni Girls Secondary School',
    'Euthini Secondary School',
    'Kasungu Secondary School',
    'Katoto Secondary School',
    'Lilongwe Girls Secondary School',
    'Likoma Secondary School',
    'Likuni Boys Secondary School',
    'Likuni Girls Secondary School',
    'Livingstonia Secondary School',
    'Luchenza Secondary School',
    'Ludzi Girls Secondary School',
    'Madisi Secondary School',
    'Magawa Secondary School',
    'Machinga Secondary School',
    'Mchinji Secondary School',
    'Mayani Secondary School',
    'Mbomba Secondary School',
    'Mitundu Secondary School',
    'Mikoke Secondary School',
    'Mzimba Secondary School',
    'Mzuzu Government Secondary School',
    'Mwanza Catholic Secondary School',
    'Mwanza Secondary School',
    'Namitete Secondary School',
    'Nankhunda Secondary School',
    'Neno Secondary School',
    'Ngabu Secondary School',
    'Nkhamenya Girls Secondary School',
    'Nkhatabay Secondary School',
    'Nkhotakota Secondary School',
    'Ntcheu Secondary School',
    'Ntchisi Boys Secondary School',
    'Our Lady of Wisdom Secondary School',
    'Phalombe Secondary School',
    'Providence Secondary School',
    'Robert Blake Boys Secondary School',
    'Robert Laws Secondary School',
    'Rumphi Boys Secondary School',
    'Salima Secondary School',
    'St. Charles Lwanga Secondary School',
    'St. John Bosco Boys Secondary School',
    'St. Johns Boys Secondary School',
    'St. Kizito Secondary School',
    'St. Mary\'s Secondary School',
    'St. Michael\'s Girls Secondary School',
    'St. Patrick\'s Secondary School',
    'St. Pius XII Seminary',
    'St. Stella Maris Secondary School',
    'Thyolo Secondary School',
    'Umbwi Boys Secondary School',
    'William Murray Boys Secondary School',
    'Zomba Catholic Secondary School',
    'Zomba Urban Secondary School',
  ];

  final List<String> classes = ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'];

  final Map<String, List<String>> classSubjects = {

    'FORM 1':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 2':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 3':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES'],
    'FORM 4':  ['AGRICULTURE', 'BIOLOGY', 'BIBLE KNOWLEDGE', 'COMPUTER SCIENCE', 'CHEMISTRY', 'CHICHEWA', 'ENGLISH', 'LIFE SKILLS', 'MATHEMATICS', 'PHYSICS', 'SOCIAL STUDIES']

  };

  List<String> _getAvailableSubjects() {
    if (selectedClasses.isEmpty) {
      return [];
    } else {
      return classSubjects[selectedClasses[0]] ?? [];
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirestoreData(); // Initialize Firestore data
    _checkSavedSelections();
    _buildClassSelection();
    _buildSubjectSelection();
  }

  void _initializeFirestoreData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Teachers_Details').get();
      List<DocumentSnapshot> documents = querySnapshot.docs;

      for (var doc in documents) {
        // Ensure the fields exist before attempting to access them
        if (doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;

          // Check and update unavailable classes
          if (data.containsKey('classes')) {
            List<String> classes = List<String>.from(data['classes']);
            unavailableClasses.addAll(classes);
          }

          // Check and update unavailable subjects
          if (data.containsKey('subjects')) {
            List<String> subjects = List<String>.from(data['subjects']);
            unavailableSubjects.addAll(subjects);
          }
        }
      }

    } catch (e) {
      print('Error initializing Firestore data: $e');
    }
  }



  Widget _buildClassSelection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Classes', style: TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          if (isSaved)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(selectedClasses.join(', '), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            )
          else
            ...classes.map((className) {
              return Card(
                child: CheckboxListTile(
                  title: Text(className, style: TextStyle(color: Colors.black, fontSize: 18)),
                  value: selectedClasses.contains(className),
                  onChanged: isSaved || unavailableClasses.contains(className)
                      ? null // Disable if already saved or unavailable
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
    );
  }


  Widget _buildSubjectSelection() {
    List<String> availableSubjects = _getAvailableSubjects();
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Subjects', style: TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          if (isSaved)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(selectedSubjects.join(', '), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            )
          else
            ...availableSubjects.map((subject) {
              return Card(
                child: CheckboxListTile(
                  title: Text(subject, style: TextStyle(color: Colors.black, fontSize: 18)),
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
    );
  }



  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Teachers_Details').doc(userEmail).get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;

        selectedSchool = data['school'] ?? null;

        if (data.containsKey('classes')) {
          setState(() {
            selectedClasses = List<String>.from(data['classes']);
          });
        }
        if (data.containsKey('subjects')) {
          setState(() {
            selectedSubjects = List<String>.from(data['subjects']);
            isSaved = true; // Set isSaved to true to indicate that selections are saved.
          });
        }
      }

    }
  }


  Future<void> _saveSelection() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedSchool == null) {
      _showToast("Please select a School first.");
      return;
    }

    if (user == false) {
      print('User is not authenticated.');
      return; // Exit if user is not authenticated.
    }

    String userEmail = user.email!; // Use the user's email as the document ID
    try {
      await FirebaseFirestore.instance.collection('Teachers_Details').doc(userEmail).set({
        'school': selectedSchool,
        'classes': selectedClasses,
        'subjects': selectedSubjects,
      }, SetOptions(merge: true));

      unavailableClasses.addAll(selectedClasses);
      unavailableSubjects.addAll(selectedSubjects);

      setState(() {
        isSaved = true; // Set isSaved to true to indicate that selections are saved.
      });

      // Show the success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selections saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving classes and subjects: $e');

      // Show the error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error in saving selections.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildSchoolSelection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50], // Background color like selected classes and subjects
        borderRadius: BorderRadius.circular(10), // Rounded corners
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
            'Selected School',
            style: TextStyle(
              color: Colors.blueAccent, // Text color similar to selected classes
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isSaved)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                selectedSchool ?? "No school selected", // Display selected school or default message
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            )
          else
          // Dropdown selection for school when not saved
            DropdownButtonFormField<String>(
              value: selectedSchool,
              decoration: InputDecoration(
                labelText: 'Select School',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: schools.map((school) {
                return DropdownMenuItem(
                  value: school,
                  child: Text(school),
                );
              }).toList(),
              onChanged: isSaved
                  ? null // Disable dropdown if already saved
                  : (value) {
                setState(() {
                  selectedSchool = value;
                  isSaved = false; // Allow changes if not saved
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind AppBar
      appBar: AppBar(
        title: Text(
          'Selected Class and Subject',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.withOpacity(0.8), // Transparent AppBar
        elevation: 0, // No shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea( // Ensures content is placed below AppBar
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Selection
                  _buildSchoolSelection(),

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
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
                                onChanged: isSaved
                                    ? null // Disable if already saved
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
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
      ),
    );
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

