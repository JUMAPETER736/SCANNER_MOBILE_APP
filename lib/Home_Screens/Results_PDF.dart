

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Results_PDF extends StatefulWidget {
  @override
  _Results_PDFState createState() => _Results_PDFState();
}

class _Results_PDFState extends State<Results_PDF> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Students').get();

      List<Map<String, dynamic>> students = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        return {
          'fullName': '$firstName $lastName',
        };
      }).toList();

      return students;
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Students PDFs'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No student records found.'));
          }

          final students = snapshot.data!;
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final fullName = students[index]['fullName'];

              return ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                title: Text(fullName),
                onTap: () {
                  // You can implement PDF viewing/downloading logic here.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on $fullName PDF')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
