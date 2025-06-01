import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'Login_Page.dart';

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
  bool isLoading = false;

  // Send reset email
  Future<void> resetPassword(String email, String name) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Email Sent ✈️',
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                TextSpan(text: 'Hello, '),
                TextSpan(
                  text: name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '  Check your email to reset your password.'),
              ],
            ),
          ),
        ),
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Failed to Reset Password',
        desc: 'Error: ${e.toString()}',
        btnOkOnPress: () {},
      ).show();
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Validate and check email in Firestore
  Future<void> validateAndResetPassword(String email) async {
    if (!isValidEmail(email)) {
      setState(() => errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      final userDoc = await _firestore
          .collection('Teachers_Details')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        setState(() {
          errorMessage = 'Email is not registered';
          isLoading = false;
        });
        return;
      }

      final data = userDoc.docs.first.data();
      final name = data['name'] ?? 'User';

      await resetPassword(email, name);
    } catch (e) {
      print('Error checking email: $e');
      setState(() {
        errorMessage = 'Something went wrong. Please try again later.';
        isLoading = false;
      });
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // Single _buildStyledTextField method using hintText instead of labelText
  Widget _buildStyledTextField({
    required TextEditingController controller,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
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
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, Login_Page.id);
          },
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
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
            children: [
              const Text(
                'Enter your email to reset your password',
                style: TextStyle(
                  fontSize: 26.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildStyledTextField(
                controller: _emailController,
                hintText: 'gradescanna@gmail.com',
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30.0),
              isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              )
                  : ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  validateAndResetPassword(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
