import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Class_Selection extends StatefulWidget {
  @override
  _Class_SelectionState createState() => _Class_SelectionState();
}

class _Class_SelectionState extends State<Class_Selection> {

  List<String> selectedClasses = [];
  List<String> selectedSubjects = [];
  String? selectedSchool;
  bool isSaved = false;

  // Updated structure to track unavailable subjects by school and class
  Map<String, Map<String, List<String>>> unavailableSubjectsBySchoolAndClass = {};
  String? currentUserEmail;

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

  // Get available subjects based on selected class and school
  List<String> _getAvailableSubjects() {
    if (selectedClasses.isEmpty || selectedSchool == null) {
      return [];
    } else {
      String className = selectedClasses[0];
      List<String> allSubjects = classSubjects[className] ?? [];

      // Filter out unavailable subjects for this school and class
      List<String> unavailableSubjects = [];
      if (unavailableSubjectsBySchoolAndClass.containsKey(selectedSchool)) {
        if (unavailableSubjectsBySchoolAndClass[selectedSchool]!.containsKey(className)) {
          unavailableSubjects = unavailableSubjectsBySchoolAndClass[selectedSchool]![className]!;
        }
      }

      // Remove the unavailable subjects from all subjects, except those selected by the current user
      return allSubjects.where((subject) {
        // If this subject is unavailable but is one of the current user's selections, still show it
        if (unavailableSubjects.contains(subject) && !selectedSubjects.contains(subject)) {
          return false;
        }
        return true;
      }).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUserEmail();
    _fetchUnavailableSubjects();
    _checkSavedSelections();
  }

  // Get the current user's email
  void _getCurrentUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email;
    }
  }

  // Fetch all subjects that are already taken by other teachers
  void _fetchUnavailableSubjects() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Teachers_Details').get();

      // Clear the existing map
      unavailableSubjectsBySchoolAndClass = {};

      for (var doc in querySnapshot.docs) {
        if (doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          String docId = doc.id;

          // Skip the current user's document
          if (docId == currentUserEmail) continue;

          // Check if school, classes and subjects fields exist
          if (data.containsKey('school') &&
              data.containsKey('classes') &&
              data.containsKey('subjects')) {

            String school = data['school'] as String;
            List<String> classes = List<String>.from(data['classes']);
            List<String> subjects = List<String>.from(data['subjects']);

            // For each class and subject combination, mark it as unavailable
            for (var className in classes) {
              for (var subject in subjects) {
                // Initialize nested maps if they don't exist
                if (!unavailableSubjectsBySchoolAndClass.containsKey(school)) {
                  unavailableSubjectsBySchoolAndClass[school] = {};
                }
                if (!unavailableSubjectsBySchoolAndClass[school]!.containsKey(className)) {
                  unavailableSubjectsBySchoolAndClass[school]![className] = [];
                }

                // Add subject to unavailable list
                if (!unavailableSubjectsBySchoolAndClass[school]![className]!.contains(subject)) {
                  unavailableSubjectsBySchoolAndClass[school]![className]!.add(subject);
                }
              }
            }
          }
        }
      }

      // Refresh UI
      setState(() {});

    } catch (e) {
      print('Error fetching unavailable subjects: $e');
    }
  }

  void _checkSavedSelections() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Teachers_Details').doc(userEmail).get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;

        setState(() {
          selectedSchool = data['school'] ?? null;

          if (data.containsKey('classes')) {
            selectedClasses = List<String>.from(data['classes']);
          }

          if (data.containsKey('subjects')) {
            selectedSubjects = List<String>.from(data['subjects']);
            isSaved = true; // Set isSaved to true to indicate that selections are saved
          }
        });
      }
    }
  }

  Future<void> _saveSelection() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showToast("User not authenticated");
      return;
    }

    if (selectedSchool == null) {
      _showToast("Please select a School first");
      return;
    }

    if (selectedClasses.isEmpty) {
      _showToast("Please select a Class first");
      return;
    }

    if (selectedSubjects.isEmpty) {
      _showToast("Please select at least one Subject");
      return;
    }

    String userEmail = user.email!; // Use the user's email as the document ID
    try {
      await FirebaseFirestore.instance.collection('Teachers_Details').doc(userEmail).set({
        'school': selectedSchool,
        'classes': selectedClasses,
        'subjects': selectedSubjects,
      }, SetOptions(merge: true));

      setState(() {
        isSaved = true; // Set isSaved to true to indicate that selections are saved
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

  // Check if a subject is already taken by another teacher
  bool _isSubjectUnavailable(String subject) {
    if (selectedSchool == null || selectedClasses.isEmpty) {
      return false;
    }

    String className = selectedClasses[0];

    // Check if the subject is unavailable for this school and class
    if (unavailableSubjectsBySchoolAndClass.containsKey(selectedSchool)) {
      if (unavailableSubjectsBySchoolAndClass[selectedSchool]!.containsKey(className)) {
        return unavailableSubjectsBySchoolAndClass[selectedSchool]![className]!.contains(subject);
      }
    }

    return false;
  }

  Widget _buildSchoolSelection() {
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
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected School',
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
                selectedSchool ?? "No school selected",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            )
          else
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
                  ? null
                  : (value) {
                setState(() {
                  selectedSchool = value;
                  // Clear class and subject selections when school changes
                  selectedClasses.clear();
                  selectedSubjects.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildClassSelection() {
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
                selectedClasses.join(', '),
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
                  onChanged: (selectedSchool == null || isSaved)
                      ? null
                      : (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (selectedClasses.length < 2) {
                          selectedClasses.add(className);
                          // Clear selected subjects when class changes
                          selectedSubjects.clear();
                        } else {
                          _showToast("You can't select more than 1 class");
                        }
                      } else {
                        selectedClasses.remove(className);
                        // Clear selected subjects when class is deselected
                        selectedSubjects.clear();
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
                selectedSubjects.join(', '),
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            )
          else if (selectedClasses.isEmpty || selectedSchool == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Please select a school and class first',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            )
          else
            ...availableSubjects.map((subject) {
              bool isUnavailable = _isSubjectUnavailable(subject) && !selectedSubjects.contains(subject);
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: CheckboxListTile(
                  title: Row(
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: isUnavailable ? Colors.grey : Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      if (isUnavailable)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(Already assigned)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  value: selectedSubjects.contains(subject),
                  onChanged: (isSaved || isUnavailable)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Selected Class and Subject',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.shade100,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Selection
                  _buildSchoolSelection(),

                  // Class Selection
                  _buildClassSelection(),

                  // Subject Selection
                  _buildSubjectSelection(),

                  // Save Button
                  if (!isSaved)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (selectedSchool != null && selectedClasses.isNotEmpty && selectedSubjects.isNotEmpty)
                            ? _saveSelection
                            : null,
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