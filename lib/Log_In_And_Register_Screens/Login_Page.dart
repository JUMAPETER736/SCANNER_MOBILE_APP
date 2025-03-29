import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:scanna/Log_In_And_Register_Screens/Google_Done.dart';
import 'package:scanna/Log_In_And_Register_Screens/Forgot_Password.dart';
import 'package:scanna/Home_Screens/Main_Home.dart';
import 'package:scanna/Log_In_And_Register_Screens/Register_Page.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Login_Page extends StatefulWidget {
  static String id = '/LoginPage';

  @override
  _Login_PageState createState() => _Login_PageState();
}

class _Login_PageState extends State<Login_Page> {
  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;
  bool _emailNotRegistered = false; // New state variable
  bool _isPasswordVisible = false;

  String _emailText = 'Please use a valid Email';
  String _emptyEmailFieldText = 'Please fill in the Email field';
  String _emptyPasswordFieldText = 'Please fill in the Password field';
  String _wrongPasswordFieldText = 'Wrong Password';
  String _emailNotRegisteredText = 'Email not registered'; // New error message

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';


  Future<void> onGoogleSignIn(BuildContext context) async {
    setState(() {
      _showSpinner = true;
    });

    User? user = await _handleGoogleSignIn();

    setState(() {
      _showSpinner = false;
    });

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Google_Done(user, _googleSignIn),
        ),
      );
    } else {
      _showToast("Google sign-in failed");
    }
  }

  Future<void> onFacebookSignIn(BuildContext context) async {
    setState(() {
      _showSpinner = true;
    });

    User? user = await _handleFacebookSignIn();

    setState(() {
      _showSpinner = false;
    });

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Main_Home(), // Navigate to your desired screen
        ),
      );
    } else {
      _showToast("Facebook sign-in failed");
    }
  }

  Future<User?> _handleGoogleSignIn() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
          credential);
      return userCredential.user;
    }
    return null;
  }

  Future<User?> _handleFacebookSignIn() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final AuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString
      );

      UserCredential userCredential = await _auth.signInWithCredential(
          credential);
      return userCredential.user;
    }
    return null;
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    if (provider == 'google') {
      await onGoogleSignIn(context);
    } else if (provider == 'facebook') {
      await onFacebookSignIn(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        color: Colors.blueAccent,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 15.0),
                  Text(
                    'Welcome back, please login to your Account',
                    style: TextStyle(fontSize: 24.0, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 20.0),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      email = value;
                      setState(() {
                        _wrongEmail = false;
                        _emailNotRegistered = false;
                        _emptyEmailField = email.isEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emptyEmailField
                          ? _emptyEmailFieldText
                          : _wrongEmail
                          ? _emailText
                          : _emailNotRegistered
                          ? _emailNotRegisteredText
                          : null,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                    ),
                  ),
                  SizedBox(height: 15.0),

                  TextField(
                    obscureText: !_isPasswordVisible,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      password = value;
                      setState(() {
                        _wrongPassword = false; // Reset wrong password state
                        _emptyPasswordField = password.isEmpty; // Check if empty
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _emptyPasswordField
                          ? _emptyPasswordFieldText
                          : _wrongPassword
                          ? _wrongPasswordFieldText
                          : null,
                      errorStyle: TextStyle(color: Colors.red), // Set error text color to red
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                          });
                        },
                      ),
                    ),
                  ),


                  SizedBox(height: 1.0),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, Forgot_Password.id);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                            fontSize: 16.0, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Center( // Center the button horizontally
                    child: SizedBox(
                      width: 88.0, // Set a fixed width for the button
                      child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _showSpinner = true; // Show the spinner
                              _emptyEmailField = email.isEmpty; // Check if email field is empty
                              _emptyPasswordField = password.isEmpty; // Check if password field is empty
                            });

                            if (_emptyEmailField || _emptyPasswordField) {
                              setState(() {
                                _showSpinner = false; // Hide the spinner if fields are empty
                              });
                              return; // Exit if either field is empty
                            }

                            try {
                              setState(() {
                                _wrongEmail = false; // Reset wrong email flag
                                _wrongPassword = false; // Reset wrong password flag
                                _emailNotRegistered = false; // Reset email not registered error
                              });

                              // Attempt to sign in
                              UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                              // Check if the user credential is valid
                              if (userCredential.user != null) {
                                Navigator.pushNamed(context, Main_Home.id); // Navigate on success
                              }
                            } on FirebaseAuthException catch (e) {
                              // Handle different error cases
                              if (e.code == 'wrong-password') {
                                setState(() {
                                  _wrongPassword = true; // Set wrong password flag
                                  _showSpinner = false; // Hide the spinner
                                });
                                _showToast("Incorrect Password"); // Show error toast
                              } else if (e.code == 'user-not-found') {
                                setState(() {
                                  _emailNotRegistered = true; // Set email not registered flag
                                  _showSpinner = false; // Hide the spinner
                                });
                                _showToast("Email not Registered"); // Show error toast
                              } else {
                                // Handle other exceptions as needed
                                setState(() {
                                  _showSpinner = false; // Hide spinner in case of other errors
                                });
                              }
                            } finally {
                              // Make sure to hide the spinner after the operation
                              setState(() {
                                _showSpinner = false;
                              });
                            }
                          },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(fontSize: 20.0, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Divider(color: Colors.blueAccent),
                      ),
                      SizedBox(width: 10.0),
                      Text('Or', style: TextStyle(
                          fontSize: 20.0, color: Colors.blueAccent)),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Divider(color: Colors.blueAccent),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150.0, // Adjust width as needed
                        child: ElevatedButton.icon(
                          onPressed: () => _signInWithSocialMedia('google'),
                          icon: Image.asset(
                              'assets/images/google.png', width: 24),
                          label: Text('Google', style: TextStyle(
                              fontSize: 18.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            side: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Container(
                        width: 150.0, // Adjust width as needed
                        child: ElevatedButton.icon(
                          onPressed: () => _signInWithSocialMedia('facebook'),
                          icon: Image.asset(
                              'assets/images/facebook.png', width: 24),
                          label: Text('Facebook', style: TextStyle(
                              fontSize: 18.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            side: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an Account? ',
                          style: TextStyle(fontSize: 15.0),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, Register_Page.id);
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 15.0,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
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
