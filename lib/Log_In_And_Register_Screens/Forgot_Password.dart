import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class Forgot_Password extends StatefulWidget {
  static String id = '/ForgotPassword';

  @override
  _Forgot_PasswordState createState() => _Forgot_PasswordState();
}

class _Forgot_PasswordState extends State<Forgot_Password> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  String errorMessage = '';

  // Function to reset password using Firebase Authentication
  Future<void> resetPassword(String email, String name) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Show success dialog with customized greeting
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Email Sent ✈️',
        desc: 'Hello $name, Check your Email to reset your Password!',
        btnOkText: 'OK',
        btnOkOnPress: () {},
      )..show();
    } catch (e) {
      print('Failed to send reset Email: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Failed to Reset Password',
        desc: 'Error: ${e.toString()}',
        btnOkText: 'OK',
        btnOkOnPress: () {},
      )..show();
    }
  }

  // Function to validate the email and check if it exists in Firestore
  Future<void> validateAndResetPassword(String email) async {
    if (!isValidEmail(email)) {
      setState(() {
        errorMessage = 'Please Enter a valid Email Address';
      });
      return;
    }

    try {
      // Query Firestore to get user info based on the email
      final userDoc = await _firestore
          .collection('TeachersDetails')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        setState(() {
          errorMessage = 'Email is not Registered';
        });
        return;
      }

      // Get the first and last name from Firestore
      final name = userDoc.docs.first.data()['name'];


      // If email is valid and exists, proceed to reset password with customized message
      await resetPassword(email, name);
    } catch (e) {
      print('Error checking Email in Firestore: $e');
      setState(() {
        errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  // Regular expression to check for valid email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Enter your Email to reset your Password',
                style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10.0),
              _buildStyledTextField(
                controller: _emailController,
                labelText: 'Email',
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  validateAndResetPassword(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
