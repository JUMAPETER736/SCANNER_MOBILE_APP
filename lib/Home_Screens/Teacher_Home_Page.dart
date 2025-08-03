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

<<<<<<< HEAD
class _Teacher_Home_PageState extends State<Teacher_Home_Page> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  int _selectedIndex = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
=======
class _Teacher_Home_PageState extends State<Teacher_Home_Page> {
  final _auth = FirebaseAuth.instance;
  int _selectedIndex = 1;
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0

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
<<<<<<< HEAD
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
=======
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
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

<<<<<<< HEAD
  // Helper method to get responsive text size
  double getResponsiveTextSize(double baseSize, double screenWidth, double screenHeight) {
    // Calculate scale factor based on both width and height
    double widthScale = screenWidth / 375; // Base width (iPhone 6/7/8)
    double heightScale = screenHeight / 667; // Base height (iPhone 6/7/8)
    double scale = (widthScale + heightScale) / 2;

    // Apply constraints to prevent text from being too small or too large
    scale = scale.clamp(0.8, 2.0);

    return baseSize * scale;
  }

  // Helper method to get responsive padding/margin
  double getResponsiveSize(double baseSize, double screenWidth, double screenHeight) {
    double widthScale = screenWidth / 375;
    double heightScale = screenHeight / 667;
    double scale = (widthScale + heightScale) / 2;

    scale = scale.clamp(0.7, 1.8);

    return baseSize * scale;
  }

  Widget _buildWelcomeSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(20, screenWidth, screenHeight),
        vertical: getResponsiveSize(12, screenWidth, screenHeight),
      ),
      child: Row(
        children: [
          Container(
            width: getResponsiveSize(50, screenWidth, screenHeight),
            height: getResponsiveSize(50, screenWidth, screenHeight),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                getResponsiveSize(25, screenWidth, screenHeight),
              ),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: getResponsiveSize(25, screenWidth, screenHeight),
            ),
          ),
          SizedBox(width: getResponsiveSize(15, screenWidth, screenHeight)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, Teacher!',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(14, screenWidth, screenHeight),
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: getResponsiveSize(2, screenWidth, screenHeight)),
                Text(
                  loggedInUser?.email?.split('@')[0] ?? 'Teacher',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
                    fontWeight: FontWeight.w400,
                    color: Colors.blueAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final leftActions = [
      {
        'icon': Icons.class_,
        'title': 'Select School',
        'subtitle': 'Choose your class',
        'color': Colors.blueAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Class_Selection()),
          );
        },
      },
      {
        'icon': Icons.analytics,
        'title': 'Grade Analytics',
        'subtitle': 'View grade trends',
        'color': Colors.greenAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Grade_Analytics()),
          );
        },
      },
      {
        'icon': Icons.person_add,
        'title': 'Add Student',
        'subtitle': 'Register new student',
        'color': Colors.orangeAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Student_Details()),
          );
        },
      },
      {
        'icon': Icons.event,
        'title': 'School Events',
        'subtitle': 'Manage events',
        'color': const Color.fromARGB(255, 59, 61, 60),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Create_Upcoming_School_Event(
              schoolName: 'schoolName',
              selectedClass: 'selectedClass',
            )),
          );
        },
      },
    ];

    final rightActions = [
      {
        'icon': Icons.school,
        'title': 'Results',
        'subtitle': 'Student results',
        'color': Colors.redAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Results_And_School_Reports()),
          );
        },
      },
      {
        'icon': Icons.list,
        'title': 'Class List',
        'subtitle': 'View all students',
        'color': Colors.purpleAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Student_Name_List(loggedInUser: loggedInUser),
            ),
          );
        },
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Statistics',
        'subtitle': 'Performance data',
        'color': Colors.tealAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Performance_Statistics()),
          );
        },
      },
      {
        'icon': Icons.picture_as_pdf,
        'title': ' Report PDFs',
        'subtitle': 'List of Reports',
        'color': Colors.deepOrangeAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => School_Reports_PDF_List()),
          );
        },
      },
    ];

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: getResponsiveSize(20, screenWidth, screenHeight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF667eea),
              ),
            ),
            SizedBox(height: getResponsiveSize(8, screenWidth, screenHeight)),
            Expanded(
              child: Row(
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: leftActions.map((action) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: getResponsiveSize(6, screenWidth, screenHeight),
                              right: getResponsiveSize(3, screenWidth, screenHeight),
                            ),
                            child: _buildActionCard(action, screenWidth, screenHeight),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Right column
                  Expanded(
                    child: Column(
                      children: rightActions.map((action) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: getResponsiveSize(6, screenWidth, screenHeight),
                              left: getResponsiveSize(3, screenWidth, screenHeight),
                            ),
                            child: _buildActionCard(action, screenWidth, screenHeight),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(
                  getResponsiveSize(12, screenWidth, screenHeight),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(
                    getResponsiveSize(12, screenWidth, screenHeight),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      getResponsiveSize(12, screenWidth, screenHeight),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: getResponsiveSize(8, screenWidth, screenHeight),
                        offset: Offset(0, getResponsiveSize(2, screenWidth, screenHeight)),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: getResponsiveSize(40, screenWidth, screenHeight),
                        height: getResponsiveSize(40, screenWidth, screenHeight),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            getResponsiveSize(10, screenWidth, screenHeight),
                          ),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: getResponsiveSize(20, screenWidth, screenHeight),
                        ),
                      ),
                      SizedBox(width: getResponsiveSize(12, screenWidth, screenHeight)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              action['title'] as String,
                              style: TextStyle(
                                fontSize: getResponsiveTextSize(14, screenWidth, screenHeight),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: getResponsiveSize(2, screenWidth, screenHeight)),
                            Text(
                              action['subtitle'] as String,
                              style: TextStyle(
                                fontSize: getResponsiveTextSize(12, screenWidth, screenHeight),
                                color: const Color(0xFF667eea),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
=======
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
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
        );
      },
    );
  }

<<<<<<< HEAD
  Widget _buildHome(BuildContext context, User? loggedInUser) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildWelcomeSection(),
          _buildQuickActions(),
        ],
=======
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
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
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
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF8FAFC),
      // Only show AppBar when on Home tab (index 1)
      appBar: _selectedIndex == 1 ? AppBar(
        title: const Text(
          'Teacher Portal',
          style: TextStyle(
            color: Colors.white,
=======
      // Only show AppBar when on Home tab (index 1)
      appBar: _selectedIndex == 1 ? AppBar(
        title: const Text(
          'Scanna',
          style: TextStyle(

            color: Colors.black,
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.logout, color: Colors.white),
=======
            icon: const Icon(Icons.logout, color: Colors.black),
>>>>>>> 85f7c1bc238d4c9527f736cfbb93398ae2c223e0
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