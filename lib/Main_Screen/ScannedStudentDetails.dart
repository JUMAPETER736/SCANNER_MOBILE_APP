// import 'dart:convert';
// import 'package:flutter/material.dart';
//
// class ScannedStudentDetails extends StatelessWidget {
//   final Map<String, dynamic> studentData;
//
//   ScannedStudentDetails({required this.studentData});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Student Details'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Student ID: ${studentData['studentID']}',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             Text('First Name: ${studentData['firstName']}', style: TextStyle(fontSize: 18)),
//             SizedBox(height: 8),
//             Text('Last Name: ${studentData['lastName']}', style: TextStyle(fontSize: 18)),
//             SizedBox(height: 8),
//             Text('Class: ${studentData['studentClass']}', style: TextStyle(fontSize: 18)),
//             SizedBox(height: 8),
//             Text('Age: ${studentData['studentAge']}', style: TextStyle(fontSize: 18)),
//             SizedBox(height: 8),
//             Text('Gender: ${studentData['studentGender']}', style: TextStyle(fontSize: 18)),
//             SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () {
//                 // Handle some action here
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Some action triggered!')),
//                 );
//               },
//               child: Text('Trigger Action'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.greenAccent,
//                 padding: EdgeInsets.symmetric(vertical: 15),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
