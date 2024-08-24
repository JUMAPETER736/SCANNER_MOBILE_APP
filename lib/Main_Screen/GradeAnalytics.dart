import 'package:flutter/material.dart';

class GradeAnalytics extends StatelessWidget {
  // Sample data for demonstration
  final List<GradeData> gradeDataList = [
    GradeData(1, 85),
    GradeData(2, 90),
    GradeData(3, 78),
    GradeData(4, 92),
    GradeData(5, 88),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grade Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: gradeDataList.length,
          itemBuilder: (context, index) {
            final gradeData = gradeDataList[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Student ID: ${gradeData.studentId}'),
                subtitle: Text('Grade: ${gradeData.grade}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Model class for holding grade data
class GradeData {
  final int studentId;
  final int grade;

  GradeData(this.studentId, this.grade);
}

// Usage example
void main() {
  runApp(MaterialApp(
    home: GradeAnalytics(),
  ));
}
