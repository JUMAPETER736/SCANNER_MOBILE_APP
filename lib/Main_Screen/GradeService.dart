import 'package:cloud_firestore/cloud_firestore.dart';

// Define the Grade class to represent a grade object
class Grade {
  final String subject;
  final String grade;
  final DateTime date;

  Grade({required this.subject, required this.grade, required this.date});
}

class GradeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGrade(String studentId, Grade grade) async {
    await _firestore.collection('students').doc(studentId).collection('grades').add({
      'subject': grade.subject,
      'grade': grade.grade,
      'date': grade.date,
    });
  }

  Future<List<Grade>> fetchGrades(String studentId) async {
    final QuerySnapshot result = await _firestore.collection('students').doc(studentId).collection('grades').get();
    return result.docs.map((doc) => Grade(
      subject: doc['subject'],
      grade: doc['grade'],
      date: (doc['date'] as Timestamp).toDate(),
    )).toList();
  }
}
