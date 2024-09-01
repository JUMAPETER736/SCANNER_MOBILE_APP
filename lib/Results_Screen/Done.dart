import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Settings/SettingsPage.dart';
import 'package:scanna/Main_Screen/GradeAnalytics.dart';
import 'package:scanna/Main_Screen/ClassSelection.dart';
import 'package:scanna/Main_Screen/StudentDetails.dart'; // Import the StudentDetails
import 'package:scanna/Main_Screen/Help.dart'; // Import the Help class
import 'package:scanna/Home_Screens/LoginPage.dart'; // Import your LoginPage

User? loggedInUser;

class Done extends StatefulWidget {
  static String id = '/Done';

  @override
  _DoneState createState() => _DoneState();
}

class _DoneState extends State<Done> {
  final _auth = FirebaseAuth.instance;
  int _selectedIndex = 0; // Track the selected index for bottom navigation

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      await _auth.signOut();
      // Navigate to the login page after logging out
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildHome() {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.0), // Add padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Message
            Text(
              'Welcome, ${loggedInUser?.displayName ?? 'User'}!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 40.0), // Spacing before buttons

            // Button for Class Selection
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassSelection(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                color: Colors.blueAccent, // Button color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Adjusted padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 30, color: Colors.white), // Adjusted icon size
                      SizedBox(width: 10),
                      Text(
                        'Select Class',
                        style: TextStyle(fontSize: 18.0, color: Colors.white), // Adjusted text size and color
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0), // Spacing between buttons

            // Button for Viewing Grade Analytics
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeAnalytics(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                color: Colors.greenAccent, // Button color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Adjusted padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 30, color: Colors.white), // Adjusted icon size
                      SizedBox(width: 10),
                      Text(
                        'View Grade Analytics',
                        style: TextStyle(fontSize: 18.0, color: Colors.white), // Adjusted text size and color
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0), // Spacing between buttons

            // Button for Entering Student Details
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetails(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                color: Colors.orangeAccent, // Button color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Adjusted padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 30, color: Colors.white), // Adjusted icon size
                      SizedBox(width: 10),
                      Text(
                        'Enter Student Details',
                        style: TextStyle(fontSize: 18.0, color: Colors.white), // Adjusted text size and color
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildHelp() {
      return Help(); // Directly using the Help widget
    }

    Widget _buildSettings() {
      // Pass the loggedInUser to the SettingsPage
      return SettingsPage(user: loggedInUser!); // Pass loggedInUser
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Scanna Dashboard'),
        backgroundColor: Colors.teal, // AppBar color
        automaticallyImplyLeading: false, // This removes the back arrow
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout, // Log out when pressed
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHelp() 
          : _selectedIndex == 1 
              ? _buildHome() 
              : _buildSettings(), // Added Settings page logic

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // Settings icon
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.teal, 
        selectedItemColor: Colors.white, 
        unselectedItemColor: Colors.white54, 
      ),
    );
  }
}
