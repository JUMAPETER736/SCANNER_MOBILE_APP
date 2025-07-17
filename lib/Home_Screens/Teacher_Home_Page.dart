import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/Main_Settings.dart';
import 'package:scanna/Home_Screens/Grade_Analytics.dart';
import 'package:scanna/Home_Screens/Class_Selection.dart';
import 'package:scanna/Students_Information/Student_Details.dart';
import 'package:scanna/Home_Screens/Help.dart';
import 'package:scanna/Students_Information/Student_Name_List.dart';
import 'package:scanna/Home_Screens/Create_Upcoming_School_Event.dart';
import 'package:scanna/Home_Screens/Results_And_School_Reports.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Home_Screens/Performance_Statistics.dart';
import 'package:scanna/Home_Screens/School_Reports_PDF_List.dart';

User? loggedInUser;

class Teacher_Home_Page extends StatefulWidget {
  static String id = '/Teacher_Main_Home_Page';

  @override
  _Teacher_Home_PageState createState() => _Teacher_Home_PageState();
}

class _Teacher_Home_PageState extends State<Teacher_Home_Page> {
  final _auth = FirebaseAuth.instance;
  int _selectedIndex = 1;

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
      Navigator.pushNamedAndRemoveUntil(context, Login_Page.id, (route) => false);
    } catch (e) {
      print(e);
    }
  }

  // Helper function to calculate adaptive text size based on screen dimensions
  double _calculateAdaptiveTextSize(double screenWidth, double screenHeight, bool isPortrait) {
    // Base text size calculation using both width and height
    double baseSize = (screenWidth + screenHeight) / 2 * 0.02;

    // Apply orientation-specific multipliers
    if (isPortrait) {
      // Portrait: slightly smaller text to fit more content
      baseSize *= 0.85;
    } else {
      // Landscape: can afford slightly larger text
      baseSize *= 1.0;
    }

    // Clamp to reasonable bounds
    return baseSize.clamp(10.0, 18.0);
  }

  // Helper function to calculate adaptive icon size
  double _calculateAdaptiveIconSize(double screenWidth, double screenHeight, bool isPortrait) {
    // Base icon size calculation using both width and height
    double baseSize = (screenWidth + screenHeight) / 2 * 0.04;

    // Apply orientation-specific multipliers
    if (isPortrait) {
      baseSize *= 0.8;
    } else {
      baseSize *= 1.1;
    }

    // Clamp to reasonable bounds
    return baseSize.clamp(20.0, 45.0);
  }

  // Helper function to calculate adaptive padding
  double _calculateAdaptivePadding(double screenDimension) {
    return (screenDimension * 0.02).clamp(8.0, 16.0);
  }

  Widget _buildHome(BuildContext context, User? loggedInUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen orientation and dimensions
        final orientation = MediaQuery.of(context).orientation;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isPortrait = orientation == Orientation.portrait;

        // Calculate adaptive sizes
        final adaptiveTextSize = _calculateAdaptiveTextSize(screenWidth, screenHeight, isPortrait);
        final adaptiveIconSize = _calculateAdaptiveIconSize(screenWidth, screenHeight, isPortrait);
        final adaptivePadding = _calculateAdaptivePadding(screenWidth);

        // Determine grid layout based on orientation
        int crossAxisCount;
        double childAspectRatio;
        bool enableScrolling;

        if (isPortrait) {
          // Portrait: 2 columns with adjusted aspect ratio to fit all cards
          crossAxisCount = 2;
          enableScrolling = false; // No scrolling in portrait
          // Calculate aspect ratio to fit all 8 cards (4 rows) on screen with buffer
          final availableHeight = screenHeight - (screenHeight * 0.08);
          final cardHeight = availableHeight / 4.2;
          final cardWidth = (screenWidth - (screenWidth * 0.08) - (screenWidth * 0.025)) / 2;
          childAspectRatio = cardWidth / cardHeight;
        } else {
          // Landscape: 4 columns for better space utilization
          crossAxisCount = 4;
          enableScrolling = true; // Enable scrolling in landscape
          childAspectRatio = 0.8; // Slightly taller cards
        }

        // Calculate responsive spacing
        final cardSpacing = (screenWidth * 0.02).clamp(8.0, 16.0);

        // Build the grid widget
        Widget gridWidget = GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: cardSpacing,
          mainAxisSpacing: cardSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: !enableScrolling,
          physics: enableScrolling
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: [
            _buildHomeCard(
              icon: Icons.class_,
              text: 'Select School & Class',
              color: Colors.blueAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Class_Selection()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.analytics,
              text: 'Grade Analytics',
              color: Colors.greenAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Grade_Analytics()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.person_add,
              text: 'Add Student',
              color: Colors.orangeAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Student_Details()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.event,
              text: 'School Events',
              color: const Color.fromARGB(255, 59, 61, 60),
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Create_Upcoming_School_Event(
                    schoolName: 'schoolName',
                    selectedClass: 'selectedClass',
                  )),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.school,
              text: 'Results',
              color: Colors.redAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Results_And_School_Reports()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.list,
              text: 'Class List',
              color: Colors.purpleAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Student_Name_List(loggedInUser: loggedInUser),
                  ),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.bar_chart,
              text: 'Statistics',
              color: Colors.tealAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Performance_Statistics()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.picture_as_pdf,
              text: 'School Reports PDFs',
              color: Colors.deepOrangeAccent,
              iconSize: adaptiveIconSize,
              textSize: adaptiveTextSize,
              padding: adaptivePadding,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => School_Reports_PDF_List()),
                );
              },
            ),
          ],
        );

        // Return the grid with adaptive padding
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: adaptivePadding,
            vertical: adaptivePadding * 0.75,
          ),
          child: gridWidget,
        );
      },
    );
  }

  Widget _buildHomeCard({
    required IconData icon,
    required String text,
    required Color color,
    required double iconSize,
    required double textSize,
    required double padding,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: EdgeInsets.all(padding * 0.5), // Adaptive padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: padding * 0.2), // Adaptive spacing
              Flexible(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding * 0.25),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1, // Adaptive line height
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelp() {
    return Help();
  }

  Widget _buildSettings() {
    return Main_Settings(user: loggedInUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show AppBar when on Home tab (index 1)
      appBar: _selectedIndex == 1 ? AppBar(
        title: const Text(
          'Scanna',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ) : null,
      body: SizedBox.expand(
        child: _selectedIndex == 0
            ? _buildHelp()
            : _selectedIndex == 1
            ? _buildHome(context, loggedInUser)
            : _buildSettings(),
      ),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}