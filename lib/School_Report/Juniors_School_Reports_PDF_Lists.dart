import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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
    setState(() {
      isLoading = true;
    });

    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final pdfDir = Directory('${directory.path}${_pdfStoragePath}');

        // Create the directory if it doesn't exist
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
          print('Created PDF directory: ${pdfDir.path}');
        }

        final files = pdfDir.listSync()
            .where((file) => file.path.endsWith('.pdf'))
            .map((file) {
          String fileName = file.path.split('/').last;
          // Remove .pdf extension and _Report suffix, replace underscores with spaces
          return fileName
              .replaceAll('.pdf', '')
              .replaceAll('_Report', '')
              .replaceAll('_', ' ');
        })
            .toList();

        // Sort the files alphabetically
        files.sort();

        setState(() {
          savedPDFs = files;
        });

        print('Loaded ${files.length} PDF files from: ${pdfDir.path}');
      }
    } catch (e) {
      print('Error loading saved PDFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading PDF files: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Open saved PDF
  Future<void> _openPDF(String studentName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory!.path}${_pdfStoragePath}/$fileName';

      print('Attempting to open PDF: $filePath');

      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
      } else {
        print('PDF file not found at: $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found for $studentName'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // Delete PDF
  Future<void> _deletePDF(String studentName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory!.path}${_pdfStoragePath}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('Deleted PDF: $filePath');
        await _loadSavedPDFs(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF deleted successfully for $studentName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found for $studentName'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error deleting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get full PDF file path for external use
  String getPDFFilePath(String studentName) {
    return '${_pdfStoragePath}/${studentName.replaceAll(' ', '_')}_Report.pdf';
  }

  // Check if PDF exists for a student
  Future<bool> pdfExistsForStudent(String studentName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final fileName = '${studentName.replaceAll(' ', '_')}_Report.pdf';
      final filePath = '${directory!.path}${_pdfStoragePath}/$fileName';
      return await File(filePath).exists();
    } catch (e) {
      print('Error checking PDF existence: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.className} Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadSavedPDFs(),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Storage Information', style: TextStyle(color: Colors.blue.shade700)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('School: ${widget.schoolName}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Class: ${widget.className}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Storage Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _pdfStoragePath,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: TextStyle(color: Colors.blue.shade700)),
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
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  widget.schoolName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.className} - ${savedPDFs.length} Reports Available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PDF List Section
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF reports...',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : savedPDFs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.blue.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No PDF Reports Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No student reports have been generated yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: savedPDFs.length,
                itemBuilder: (context, index) {
                  final studentName = savedPDFs[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          offset: Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      subtitle: Text(
                        'Tap to open report',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.blue.shade600),
                        color: Colors.white,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, color: Colors.blue.shade600),
                                SizedBox(width: 8),
                                Text('Open Report', style: TextStyle(color: Colors.blue.shade800)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red.shade600),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red.shade600)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'open') {
                            _openPDF(studentName);
                          } else if (value == 'delete') {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete PDF Report', style: TextStyle(color: Colors.blue.shade700)),
                                content: Text('Are you sure you want to delete the report for $studentName?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deletePDF(studentName);
                                    },
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      onTap: () => _openPDF(studentName),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}