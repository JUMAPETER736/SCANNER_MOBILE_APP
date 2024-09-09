import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/SettingsPage.dart';
import 'package:scanna/Main_Screen/GradeAnalytics.dart';
import 'package:scanna/Main_Screen/ClassSelection.dart';
import 'package:scanna/Students_Information/StudentDetails.dart';
import 'package:scanna/Main_Screen/Help.dart';
import 'package:scanna/Students_Information/StudentNameList.dart';
import 'package:scanna/Main_Screen/QRCodeScan.dart';
import 'package:scanna/Main_Screen/SchoolReports.dart';
import 'package:scanna/Home_Screens/LoginPage.dart';

User? loggedInUser;

class Done extends StatefulWidget {
  static String id = '/Done';

  @override
  _DoneState createState() => _DoneState();
}

class _DoneState extends State<Done> {
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
      Navigator.pushNamedAndRemoveUntil(context, LoginPage.id, (route) => false);
    } catch (e) {
      print(e);
    }
  }

  Widget _buildHome(BuildContext context, User? loggedInUser) {
    return Container(
      color: Color.fromARGB(255, 198, 205, 218),
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, ${loggedInUser?.displayName ?? 'User'}!',
            style: TextStyle(
                fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          SizedBox(height: 30.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 5.3 / 3,
                children: [
                  // Select Class
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ClassSelection()),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.class_,
                      text: 'Select Class',
                      color: Colors.blueAccent,
                    ),
                  ),
                  // View Grade Analytics
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GradeAnalytics()),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.analytics,
                      text: 'View Grade Analytics',
                      color: Colors.greenAccent,
                    ),
                  ),
                  // Enter Student Details
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StudentDetails()),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.person_add,
                      text: 'Enter Student Details',
                      color: Colors.orangeAccent,
                    ),
                  ),
                  // QR Code Scan
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QRCodeScan()),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.qr_code_scanner,
                      text: 'QR Scan',
                      color: Color.fromARGB(255, 59, 61, 60),
                    ),
                  ),
                  // School Reports
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SchoolReports()),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.school,
                      text: 'School Reports',
                      color: Colors.redAccent,
                    ),
                  ),
                  // List Students
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentNameList(loggedInUser: loggedInUser),
                        ),
                      );
                    },
                    child: _buildSquareCard(
                      icon: Icons.list,
                      text: 'Students Names',
                      color: Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareCard(
      {required IconData icon, required String text, required Color color}) {
    return Card(
      elevation: 5,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelp() {
    return Help();
  }

  Widget _buildSettings() {
    return SettingsPage(user: loggedInUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scanna Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold), // Text in bold
        ),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHelp()
          : _selectedIndex == 1
          ? _buildHome(context, loggedInUser)
          : _buildSettings(),
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
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}
