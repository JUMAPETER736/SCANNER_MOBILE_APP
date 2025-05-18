import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanna/Settings/Main_Settings.dart';
import 'package:scanna/Home_Screens/Grade_Analytics.dart';
import 'package:scanna/Home_Screens/Class_Selection.dart';
import 'package:scanna/Students_Information/Student_Details.dart';
import 'package:scanna/Home_Screens/Help.dart';
import 'package:scanna/Students_Information/Student_Name_List.dart';
import 'package:scanna/Home_Screens/QR_Code_Scan.dart';
import 'package:scanna/Home_Screens/School_Reports.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Home_Screens/Statistics.dart';
import 'package:scanna/Home_Screens/Results_PDF.dart';

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
    return SizedBox.expand(
      child: Container(
        color: const Color.fromARGB(255, 198, 205, 218),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                padding: EdgeInsets.zero,
                childAspectRatio: 4 / 3,
                children: [
                  _buildHomeCard(
                    icon: Icons.class_,
                    text: 'Select School & Class',
                    color: Colors.blueAccent,
                    iconSize: 65.0,
                    textSize: 19.0,
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
                    iconSize: 95.0,
                    textSize: 19.0,
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
                    iconSize: 95.0,
                    textSize: 19.0,
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
                    iconSize: 95.0,
                    textSize: 19.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QR_Code_Scan()),
                      );
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.school,
                    text: 'School Reports',
                    color: Colors.redAccent,
                    iconSize: 95.0,
                    textSize: 19.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => School_Reports()),
                      );
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.list,
                    text: 'Students Names',
                    color: Colors.purpleAccent,
                    iconSize: 95.0,
                    textSize: 19.0,
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
                    iconSize: 95.0,
                    textSize: 19.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Statistics()), // Replace with your actual class
                      );
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.picture_as_pdf,
                    text: 'School Reports PDFs',
                    color: Colors.deepOrangeAccent,
                    iconSize: 95.0,
                    textSize: 19.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  Results_PDF()), // Replace with your actual class
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHomeCard({
    required IconData icon,
    required String text,
    required Color color,
    required double iconSize, // Icon size parameter
    required double textSize, // Text size parameter
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize, // Set the icon size here
              color: Colors.white,
            ),
            const SizedBox(height: 8.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: textSize, // Set the text size here
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHelp() => Help();

  Widget _buildSettings() => Main_Settings(user: loggedInUser!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
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
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}


