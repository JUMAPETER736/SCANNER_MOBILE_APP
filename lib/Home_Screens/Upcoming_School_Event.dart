import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class Upcoming_School_Event extends StatefulWidget {
  @override
  _Upcoming_School_EventState createState() => _Upcoming_School_EventState();
}

class _Upcoming_School_EventState extends State<Upcoming_School_Event> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false; // To prevent multiple scans
  Map<String, dynamic>? studentData; // Store scanned student data

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          studentData == null ? 'Scan QR Code' : 'Student Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: studentData == null ? _buildQrScannerView(context) : _buildStudentDetailsView(),
    );
  }

  Widget _buildQrScannerView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;

    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.blueAccent,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Point your camera at the QR code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned) {
        setState(() {
          isScanned = true;
        });
        controller.pauseCamera();

        try {
          studentData = jsonDecode(scanData.code!);
          setState(() {});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid QR Code'),
              backgroundColor: Colors.redAccent,
            ),
          );
          controller.resumeCamera();
          setState(() {
            isScanned = false;
          });
        }
      }
    });
  }

  Widget _buildStudentDetailsView() {
    String firstName = studentData?['firstName'] ?? 'N/A';
    String lastName = studentData?['lastName'] ?? 'N/A';
    String studentClass = studentData?['studentClass'] ?? 'N/A';
    String studentAge = studentData?['studentAge'] ?? 'N/A';
    String studentGender = studentData?['studentGender'] ?? 'N/A';
    String studentID = studentData?['studentID'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlueAccent.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shadowColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_pin,
                size: 100,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 16),
              Text(
                '$firstName $lastName',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Divider(
                height: 30,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
              _buildDetailRow('Student ID', studentID),
              _buildDetailRow('Class', studentClass),
              _buildDetailRow('Age', studentAge),
              _buildDetailRow('Gender', studentGender),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline),
                label: Text('Mark Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Handle attendance marking logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Attendance Marked for $firstName $lastName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            Icons.arrow_right,
            color: Colors.blueAccent,
          ),
          SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
