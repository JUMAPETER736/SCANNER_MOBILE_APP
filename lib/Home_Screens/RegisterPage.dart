import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:validators/validators.dart' as validator;
import 'package:scanna/Results_Screen/Done.dart';
import 'package:scanna/Home_Screens/LoginPage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget { 
  static String id = '/RegisterPage';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? name;
  String? email;
  String? password;
  String? confirmPassword; // Added variable for confirm password

  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyNameField = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;
  bool _passwordMismatch = false; // Added flag for password mismatch

  String _emailText = 'Please use a valid Email';
  String _passwordText = 'Please use a strong Password';
  String _emptyNameFieldText = 'Please fill in the Name field';
  String _emptyEmailFieldText = 'Please fill in the Email field';
  String _emptyPasswordFieldText = 'Please fill in the Password field';
  String _passwordMismatchText = 'Passwords do not match'; // Error message for password mismatch
  String _inUsedEmailText = 'The Email address is already in use by another Account.';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    setState(() {
      _wrongEmail = false;
      _wrongPassword = false;
      _emptyNameField = false;
      _emptyEmailField = false;
      _emptyPasswordField = false;
      _passwordMismatch = false; // Reset password mismatch flag
    });

    // Validate input fields
    if (name == null || name!.isEmpty) {
      setState(() {
        _emptyNameField = true;
      });
    }

    if (email == null || email!.isEmpty) {
      setState(() {
        _emptyEmailField = true;
      });
    }

    if (password == null || password!.isEmpty) {
      setState(() {
        _emptyPasswordField = true;
      });
    }

    if (confirmPassword == null || confirmPassword!.isEmpty) {
      setState(() {
        _passwordMismatch = true;
      });
    }

    if (_emptyNameField || _emptyEmailField || _emptyPasswordField || _passwordMismatch) {
      return;
    }

    if (!validator.isEmail(email!) || !validator.isLength(password!, 6) || password != confirmPassword) {
      setState(() {
        if (!validator.isEmail(email!)) {
          _wrongEmail = true;
        }
        if (!validator.isLength(password!, 6)) {
          _wrongPassword = true;
        }
        if (password != confirmPassword) {
          _passwordMismatch = true; // Set password mismatch flag
        }
      });
      return;
    }

    setState(() {
      _showSpinner = true;
    });

    try {
      final newUser = await _auth.createUserWithEmailAndPassword(
        email: email!,
        password: password!,
      );

      if (newUser.user != null) {
        // Save the user's details to Firestore
        await _saveUserDetails(newUser.user!);
        _showSuccessToast();
        Navigator.pushNamed(context, Done.id);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _showSpinner = false;
        if (e.code == 'email-already-in-use') {
          _wrongEmail = true;
          _emailText = _inUsedEmailText;
        }
      });
    } catch (e) {
      setState(() {
        _showSpinner = false;
      });
      print("Error: $e");
    }
  }

  Future<void> _saveUserDetails(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name ?? 'Unknown',
      'email': email ?? 'Unknown',
      'createdAt': Timestamp.now(),
      'profilePictureUrl': '',
    });
  }

  void _showSuccessToast() {
    Fluttertoast.showToast(
      msg: "Registered Successfully",
      toastLength: Toast.LENGTH_SHORT,
      // gravity: ToastGravity.BOTTOM,
      textColor: Colors.blue,
      fontSize: 16.0,
    );
  }

  Future<void> _signInWithSocialMedia(String platform) async {
    setState(() {
      _showSpinner = true;
    });

    UserCredential? userCredential;

    try {
      if (platform == 'google') {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

        if (googleAuth != null) {
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(credential);
        }
      } else if (platform == 'facebook') {
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          final AccessToken accessToken = result.accessToken!;
          final AuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
          userCredential = await _auth.signInWithCredential(credential);
        }
      }

      if (userCredential != null && userCredential.user != null) {
        await _saveUserDetails(userCredential.user!);
        _showSuccessToast();
        Navigator.pushNamed(context, Done.id);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        color: Colors.blueAccent,
        child: Stack(
          children: [

            Padding(
              padding: EdgeInsets.only(
                top: 30.0,
                bottom: 45.0,
                left: 20.0,
                right: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Please Register',
                    style: TextStyle(fontSize: 50.0),
                  ),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       'Let\'s get',
                  //       style: TextStyle(fontSize: 30.0),
                  //     ),
                  //     Text(
                  //       'you on board',
                  //       style: TextStyle(fontSize: 30.0),
                  //     ),
                  //   ],
                  // ),
                  Column(
                    children: [
                      TextField(
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          name = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Username',
                          errorText: _emptyNameField ? _emptyNameFieldText : null,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          email = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText: _wrongEmail ? _emailText : _emptyEmailField ? _emptyEmailFieldText : null,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (value) {
                          password = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: _wrongPassword ? _passwordText : _emptyPasswordField ? _emptyPasswordFieldText : null,
                        ),
                      ),

                      SizedBox(height: 20.0),
                      TextField(
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (value) {
                          confirmPassword = value; // Capture confirm password input
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          errorText: _passwordMismatch ? _passwordMismatchText : null,
                        ),
                      ),
                      SizedBox(height: 20.0),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      backgroundColor: Color(0xff447def),
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(fontSize: 25.0, color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          height: 1.0,
                          width: 60.0,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Or',
                        style: TextStyle(fontSize: 25.0),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          height: 1.0,
                          width: 60.0,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _signInWithSocialMedia('google'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            backgroundColor: Color(0xff447def), // Blue background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(width: 0.5, color: Colors.grey[400]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google.png',
                                fit: BoxFit.contain,
                                width: 40.0,
                                height: 40.0,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Google',
                                style: TextStyle(fontSize: 25.0, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 20.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _signInWithSocialMedia('facebook'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            backgroundColor: Color(0xff447def),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(width: 0.5, color: Colors.grey[400]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/facebook.png',
                                fit: BoxFit.contain,
                                width: 40.0,
                                height: 40.0,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Facebook',
                                style: TextStyle(fontSize: 25.0, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an Account?',
                          style: TextStyle(fontSize: 15.0),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, LoginPage.id);
                          },
                          child: Text(
                            'Log In',
                            style: TextStyle(fontSize: 15.0, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}