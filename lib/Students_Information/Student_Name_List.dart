import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Students_Information/Student_Subjects.dart';
import 'dart:async';

class Student_Name_List extends StatefulWidget {
  final User? loggedInUser;

  const Student_Name_List({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _Student_Name_ListState createState() => _Student_Name_ListState();
}

class _Student_Name_ListState extends State<Student_Name_List> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  String? teacherSchool;
  List<String>? teacherClasses;
  String? selectedClass;
  bool _hasSelectedCriteria = false;
  bool _noSearchResults = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkTeacherSelection();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds when not searching
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_searchQuery.isEmpty && mounted) {
        setState(() {
          // This will trigger a rebuild and refresh the StreamBuilder
        });
      }
    });
  }

  void _checkTeacherSelection() async {
    if (widget.loggedInUser != null) {
      var teacherSnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(widget.loggedInUser!.email)
          .get();

      if (teacherSnapshot.exists) {
        var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
        var school = teacherData['school'];
        var classes = teacherData['classes'] as List<dynamic>? ?? [];

        if (school != null && classes.isNotEmpty) {
          setState(() {
            teacherSchool = school;
            teacherClasses = List<String>.from(classes);
            selectedClass = classes[0];
            _hasSelectedCriteria = true;
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
        title: _hasSelectedCriteria
            ? Text(
          '$teacherSchool',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Name of Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: _hasSelectedCriteria
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
        child: _hasSelectedCriteria
            ? Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: (teacherClasses ?? []).map((classItem) {
                  final isSelected = classItem == selectedClass;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedClass = classItem;
                          _searchQuery = '';
                          _noSearchResults = false;
                          _searchController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.grey[300],
                        foregroundColor:
                        isSelected ? Colors.white : Colors.black,
                      ),
                      child: Text(
                        classItem,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Searching for: "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _noSearchResults = false;
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Schools')
                    .doc(teacherSchool)
                    .collection('Classes')
                    .doc(selectedClass)
                    .collection('Student_Details')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No Student Found.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  var studentDocs = snapshot.data!.docs;
                  List<Widget> studentCards = [];
                  List<Widget> filteredStudentCards = [];

                  for (int index = 0; index < studentDocs.length; index++) {
                    var studentDoc = studentDocs[index];
                    var registeredInformationDocRef =
                    studentDoc.reference
                        .collection('Personal_Information')
                        .doc('Registered_Information');

                    studentCards.add(
                      FutureBuilder<DocumentSnapshot>(
                        future: registeredInformationDocRef.get(),
                        builder: (context, futureSnapshot) {
                          if (!futureSnapshot.hasData ||
                              !futureSnapshot.data!.exists) {
                            return SizedBox.shrink();
                          }

                          var data = futureSnapshot.data!.data()
                          as Map<String, dynamic>;
                          var firstName = data['firstName'] ?? 'N/A';
                          var lastName = data['lastName'] ?? 'N/A';
                          var studentGender =
                              data['studentGender'] ?? 'N/A';
                          var fullName = '$lastName $firstName';

                          // Check if student matches search query
                          bool matchesSearch = _searchQuery.isEmpty ||
                              fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              lastName.toLowerCase().contains(_searchQuery.toLowerCase());

                          if (!matchesSearch) {
                            return SizedBox.shrink();
                          }

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                                vertical: 4.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 12.0),
                              leading: Text(
                                '${index + 1}.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              title: Text(
                                fullName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              subtitle: Text(
                                'Gender: $studentGender',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward,
                                  color: Colors.blueAccent),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Student_Subjects(
                                          studentName: fullName,
                                          studentClass: selectedClass!,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }

                  // Create a future that resolves when all FutureBuilders are done
                  return FutureBuilder<List<Widget>>(
                    future: _buildFilteredList(studentCards),
                    builder: (context, filteredSnapshot) {
                      if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var filteredCards = filteredSnapshot.data ?? [];

                      // Check if search query exists and no results found
                      if (_searchQuery.isNotEmpty && filteredCards.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Student Not Found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No student matches "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _noSearchResults = false;
                                  });
                                },
                                child: Text('Clear Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            // Trigger rebuild
                          });
                        },
                        child: ListView.separated(
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: filteredCards.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            return filteredCards[index];
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        )
            : Center(
          child: Text(
            'Please select Class First',
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

  Future<List<Widget>> _buildFilteredList(List<Widget> studentCards) async {
    // Wait for all FutureBuilders to complete and filter out empty widgets
    List<Widget> filteredCards = [];

    for (Widget card in studentCards) {
      if (card is FutureBuilder<DocumentSnapshot>) {
        // We need to check if this card should be displayed
        // Since we can't easily await the FutureBuilder here,
        // we'll let the FutureBuilder handle the filtering
        filteredCards.add(card);
      }
    }

    return filteredCards;
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Search Student',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                cursorColor: Colors.blueAccent, // Set cursor color to blue
                decoration: InputDecoration(
                  hintText: 'Enter first or last name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent), // Default border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent), // Blue border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2), // Thicker blue border when focused
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _searchController.clear();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _searchQuery = _searchController.text.trim();
                  _noSearchResults = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Search',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}