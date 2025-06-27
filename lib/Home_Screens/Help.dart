import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanna/Home_Screens/Teacher_Home_Page.dart';

class Help extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Hide system UI overlays (status bar, navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // Custom header with back button and title
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, Teacher_Home_Page.id);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Empty container to balance the row
                    Container(width: 48),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text(
                        'How to Use Scanna',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      _buildHelpText(
                        '1. Select Class: Tap on "Select Class" to choose the class you want to work with. This will allow you to filter and manage students in that class.',
                      ),
                      SizedBox(height: 20.0),
                      _buildHelpText(
                        '2. View Grade Analytics: Tap on "View Grade Analytics" to see the performance of students in the selected class. This feature provides insights into student grades.',
                      ),
                      SizedBox(height: 20.0),
                      _buildHelpText(
                        '3. Enter Student Details: Tap on "Enter Student Details" to add new students to the system. After entering details, you can generate a barcode for each student.',
                      ),
                      SizedBox(height: 20.0),
                      _buildHelpText(
                        '4. Generate Barcode: After saving student details, the app will automatically generate a barcode that represents the student ID. This barcode can be scanned later for quick access.',
                      ),
                      SizedBox(height: 20.0),
                      _buildHelpText(
                          '''
5. Need Further Assistance or any Question for additional help or any other queries.
You can contact us on:
  Email: jumapeter736@gmail.com
  Phone: +265 880 409 468 / +265 994 459 714
'''
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each help text section with consistent style
  Widget _buildHelpText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
      ),
    );
  }
}