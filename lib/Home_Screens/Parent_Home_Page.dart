import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Parent_Screens/Student_Details_View.dart';
import 'package:scanna/Parent_Screens/Available_School_Events.dart';
import 'package:scanna/Parent_Screens/Student_Results.dart';
import 'package:scanna/Parent_Screens/School_Fees_Structure_And_Balance.dart';

User? loggedInUser;

class Parent_Home_Page extends StatefulWidget {
  static String id = '/ParentMain';

  @override
  _Parent_Home_PageState createState() => _Parent_Home_PageState();
}

class _Parent_Home_PageState extends State<Parent_Home_Page> {
  final _auth = FirebaseAuth.instance;

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
          // Portrait: 2 columns with adjusted aspect ratio to fit all cards
          crossAxisCount = 2;
          enableScrolling = false; // No scrolling in portrait
          // Calculate aspect ratio to fit all 4 cards (2 rows) on screen with buffer
          final availableHeight = screenHeight - (screenHeight * 0.1); // Account for padding and buffer
          final cardHeight = availableHeight / 2.5; // 2 rows with extra spacing
          final cardWidth = (screenWidth - (screenWidth * 0.08) - (screenWidth * 0.025)) / 2; // Account for padding and spacing
          childAspectRatio = cardWidth / cardHeight;
        } else {
          // Landscape: 4 columns for better space utilization
          crossAxisCount = 4;
          enableScrolling = false; // No need to scroll with only 4 cards
          childAspectRatio = 0.8; // Slightly taller cards
        }

        // Calculate responsive dimensions
        final horizontalPadding = screenWidth * 0.04; // Horizontal padding
        final verticalPadding = screenHeight * 0.03; // Vertical padding
        final cardSpacing = screenWidth * 0.025; // Card spacing

        // Calculate responsive sizes
        final iconSize = orientation == Orientation.portrait
            ? (screenWidth * 0.08).clamp(24.0, 48.0) // Larger icons for parent view
            : (screenWidth * 0.06).clamp(30.0, 50.0);
        final textSize = orientation == Orientation.portrait
            ? (screenWidth * 0.035).clamp(12.0, 16.0) // Larger text for parent view
            : (screenWidth * 0.03).clamp(12.0, 18.0);

        // Build the grid widget
        Widget gridWidget = GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: cardSpacing,
          mainAxisSpacing: cardSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: !enableScrolling, // Shrink when scrolling is disabled
          physics: enableScrolling
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: [
            _buildHomeCard(
              icon: Icons.person,
              text: 'Student Details',
              color: Colors.blueAccent,
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Student_Details_View(
                      schoolName: "School Name Here",
                      studentClass: "Class Name Here",
                      studentFullName: "Student Full Name Here",
                    ),
                  ),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.event,
              text: 'Events',
              color: Colors.greenAccent,
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Available_School_Events(
                      schoolName: 'schoolName',
                      selectedClass: 'className',
                    ),
                  ),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.assessment,
              text: 'Results',
              color: Colors.orangeAccent,
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Student_Results(
                      studentFullName: 'studentFullName')),
                );
              },
            ),
            _buildHomeCard(
              icon: Icons.account_balance_wallet,
              text: 'Fees Structure',
              color: Colors.purpleAccent,
              iconSize: iconSize,
              textSize: textSize,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => School_Fees_Structure_And_Balance()),
                // );
              },
            ),
          ],
        );

        // Return the grid with proper padding and centering
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: gridWidget,
          ),
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
              const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parent Portal',
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
      ),
      body: SizedBox.expand(
        child: _buildHome(context, loggedInUser),
      ),
    );
  }
}