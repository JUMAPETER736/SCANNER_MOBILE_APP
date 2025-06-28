import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Parent_Screens/Student_Details_View.dart';
import 'package:scanna/Parent_Screens/Available_School_Events.dart';
import 'package:scanna/Parent_Screens/Student_Results.dart';
import 'package:scanna/Parent_Screens/School_Fees_Structure_And_Balance.dart';

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

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.01,
        vertical: MediaQuery.of(context).size.height * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.12,
                height: MediaQuery.of(context).size.width * 0.12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.07,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                    Text(
                      loggedInUser?.email?.split('@')[0] ?? 'Parent',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,

                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
                selectedClass: 'className',
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
                studentFullName: 'studentFullName',
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
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => School_Fees_Structure_And_Balance()),
          // );
        },
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.01,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.055,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF667eea),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
                        child: InkWell(
                          onTap: action['onTap'] as VoidCallback,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                              vertical: MediaQuery.of(context).size.height * 0.01,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.12,
                                      height: MediaQuery.of(context).size.width * 0.12,
                                      decoration: BoxDecoration(
                                        color: (action['color'] as Color).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        action['icon'] as IconData,
                                        color: action['color'] as Color,
                                        size: MediaQuery.of(context).size.width * 0.06,
                                      ),
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          action['title'] as String,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width * 0.045,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2D3748),
                                          ),
                                        ),
                                        SizedBox(height: MediaQuery.of(context).size.height * 0.003),
                                        Text(
                                          action['subtitle'] as String,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width * 0.037,
                                            color: const Color(0xFF667eea),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: MediaQuery.of(context).size.width * 0.04,
                                    color: const Color(0xFF667eea),
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
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Parent Portal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.05,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.04),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
              ),
              onPressed: _logout,
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildWelcomeSection(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                _buildQuickActions(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

}