import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'How to Use Scanna',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            Text(
              '1. Select Class: Tap on "Select Class" to choose the class you want to work with. This will allow you to filter and manage students in that class.',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '2. View Grade Analytics: Tap on "View Grade Analytics" to see the performance of students in the selected class. This feature provides insights into student grades.',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '3. Enter Student Details: Tap on "Enter Student Details" to add new students to the system. After entering details, you can generate a barcode for each student.',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '4. Generate Barcode: After saving student details, the app will automatically generate a barcode that represents the student ID. This barcode can be scanned later for quick access.',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '5. Need Further Assistance? Contact us at support@scannaapp.com for additional help or any other queries.',
              style: TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      ),
    );
  }
}
