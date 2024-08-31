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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Customize your grading scale and display:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Junior Certificate Education Grading (JCE):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...juniorGradeRanges.map((grade) {
              return Card(
                child: ListTile(
                  title: Text('Marks: ${grade['range']}'),
                  subtitle: Text('Grade: ${grade['grade']}'),
                ),
              );
            }).toList(),
            SizedBox(height: 16),
            Text(
              'Senior Certificate Education Grading (MSCE):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...seniorGradeRanges.map((grade) {
              return Card(
                child: ListTile(
                  title: Text('Marks: ${grade['range']}'),
                  subtitle: Text('Grade: ${grade['grade']}'),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
