import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class Juniors_School_Report_View extends StatefulWidget {
  final String studentClass;
  final String studentFullName;

  const Juniors_School_Report_View({
    required this.studentClass,
    required this.studentFullName,
    Key? key,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() => _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState extends State<Juniors_School_Report_View> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic> totalMarks = {};
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? userEmail;

  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'No user is currently logged in.';
      });
      return;
    }

    userEmail = user.email;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('Teachers_Details').doc(userEmail).get();

      if (!userDoc.exists) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'User details not found.';
        });
        return;
      }

      final String? teacherSchool = userDoc['school'];
      final List<dynamic>? teacherClasses = userDoc['classes'];

      if (teacherSchool == null || teacherClasses == null || teacherClasses.isEmpty) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Please select a School and Classes before accessing reports.';
        });
        return;
      }

      final String studentClass = widget.studentClass.trim().toUpperCase();
      final String studentFullName = widget.studentFullName;

      if (studentClass != 'FORM 1' && studentClass != 'FORM 2') {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Only students in FORM 1 or FORM 2 can access this report.';
        });
        return;
      }


      // ✅ Use teacher's school from Firestore instead of widget.schoolName
      final String basePath = 'Schools/$teacherSchool/Classes/$studentClass/Student_Details/$studentFullName';

      print('Base Path: $basePath');

      await fetchStudentSubjects(basePath);
      await fetchTotalMarks(basePath);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred while fetching data.';
      });
    }
  }



  Future<void> fetchStudentSubjects(String basePath) async {
    try {
      final snapshot = await _firestore
          .collection('$basePath/Student_Subjects')
          .get();

      List<Map<String, dynamic>> subjectList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        subjectList.add({
          'subject': data['Subject_Name'] ?? doc.id,
          'grade': data['Subject_Grade'] ?? 'N/A',

        });
      }

      setState(() {
        subjects = subjectList;
        _statusMessage = 'Subjects fetched successfully.';
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      setState(() {
        _statusMessage = 'Failed to load subjects.';
      });
    }
  }




  Future<void> fetchTotalMarks(String basePath) async {
    try {
      final doc = await _firestore.doc('$basePath/TOTAL_MARKS/Marks').get();

      if (doc.exists) {
        setState(() {
          totalMarks = doc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _statusMessage = 'No total marks found.';
        });
      }
    } catch (e) {
      print("Error fetching total marks: $e");
      setState(() {
        _statusMessage = 'Failed to load total marks.';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
        setState(() => errorMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Report: ${widget.studentFullName}'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchStudentData),
          IconButton(icon: Icon(Icons.print), onPressed: _printDocument),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic),
                  ),
                ),
              _buildSchoolInfoCard(),
              SizedBox(height: 16),
              _buildSubjectsCard(),
              SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    return Card(
      child: ListTile(
        title: Text('Class: ${widget.studentClass}'),
        subtitle: Text('Student: ${widget.studentFullName}'),
      ),
    );
  }

  Widget _buildSubjectsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(title: Text('Subjects, Marks & Grades')),
          Divider(),
          ...subjects.map((subj) => ListTile(
            title: Text(subj['subject'] ?? 'Unknown'),
            trailing: Text('Grade: ${subj['grade'] ?? '-'}'),
          )),
        ],
      ),
    );
  }


  Widget _buildSummaryCard() {
    return Card(
      child: ListTile(
        title: Text('Total Marks'),
        subtitle: Text(totalMarks.toString()),
      ),
    );
  }

  void _printDocument() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text("School Report for - ${widget.studentFullName}"),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}
