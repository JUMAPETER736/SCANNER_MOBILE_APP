import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _Teacher_Home_PageState extends State<Teacher_Home_Page> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String teacherName = 'Teacher'; // Default name
  bool isLoadingName = true;

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        // Fetch teacher name from Firestore
        await getTeacherName(user.email!);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> getTeacherName(String email) async {
    try {
      // Query the Teachers_Details collection for the document with matching email
      QuerySnapshot querySnapshot = await _firestore
          .collection('Schools')
          .doc('Teachers_Details')
          .collection('Teachers_Details')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot teacherDoc = querySnapshot.docs.first;
        String name = teacherDoc.get('name') ?? 'Teacher';
        setState(() {
          teacherName = name.toUpperCase(); // Convert to uppercase
          isLoadingName = false;
        });
      } else {
        // If no document found, keep default name
        setState(() {
          isLoadingName = false;
        });
      }
    } catch (e) {
      print('Error fetching teacher name: $e');
      setState(() {
        isLoadingName = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
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
                  'Welcome',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(14, screenWidth, screenHeight),
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: getResponsiveSize(2, screenWidth, screenHeight)),
                isLoadingName
                    ? SizedBox(
                  width: getResponsiveSize(20, screenWidth, screenHeight),
                  height: getResponsiveSize(20, screenWidth, screenHeight),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                )
                    : Text(
                  teacherName,
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
                    fontWeight: FontWeight.w600,
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
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

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

    return isLandscape
        ? // Landscape layout: Use flexible sizing for scrollable content
    Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(20, screenWidth, screenHeight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: leftActions.map((action) {
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: getResponsiveSize(8, screenWidth, screenHeight),
                        right: getResponsiveSize(4, screenWidth, screenHeight),
                      ),
                      height: getResponsiveSize(80, screenWidth, screenHeight),
                      child: _buildActionCard(action, screenWidth, screenHeight),
                    );
                  }).toList(),
                ),
              ),
              // Right column
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rightActions.map((action) {
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: getResponsiveSize(8, screenWidth, screenHeight),
                        left: getResponsiveSize(4, screenWidth, screenHeight),
                      ),
                      height: getResponsiveSize(80, screenWidth, screenHeight),
                      child: _buildActionCard(action, screenWidth, screenHeight),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: getResponsiveSize(20, screenWidth, screenHeight)), // Extra spacing at bottom
        ],
      ),
    )
        : // Portrait layout: Use Expanded to fill available space without scrolling
    Expanded(
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
        );
      },
    );
  }

  Widget _buildHome(BuildContext context, User? loggedInUser) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    final content = FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildWelcomeSection(),
          _buildQuickActions(),
        ],
      ),
    );

    // In portrait mode: disable scrolling, fit content to screen
    // In landscape mode: enable scrolling for better content visibility
    if (isLandscape) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: content,
        ),
      );
    } else {
      return content;
    }
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
      backgroundColor: const Color(0xFFF8FAFC),
      // Only show AppBar when on Home tab (index 1)
      appBar: _selectedIndex == 1 ? AppBar(
        title: const Text(
          'Teacher Portal',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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