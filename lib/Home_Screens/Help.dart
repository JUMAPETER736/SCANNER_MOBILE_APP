import 'package:flutter/material.dart';
import 'package:scanna/Home_Screens/Main_Home.dart';

class Help extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // Set this to false to avoid automatic back button
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Back arrow icon
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, Home.id, (route) => false);

          },
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
              '5. Need Further Assistance? Contact us at jumapeter736@gmail.com for additional help or any other queries.',
            ),
          ],
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
