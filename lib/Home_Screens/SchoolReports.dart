import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Home_Screens/SchoolReportPDFGenerator.dart';

class SchoolReports extends StatefulWidget {
  final User? loggedInUser;

  const SchoolReports({Key? key, this.loggedInUser}) : super(key: key);

  @override
  _SchoolReportsState createState() => _SchoolReportsState();
}

class _SchoolReportsState extends State<SchoolReports> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? teacherClass;
  bool _hasSelectedClass = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.loggedInUser;
    if (currentUser != null) {
      _fetchTeacherClass();
    }
  }

  Future<void> _fetchTeacherClass() async {
    if (currentUser == null) return;

    var teacherSnapshot = await FirebaseFirestore.instance
        .collection('Teachers_Details')
        .doc(currentUser!.email)
        .get();

    if (teacherSnapshot.exists) {
      var teacherData = teacherSnapshot.data() as Map<String, dynamic>;
      var classes = teacherData['classes'] as List<dynamic>? ?? [];

      if (classes.isNotEmpty) {
        setState(() {
          teacherClass = classes[0];
          _hasSelectedClass = true;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    if (teacherClass == null) return [];

    var studentsSnapshot = await FirebaseFirestore.instance
        .collection('Students_Details')
        .doc(teacherClass!)
        .collection('Student_Details')
        .get();

    List<Map<String, dynamic>> students = [];

    for (var studentDoc in studentsSnapshot.docs) {
      var personalInfoDoc = await studentDoc.reference
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (personalInfoDoc.exists) {
        var personalInfo = personalInfoDoc.data() as Map<String, dynamic>;
        var studentData = studentDoc.data() as Map<String, dynamic>;

        students.add({
          'id': studentDoc.id,
          'fullName': "${personalInfo['lastName']} ${personalInfo['firstName']}",
          'gender': personalInfo['studentGender'] ?? 'N/A',
          'studentTotalMarks': studentData['Student_Total_Marks'] ?? 0,
          'teachersTotalMarks': studentData['Teachers_Total_Marks'] ?? 0,
        });
      }
    }

    students.sort((a, b) => b['studentTotalMarks'].compareTo(a['studentTotalMarks']));
    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasSelectedClass ? '$teacherClass STUDENTS' : 'School Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: _hasSelectedClass
            ? [IconButton(icon: Icon(Icons.search), onPressed: () => _showSearchDialog())]
            : [],
      ),
      body: _hasSelectedClass
          ? FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Student found.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)));
          }

          var filteredStudents = snapshot.data!.where((student) => student['fullName'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return filteredStudents.isEmpty
              ? Center(child: Text('Student NOT found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)))
              : ListView.separated(
            itemCount: filteredStudents.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              var student = filteredStudents[index];
              return _buildStudentTile(student, index);
            },
          );
        },
      )
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, int index) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text('${index + 1}.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        title: Text(student['fullName'].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gender: ${student['gender']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Total Marks: ${student['studentTotalMarks']}/${student['teachersTotalMarks']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolReportPDFGenerator(
                studentName: student['id'],
                studentClass: teacherClass!,
                studentTotalMarks: student['studentTotalMarks'],
                teachersTotalMarks: student['teachersTotalMarks'],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Student'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(hintText: 'Enter Student Name'),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(child: Text('Search'), onPressed: () => setState(() => _searchQuery = _searchController.text)),
        ],
      ),
    );
  }
}
