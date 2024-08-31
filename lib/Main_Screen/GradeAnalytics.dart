import 'package:flutter/material.dart';

class GradeAnalytics extends StatelessWidget {
  final List<Map<String, String>> juniorGradeRanges = [
    {'range': '80 - 100%', 'grade': 'A'},
    {'range': '70 - 79%', 'grade': 'B'},
    {'range': '60 - 69%', 'grade': 'C'},
    {'range': '50 - 59%', 'grade': 'D'},
    {'range': '40 - 49%', 'grade': 'E'},
    {'range': '0 - 39%', 'grade': 'F'},
  ];

  final List<Map<String, String>> seniorGradeRanges = [
    {'range': '80 - 100%', 'grade': '1'},
    {'range': '75 - 79%', 'grade': '2'},
    {'range': '70 - 74%', 'grade': '3'},
    {'range': '65 - 69%', 'grade': '4'},
    {'range': '60 - 64%', 'grade': '5'},
    {'range': '55 - 59%', 'grade': '6'},
    {'range': '50 - 54%', 'grade': '7'},
    {'range': '40 - 49%', 'grade': '8'},
    {'range': '0 - 39%', 'grade': '9'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Format'),
        backgroundColor: Colors.blueAccent, // Same color as in ClassSelection
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                'Customize your grading scale and display:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 16),
              _buildGradeSection('Junior Certificate Education Grading (JCE):', juniorGradeRanges),
              SizedBox(height: 16),
              _buildGradeSection('Senior Certificate Education Grading (MSCE):', seniorGradeRanges),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each grade section
  Widget _buildGradeSection(String title, List<Map<String, String>> grades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        ...grades.map((grade) {
          return Card(
            color: Colors.blueAccent, // Background color of the cards
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
            ),
            child: ListTile(
              title: Text(
                'Marks: ${grade['range']}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                'Grade: ${grade['grade']}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
