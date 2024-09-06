import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:scanna/Results_Screen/GoogleDone.dart';
import 'package:scanna/Results_Screen/ForgotPassword.dart';
import 'package:scanna/Results_Screen/Done.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  String _wrongPasswordFieldText = 'Wrong Password';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';
  User? _user;

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
          builder: (context) => GoogleDone(user, _googleSignIn),
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
          builder: (context) => Done(), // Navigate to your desired screen
        ),
      );
    } else {
      _showToast("Facebook sign-in failed");
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
      return userCredential.user;
    }
    return null;
  }

  Future<User?> _handleFacebookSignIn() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final AuthCredential credential = FacebookAuthProvider.credential(accessToken.token);

      UserCredential userCredential = await _auth.signInWithCredential(credential);
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
                    style: TextStyle(fontSize: 30.0, color: Colors.black54),
                  ),
                  SizedBox(height: 40.0),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emptyEmailField ? _emptyEmailFieldText : _wrongEmail ? _emailText : null,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
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
                      errorText: _wrongPassword ? _wrongPasswordFieldText : _emptyPasswordField ? _emptyPasswordFieldText : _wrongPassword ? _passwordText : null,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
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
                        style: TextStyle(fontSize: 16.0, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.0),
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
                          _showToast("Incorrect Password");
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
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      backgroundColor: Colors.blueAccent,
                      side: BorderSide(width: 0.5, color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Divider(color: Colors.blueAccent),
                      ),
                      SizedBox(width: 10.0),
                      Text('Or', style: TextStyle(fontSize: 20.0, color: Colors.blueAccent)),
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
                        width: 150.0,
                        child: ElevatedButton.icon(
                          onPressed: () => _signInWithSocialMedia('google'),
                          icon: Image.asset('assets/images/google.png', width: 24),
                          label: Text('Google', style: TextStyle(fontSize: 18.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            side: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Container(
                        width: 150.0,
                        child: ElevatedButton.icon(
                          onPressed: () => _signInWithSocialMedia('facebook'),
                          icon: Image.asset('assets/images/facebook.png', width: 24),
                          label: Text('Facebook', style: TextStyle(fontSize: 18.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            side: BorderSide(color: Colors.blueAccent),
                          ),
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
