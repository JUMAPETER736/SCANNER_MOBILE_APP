import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mobile Application Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'This mobile application is designed for efficient grade management. It allows teachers to scan QR codes associated with students to access their details quickly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Key Features:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '- QR Code Scanning: Scan student QR codes to retrieve their information.\n'
                  '- Grade Entry: Teachers can enter grades for specific students after scanning their codes.\n'
                  '- Secure Access: Only authorized teachers can input grades, ensuring data integrity and security.',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'For any support or inquiries, please contact our support team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
