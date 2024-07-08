import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:validators/validators.dart' as validator;
import 'package:scanna/results_screen/Done.dart';
import 'package:scanna/results_screen/GoogleDone.dart';
import 'package:scanna/main_screens/LoginPage.dart';

class RegisterPage extends StatefulWidget {
  static String id = '/RegisterPage';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? name;
  String? email;
  String? password;

  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyNameField = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;

  String _emailText = 'Please use a valid Email';
  String _passwordText = 'Please use a strong Password';
  String _emptyNameFieldText = 'Please fill in the name field';
  String _emptyEmailFieldText = 'Please fill in the email field';
  String _emptyPasswordFieldText = 'Please fill in the password field';
  String _inUsedEmailText = 'The email address is already in use by another account.';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> _handleSignIn() async {
    User? user;
    bool isSignedIn = await _googleSignIn.isSignedIn();
    if (isSignedIn) {
      user = await _auth.currentUser;
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      user = (await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      ))
          .user;
    }

    return user;
  }

  void onGoogleSignIn(BuildContext context) async {
    User? user = await _handleSignIn();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleDone(user!, _googleSignIn),
      ),
    );
  }

  void _register() async {
    setState(() {
      _wrongEmail = false;
      _wrongPassword = false;
      _emptyNameField = false;
      _emptyEmailField = false;
      _emptyPasswordField = false;
    });

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

    if (_emptyNameField || _emptyEmailField || _emptyPasswordField) {
      return;
    }

    if (!validator.isEmail(email!) || !validator.isLength(password!, 6)) {
      setState(() {
        if (!validator.isEmail(email!)) {
          _wrongEmail = true;
        }
        if (!validator.isLength(password!, 6)) {
          _wrongPassword = true;
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
      if (newUser != null) {
        print('User registered successfully');
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
      print(e);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Register',
                    style: TextStyle(fontSize: 50.0),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Let\'s get',
                        style: TextStyle(fontSize: 30.0),
                      ),
                      Text(
                        'you on board',
                        style: TextStyle(fontSize: 30.0),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      TextField(
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          name = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Full Name',
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
                      SizedBox(height: 10.0),
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
                          onPressed: () {
                            onGoogleSignIn(context);
                          },
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
                            // TODO: Implement Facebook functionality
                          },
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
                        'Already have an account?',
                        style: TextStyle(fontSize: 25.0),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, LoginPage.id);
                        },
                        child: Text(
                          ' Sign In',
                          style: TextStyle(fontSize: 25.0, color: Colors.blue),
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
