import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Juniors_School_Report_View extends StatefulWidget {
  final String schoolName;
  final String studentClass;
  final String studentFullName; // Matches the saved document ID

  const Juniors_School_Report_View({
    Key? key,
    required this.schoolName,
    required this.studentClass,
    required this.studentFullName,
  }) : super(key: key);

  @override
  _Juniors_School_Report_ViewState createState() =>
      _Juniors_School_Report_ViewState();
}

class _Juniors_School_Report_ViewState
    extends State<Juniors_School_Report_View> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic>? studentDetails;
  List<Map<String, dynamic>> studentSubjects = [];
  Map<String, dynamic>? totalMarks;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    try {
      // Fetch student document
      print(
          'DEBUG: Fetching student details from path: Schools/${widget.schoolName}/Classes/${widget.studentClass}/Student_Details/${widget.studentFullName}');
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.studentClass)
          .collection('Student_Details')
          .doc(widget.studentFullName) // Uses studentFullName
          .get();

      if (!studentDoc.exists) {
        throw Exception('Student document not found.');
      }

      // Fetch 'Registered_Information'
      DocumentSnapshot registeredInformationDoc = await studentDoc.reference
          .collection('Personal_Information')
          .doc('Registered_Information')
          .get();

      if (!registeredInformationDoc.exists) {
        throw Exception('Registered Information not found.');
      }

      // Fetch 'Student_Subjects'
      QuerySnapshot subjectsSnapshot = await studentDoc.reference
          .collection('Student_Subjects')
          .get();

      // Fetch 'TOTAL_MARKS'
      DocumentSnapshot totalMarksDoc = await studentDoc.reference
          .collection('TOTAL_MARKS')
          .doc('Marks')
          .get();

      // Extract student details
      final registeredData =
      registeredInformationDoc.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> subjectDetails = [];
      final Map<String, dynamic>? totalMarksData =
      totalMarksDoc.data() as Map<String, dynamic>?;

      // Process subjects
      for (var subjectDoc in subjectsSnapshot.docs) {
        var subjectData = subjectDoc.data() as Map<String, dynamic>;
        subjectDetails.add({
          'Subject_Name': subjectData['Subject_Name'] ?? 'Unknown Subject',
          'Subject_Grade': subjectData['Subject_Grade'] ?? 'N/A',
        });
      }

      // Update state with fetched data
      setState(() {
        studentDetails = {
          'fullName': '${registeredData['lastName']} ${registeredData['firstName']}',
          'studentGender': registeredData['studentGender'] ?? 'N/A',
          'studentClass': registeredData['studentClass'] ?? 'N/A',
          'studentAge': registeredData['studentAge'] ?? 'N/A',
          'studentID': registeredData['studentID'] ?? 'N/A',
        };
        studentSubjects = subjectDetails;
        totalMarks = {
          'Best_Six_Total_Points': totalMarksData?['Best_Six_Total_Points'] ?? 0,
          'Student_Total_Marks': totalMarksData?['Student_Total_Marks']?.toString() ?? '0',
          'Teacher_Total_Marks': totalMarksData?['Teacher_Total_Marks']?.toString() ?? '0',
        };
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching student details: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
        'An error occurred while fetching student details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Juniors School Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
          child: Text(
            errorMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Information
              Text(
                'Student Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              _buildInfoRow('Full Name', studentDetails!['fullName']),
              _buildInfoRow(
                  'Class', studentDetails!['studentClass']),
              _buildInfoRow(
                  'Gender', studentDetails!['studentGender']),
              _buildInfoRow('Age', studentDetails!['studentAge']),
              _buildInfoRow('ID', studentDetails!['studentID']),
              SizedBox(height: 20),

              // Subjects and Grades
              Text(
                'Subjects and Grades',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: studentSubjects.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  var subject = studentSubjects[index];
                  return ListTile(
                    title: Text(
                      subject['Subject_Name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      subject['Subject_Grade'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Total Marks
              Text(
                'Total Marks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              _buildInfoRow(
                'Best Six Total Points',
                totalMarks!['Best_Six_Total_Points'].toString(),
              ),
              _buildInfoRow(
                'Student Total Marks',
                totalMarks!['Student_Total_Marks'].toString(),
              ),
              _buildInfoRow(
                'Teacher Total Marks',
                totalMarks!['Teacher_Total_Marks'].toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}