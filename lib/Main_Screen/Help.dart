import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
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
            ..._buildHelpItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHelpItems() {
    return [
      _buildHelpItem(
        title: '1. Select Class',
        description:
            'Tap on "Select Class" to choose the class you want to work with. This will allow you to filter and manage students in that class.',
      ),
      _buildHelpItem(
        title: '2. View Grade Analytics',
        description:
            'Tap on "View Grade Analytics" to see the performance of students in the selected class. This feature provides insights into student grades.',
      ),
      _buildHelpItem(
        title: '3. Enter Student Details',
        description:
            'Tap on "Enter Student Details" to add new students to the system. After entering details, you can generate a barcode for each student.',
      ),
      _buildHelpItem(
        title: '4. Generate Barcode',
        description:
            'After saving student details, the app will automatically generate a barcode that represents the student ID. This barcode can be scanned later for quick access.',
      ),
      _buildHelpItem(
        title: '5. Need Further Assistance?',
        description: 'Contact us at support@scannaapp.com for additional help or any other queries.',
      ),
    ];
  }

  Widget _buildHelpItem({required String title, required String description}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              description,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
