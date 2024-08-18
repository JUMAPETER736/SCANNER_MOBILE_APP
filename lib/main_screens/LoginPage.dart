import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Import Facebook Auth
import 'package:scanna/results_screen/GoogleDone.dart';
import 'package:scanna/results_screen/ForgotPassword.dart';
import 'package:scanna/main_screens/RegisterPage.dart';
import 'package:scanna/results_screen/Done.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';





class LoginPage extends StatefulWidget {
  static String id = '/LoginPage';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;

  String _emailText = 'Please use a valid Email';
  String _passwordText = 'Please use a strong Password';
  String _emptyEmailFieldText = 'Please fill in the Email field';
  String _emptyPasswordFieldText = 'Please fill in the Password field';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';
  User? _user;

  void onGoogleSignIn(BuildContext context) async {
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
          builder: (context) => GoogleDone(user, _googleSignIn),
        ),
      );
    } else {
      // Handle sign-in failure
      // You can show a dialog or message indicating failure
    }
  }

  Future<User?> _handleGoogleSignIn() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
    }

    return _user;
  }

Future<void> loginWithFacebook() async {
  try {
    // Trigger Facebook login
    final LoginResult result = await FacebookAuth.instance.login();

    // Check if Facebook login is successful
    if (result.status == LoginStatus.success) {
      // Get Facebook user profile
      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      // Navigate to the appropriate screen after successful login
      // Example:
      // Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
    } else {
      // Handle if login is cancelled or failed
      print('Facebook login failed');
    }
  } catch (e) {
    // Handle error
    print('Error while Facebook login: $e');
  }
}



  void onFacebookSignIn(BuildContext context) async {
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
          builder: (context) => Done(), // Navigate to your desired screen
        ),
      );
    } else {
      // Handle sign-in failure
      // You can show a dialog or message indicating failure
    }
  }

  Future<User?> _handleFacebookSignIn() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final AuthCredential credential = FacebookAuthProvider.credential(accessToken.token);

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
    }

    return _user;
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
            Align(
              alignment: Alignment.topRight,
              child: Image.asset('assets/images/background.png'),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: 60.0, bottom: 20.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(fontSize: 50.0),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 30.0),
                      ),
                      Text(
                        'please login',
                        style: TextStyle(fontSize: 30.0),
                      ),
                      Text(
                        'to your Account',
                        style: TextStyle(fontSize: 30.0),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          email = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText: _emptyEmailField ? _emptyEmailFieldText : _wrongEmail ? _emailText : null,
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
                          errorText: _emptyPasswordField ? _emptyPasswordFieldText : _wrongPassword ? _passwordText : null,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, ForgotPassword.id);
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(fontSize: 20.0, color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _showSpinner = true;
                        _emptyEmailField = email.isEmpty;
                        _emptyPasswordField = password.isEmpty;
                      });

                      if (_emptyEmailField || _emptyPasswordField) {
                        setState(() {
                          _showSpinner = false;
                        });
                        return;
                      }

                      try {
                        setState(() {
                          _wrongEmail = false;
                          _wrongPassword = false;
                        });

                        UserCredential userCredential =
                            await _auth.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        if (userCredential.user != null) {
                          Navigator.pushNamed(context, Done.id);
                        }
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'wrong-password') {
                          setState(() {
                            _wrongPassword = true;
                          });
                        } else if (e.code == 'user-not-found') {
                          setState(() {
                            _wrongEmail = true;
                          });
                        }
                      } finally {
                        setState(() {
                          _showSpinner = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      backgroundColor: Color(0xff447def),
                      side: BorderSide(width: 0.5, color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'Login',
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
                          onPressed: () {
                            onGoogleSignIn(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            backgroundColor: Color(0xff447def),
                            side: BorderSide(width: 0.5, color: Colors.grey[400]!),
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
                                style: TextStyle(fontSize: 25.0, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 20.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onFacebookSignIn(context); // Call Facebook login method
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            backgroundColor: Color(0xff447def),
                            side: BorderSide(width: 0.5, color: Colors.grey[400]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/facebook.png', // Replace with your Facebook button image asset
                                fit: BoxFit.cover,
                                width: 40.0,
                                height: 40.0,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Facebook',
                                style: TextStyle(fontSize: 25.0, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an Account?',
                        style: TextStyle(fontSize: 15.0),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, RegisterPage.id);
                        },
                        child: Text(
                          ' Sign In',
                          style: TextStyle(fontSize: 15.0, color: Colors.blue),
                        ),
                      ),
                    ],
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
