import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/Main_Settings.dart';
import 'package:scanna/Home_Screens/Grade_Analytics.dart';
import 'package:scanna/Home_Screens/Class_Selection.dart';
import 'package:scanna/Students_Information/Student_Details.dart';
import 'package:scanna/Home_Screens/Help.dart';
import 'package:scanna/Students_Information/Student_Name_List.dart';
import 'package:scanna/Home_Screens/QR_Code_Scan.dart';
import 'package:scanna/Home_Screens/Results_And_%20School_Reports.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Home_Screens/Performance_Statistics.dart';
import 'package:scanna/Home_Screens/School_Reports_PDF_List.dart';

User? loggedInUser;

class Main_Home extends StatefulWidget {
  static String id = '/Main';

  @override
  _Main_HomeState createState() => _Main_HomeState();
}

class _Main_HomeState extends State<Main_Home> {
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

  Widget _buildHome(BuildContext context, User? loggedInUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen orientation
        final orientation = MediaQuery.of(context).orientation;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Determine grid layout based on orientation
        int crossAxisCount;
        double childAspectRatio;
        bool enableScrolling;

        if (orientation == Orientation.portrait) {
          // Portrait: 2 columns
          crossAxisCount = 2;
          childAspectRatio = 1.1; // Slightly wider than square
          enableScrolling = false; // Disable scrolling in portrait if content fits
        } else {
          // Landscape: 4 columns
          crossAxisCount = 4;
          childAspectRatio = 0.9; // Slightly taller than square
          enableScrolling = true; // Enable scrolling in landscape
        }

        // Calculate responsive dimensions
        final horizontalPadding = screenWidth * 0.03;
        final verticalPadding = screenHeight * 0.015;
        final cardSpacing = screenWidth * 0.02;

        // Calculate responsive sizes
        final iconSize = orientation == Orientation.portrait
            ? (screenWidth * 0.06).clamp(20.0, 35.0)
            : (screenWidth * 0.045).clamp(25.0, 35.0);
        final textSize = orientation == Orientation.portrait
            ? (screenWidth * 0.028).clamp(10.0, 14.0)
            : (screenWidth * 0.022).clamp(10.0, 13.0);

        // Build the grid widget
        Widget gridWidget = GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: cardSpacing,
          mainAxisSpacing: cardSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: !enableScrolling, // Shrink when scrolling is disabled
          physics: enableScrolling
              ? const AlwaysScrollableScrollPhysics() // Enable scrolling
              : const NeverScrollableScrollPhysics(), // Disable scrolling
          children: [
            _buildHomeCard(
              icon: Icons.class_,
              text: 'Select School & Class',
              color: Colors.blueAccent,
              iconSize: iconSize,
              textSize: textSize,
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
              iconSize: iconSize,
              textSize: textSize,
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
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Student_Details()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.qr_code_scanner,
              text: 'QR Scan',
              color: const Color.fromARGB(255, 59, 61, 60),
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QR_Code_Scan()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.school,
              text: 'Results',
              color: Colors.redAccent,
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Results_And_School_Reports()),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.list,
              text: 'Students Names',
              color: Colors.purpleAccent,
              iconSize: iconSize,
              textSize: textSize,
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
              iconSize: iconSize,
              textSize: textSize,
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
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => School_Reports_PDF_List()),
                );
              },
            ),
          ],
        );

        // Return the grid with proper padding
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: enableScrolling
              ? SingleChildScrollView(child: gridWidget) // Wrap with ScrollView when needed
              : gridWidget,
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
          padding: const EdgeInsets.all(8.0),
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
              const SizedBox(height: 4),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
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