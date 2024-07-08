import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ForgotPassword extends StatelessWidget {
  static String id = '/ForgotPassword';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    String email = '';

    Future<void> resetPassword(String email) async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        // Show success dialog on successful password reset email send
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success, // Corrected enum value to 'success'
          animType: AnimType.scale, // Corrected enum value to 'scale'
          title: 'Email Sent ✈️',
          desc: 'Check your email to reset password!',
          btnOkText: 'OK',
          btnOkOnPress: () {},
        )..show();
      } catch (e) {
        // Handle errors such as invalid email or network issues
        print('Failed to send reset email: $e');
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error, // Corrected enum value to 'error'
          animType: AnimType.scale, // Corrected enum value to 'scale'
          title: 'Failed to Reset Password',
          desc: '$e', // Show error message in the dialog
          btnOkText: 'OK',
          btnOkOnPress: () {},
        )..show();
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Image.asset('assets/images/background.png'),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 60.0,
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 40.0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(height: 20.0),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        email = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Email',
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    resetPassword(email);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    backgroundColor: Color(0xff447def),
                  ),
                  child: Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 25.0, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
