import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ForgotPassword extends StatefulWidget {
  static String id = '/ForgotPassword';

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  String errorMessage = '';

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      // Show success dialog on successful password reset email send
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Email Sent ✈️',
        desc: 'Check your email to reset your password!',
        btnOkText: 'OK',
        btnOkOnPress: () {},
      )..show();
    } catch (e) {
      // Handle errors such as invalid email or network issues
      print('Failed to send reset email: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Failed to Reset Password',
        desc: '$e', // Show error message in the dialog
        btnOkText: 'OK',
        btnOkOnPress: () {},
      )..show();
    }
  }

  Future<void> validateAndResetPassword(String email) async {
    if (!isValidEmail(email)) {
      setState(() {
        errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    try {
      // Check if the email exists in Firestore under the 'users' collection
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        setState(() {
          errorMessage = 'Email is not registered';
        });
        return;
      }

      // If email is valid and exists, proceed to reset password
      await resetPassword(email);
    } catch (e) {
      print('Error checking email in Firestore: $e');
      setState(() {
        errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

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
                'Enter your Email to reset your password',
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
              SizedBox(height: 30.0), // Increased space above the button
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  validateAndResetPassword(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent, // Button color
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0), // Increased horizontal padding
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
