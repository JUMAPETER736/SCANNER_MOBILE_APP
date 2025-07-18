import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Parent_Screens/Student_Details_View.dart';
import 'package:scanna/Parent_Screens/Available_School_Events.dart';
import 'package:scanna/Parent_Screens/Student_Results.dart';
import 'package:scanna/Parent_Screens/School_Fees_Structure_And_Balance.dart';
import 'package:scanna/Parent_Screens/Student_Behavior.dart';

User? loggedInUser;

class Parent_Home_Page extends StatefulWidget {
  static String id = '/Parent_Main_Home_Page';

  @override
  _Parent_Home_PageState createState() => _Parent_Home_PageState();
}

class _Parent_Home_PageState extends State<Parent_Home_Page> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
              Icons.person,
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
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(14, screenWidth, screenHeight),
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: getResponsiveSize(2, screenWidth, screenHeight)),
                Text(
                  loggedInUser?.email?.split('@')[0] ?? 'Parent',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
                    fontWeight: FontWeight.bold,
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

    final actions = [
      {
        'icon': Icons.person_outline,
        'title': 'Student Details',
        'subtitle': 'View profile & info',
        'color': const Color(0xFF4F46E5),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Student_Details_View(
                schoolName: 'schoolName',
                className: 'className',
                studentClass: 'studentClass',
                studentName: 'StudentName',
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.event_note_outlined,
        'title': 'Events',
        'subtitle': 'Upcoming activities',
        'color': const Color(0xFF059669),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Available_School_Events(
                schoolName: 'schoolName',
                className: 'className',
                studentClass: 'studentClass',
                studentName: 'StudentName',
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.assessment_outlined,
        'title': 'Results',
        'subtitle': 'Academic performance',
        'color': const Color(0xFFEA580C),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Student_Results(
                schoolName: 'schoolName',
                className: 'className',
                studentClass: 'studentClass',
                studentName: 'StudentName',
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Behavior',
        'subtitle': 'Conduct & discipline',
        'color': const Color(0xFFDC2626),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Student_Behavior(
                schoolName: 'schoolName',
                className: 'className',
                studentClass: 'studentClass',
                studentName: 'StudentName',
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Fees Structure',
        'subtitle': 'Payment & balance',
        'color': const Color(0xFF7C3AED),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => School_Fees_Structure_And_Balance(
                schoolName: 'schoolName',
                className: 'className',
                studentClass: 'studentClass',
                studentName: 'StudentName',
              ),
            ),
          );
        },
      },
    ];

    // Calculate optimal layout based on orientation
    final bool isLandscape = orientation == Orientation.landscape;

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
              child: isLandscape && screenWidth > 600
                  ? _buildGridLayout(actions, screenWidth, screenHeight)
                  : _buildColumnLayout(actions, screenWidth, screenHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnLayout(List<Map<String, dynamic>> actions, double screenWidth, double screenHeight) {
    return Column(
      children: actions.map((action) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              bottom: getResponsiveSize(6, screenWidth, screenHeight),
            ),
            child: _buildActionCard(action, screenWidth, screenHeight),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridLayout(List<Map<String, dynamic>> actions, double screenWidth, double screenHeight) {
    return Column(
      children: [
        // First row with 2 cards
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: getResponsiveSize(6, screenWidth, screenHeight),
                    bottom: getResponsiveSize(6, screenWidth, screenHeight),
                  ),
                  child: _buildActionCard(actions[0], screenWidth, screenHeight),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: getResponsiveSize(6, screenWidth, screenHeight),
                    bottom: getResponsiveSize(6, screenWidth, screenHeight),
                  ),
                  child: _buildActionCard(actions[1], screenWidth, screenHeight),
                ),
              ),
            ],
          ),
        ),
        // Second row with 2 cards
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: getResponsiveSize(6, screenWidth, screenHeight),
                    bottom: getResponsiveSize(6, screenWidth, screenHeight),
                  ),
                  child: _buildActionCard(actions[2], screenWidth, screenHeight),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: getResponsiveSize(6, screenWidth, screenHeight),
                    bottom: getResponsiveSize(6, screenWidth, screenHeight),
                  ),
                  child: _buildActionCard(actions[3], screenWidth, screenHeight),
                ),
              ),
            ],
          ),
        ),
        // Third row with 1 card centered
        Expanded(
          child: Container(
            margin: EdgeInsets.only(
              bottom: getResponsiveSize(6, screenWidth, screenHeight),
            ),
            child: _buildActionCard(actions[4], screenWidth, screenHeight),
          ),
        ),
      ],
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
                      Icon(
                        Icons.arrow_forward_ios,
                        size: getResponsiveSize(14, screenWidth, screenHeight),
                        color: const Color(0xFF667eea),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Parent Portal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: getResponsiveSize(16, screenWidth, screenHeight),
            ),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(
                  getResponsiveSize(8, screenWidth, screenHeight),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    getResponsiveSize(12, screenWidth, screenHeight),
                  ),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: getResponsiveSize(20, screenWidth, screenHeight),
                ),
              ),
              onPressed: _logout,
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildWelcomeSection(),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

}