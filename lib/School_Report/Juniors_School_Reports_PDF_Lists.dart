import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'Juniors_School_Report_PDF.dart';

class Juniors_School_Reports_PDF_List extends StatefulWidget {
  final String schoolName;
  final String className; // e.g., "FORM 1" or "FORM 2"

  const Juniors_School_Reports_PDF_List({
    Key? key,
    required this.schoolName,
    required this.className,
    required String studentClass,
    required studentFullName,
  }) : super(key: key);

  @override
  _Juniors_School_Reports_PDF_ListState createState() => _Juniors_School_Reports_PDF_ListState();
}

class _Juniors_School_Reports_PDF_ListState extends State<Juniors_School_Reports_PDF_List> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> savedPDFs = [];
  bool isLoading = false;

  // Get the dynamic PDF storage path
  String get _pdfStoragePath {
    return '/Schools/${widget.schoolName}/Classes/${widget.className}/School_Reports_PDF';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPDFs();
  }

  // Load list of saved PDFs from device storage
  Future<void> _loadSavedPDFs() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final pdfDir = Directory('${directory.path}${_pdfStoragePath}');
        if (await pdfDir.exists()) {
          final files = pdfDir.listSync()
              .where((file) => file.path.endsWith('.pdf'))
              .map((file) => file.path.split('/').last.replaceAll('.pdf', ''))
              .toList();

          setState(() {
            savedPDFs = files;
          });
        }
      }
    } catch (e) {
      print('Error loading saved PDFs: $e');
    }
  }

  // Fetch students with complete data for PDF generation
  Future<List<Map<String, dynamic>>> _fetchStudentsWithData() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Students')
          .get();

      List<Map<String, dynamic>> students = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final fullName = '$firstName $lastName';

        // Fetch subjects/grades for this student
        final subjects = await _fetchStudentSubjects(doc.id);

        // Calculate subject statistics
        final subjectStats = await _calculateSubjectStats(subjects);

        students.add({
          'id': doc.id,
          'fullName': fullName,
          'class': widget.className,
          'subjects': subjects,
          'subjectStats': subjectStats,
          'firstName': firstName,
          'lastName': lastName,
          'studentTotalMarks': data['studentTotalMarks'] ?? 0,
          'teacherTotalMarks': data['teacherTotalMarks'] ?? 0,
          'studentPosition': data['studentPosition'] ?? 0,
          'totalStudents': data['totalStudents'] ?? 0,
          'formTeacherRemarks': data['formTeacherRemarks'],
          'headTeacherRemarks': data['headTeacherRemarks'],
          'averageGradeLetter': data['averageGradeLetter'],
          'jceStatus': data['jceStatus'] ?? 'FAIL',
        });
      }

      return students;
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // Fetch subjects for a specific student
  Future<List<Map<String, dynamic>>> _fetchStudentSubjects(String studentId) async {
    try {
      QuerySnapshot subjectsSnapshot = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.className)
          .collection('Students')
          .doc(studentId)
          .collection('subjects')
          .get();

      return subjectsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'subject': data['subject'] ?? '',
          'score': data['score'] ?? 0,
          'hasGrade': data['hasGrade'] ?? true,
          'gradeLetter': data['gradeLetter'] ?? '',
          'position': data['position'] ?? 0,
          'totalStudents': data['totalStudents'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching student subjects: $e');
      return [];
    }
  }

  // Calculate subject statistics (averages, etc.)
  Future<Map<String, dynamic>> _calculateSubjectStats(List<Map<String, dynamic>> subjects) async {
    Map<String, dynamic> stats = {};

    for (var subject in subjects) {
      final subjectName = subject['subject'];

      try {
        // Fetch all students' scores for this subject to calculate average
        QuerySnapshot allStudentsSnapshot = await _firestore
            .collection('Schools')
            .doc(widget.schoolName)
            .collection('Classes')
            .doc(widget.className)
            .collection('Students')
            .get();

        List<int> allScores = [];

        for (var studentDoc in allStudentsSnapshot.docs) {
          QuerySnapshot subjectSnapshot = await _firestore
              .collection('Schools')
              .doc(widget.schoolName)
              .collection('Classes')
              .doc(widget.className)
              .collection('Students')
              .doc(studentDoc.id)
              .collection('subjects')
              .where('subject', isEqualTo: subjectName)
              .get();

          if (subjectSnapshot.docs.isNotEmpty) {
            final score = subjectSnapshot.docs.first.data() as Map<String, dynamic>;
            allScores.add(score['score'] ?? 0);
          }
        }

        // Calculate average
        int average = 0;
        if (allScores.isNotEmpty) {
          average = (allScores.reduce((a, b) => a + b) / allScores.length).round();
        }

        stats[subjectName] = {
          'average': average,
          'totalStudents': allScores.length,
        };
      } catch (e) {
        print('Error calculating stats for $subjectName: $e');
        stats[subjectName] = {
          'average': 0,
          'totalStudents': 0,
        };
      }
    }

    return stats;
  }

  // Fetch school information
  Future<Map<String, dynamic>> _fetchSchoolInfo() async {
    try {
      DocumentSnapshot schoolDoc = await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .get();

      if (schoolDoc.exists) {
        return schoolDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching school info: $e');
    }

    return {};
  }

  // Generate PDF for a specific student
  Future<void> _generateStudentPDF(Map<String, dynamic> studentData) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Request storage permission
      if (await Permission.storage.request().isGranted) {
        final schoolInfo = await _fetchSchoolInfo();

        // Create PDF using the correct parameters from Juniors_School_Report_PDF
        final pdfGenerator = Juniors_School_Report_PDF(
          studentClass: studentData['class'],
          studentFullName: studentData['fullName'],
          subjects: studentData['subjects'],
          subjectStats: studentData['subjectStats'],
          studentTotalMarks: studentData['studentTotalMarks'],
          teacherTotalMarks: studentData['teacherTotalMarks'],
          studentPosition: studentData['studentPosition'],
          totalStudents: studentData['totalStudents'],
          schoolName: schoolInfo['name'] ?? widget.schoolName,
          schoolAddress: schoolInfo['address'],
          schoolPhone: schoolInfo['phone'],
          schoolEmail: schoolInfo['email'],
          schoolAccount: schoolInfo['account'],
          nextTermDate: schoolInfo['nextTermDate'],
          formTeacherRemarks: studentData['formTeacherRemarks'],
          headTeacherRemarks: studentData['headTeacherRemarks'],
          averageGradeLetter: studentData['averageGradeLetter'],
          jceStatus: studentData['jceStatus'],
        );

        // Generate and save PDF to specific path
        await _savePDFToStorage(pdfGenerator, studentData['fullName']);

        // Refresh the PDF list
        await _loadSavedPDFs();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated for ${studentData['fullName']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save PDF to device storage using dynamic path
  Future<void> _savePDFToStorage(Juniors_School_Report_PDF pdfGenerator, String studentName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final pdfDir = Directory('${directory!.path}${_pdfStoragePath}');

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';

      // Use the generateAndSavePDF method from your PDF class
      await pdfGenerator.generateAndSavePDF(fileName);

      // The PDF should now be saved to the correct location
      print('PDF saved to: ${pdfDir.path}/$fileName');

    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  // Open saved PDF
  Future<void> _openPDF(String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}${_pdfStoragePath}/$fileName.pdf';

      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete PDF
  Future<void> _deletePDF(String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}${_pdfStoragePath}/$fileName.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        await _loadSavedPDFs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate PDFs for all students
  Future<void> _generateAllPDFs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final students = await _fetchStudentsWithData();
      int successCount = 0;
      int errorCount = 0;

      for (var student in students) {
        try {
          if (!savedPDFs.contains(student['fullName'])) {
            await _generateStudentPDF(student);
            successCount++;
          }
        } catch (e) {
          errorCount++;
          print('Error generating PDF for ${student['fullName']}: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated $successCount PDFs successfully. $errorCount errors.'),
          backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Reports - ${widget.schoolName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadSavedPDFs(),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Storage Path'),
                  content: Text(
                    'PDFs are saved to:\n${_pdfStoragePath}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Saved PDFs Section
          if (savedPDFs.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Saved Reports (${savedPDFs.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: savedPDFs.length,
                itemBuilder: (context, index) {
                  final fileName = savedPDFs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf, color: Colors.green),
                      title: Text(fileName),
                      subtitle: Text('Tap to open'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new),
                                SizedBox(width: 8),
                                Text('Open'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'open') {
                            _openPDF(fileName);
                          } else if (value == 'delete') {
                            _deletePDF(fileName);
                          }
                        },
                      ),
                      onTap: () => _openPDF(fileName),
                    ),
                  );
                },
              ),
            ),
            Divider(thickness: 2),
          ],

          // Generate New PDFs Section
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.add_circle, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Generate New Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Students List for PDF Generation
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchStudentsWithData(),
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
                    final student = students[index];
                    final fullName = student['fullName'];
                    final hasExistingPDF = savedPDFs.contains(fullName);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          hasExistingPDF ? Icons.check_circle : Icons.person,
                          color: hasExistingPDF ? Colors.green : Colors.grey,
                        ),
                        title: Text(fullName),
                        subtitle: Text(
                          hasExistingPDF
                              ? 'PDF already exists - Class: ${student['class']}'
                              : 'Class: ${student['class']} - ${student['subjects'].length} subjects',
                        ),
                        trailing: isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(
                          hasExistingPDF ? Icons.refresh : Icons.picture_as_pdf,
                          color: hasExistingPDF ? Colors.orange : Colors.blue,
                        ),
                        onTap: isLoading
                            ? null
                            : () async {
                          await _generateStudentPDF(student);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _generateAllPDFs,
        icon: Icon(Icons.auto_awesome),
        label: Text('Generate All'),
        backgroundColor: isLoading ? Colors.grey : null,
      ),
    );
  }
}