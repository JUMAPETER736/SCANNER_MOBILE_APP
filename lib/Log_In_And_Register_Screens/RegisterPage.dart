import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:validators/validators.dart' as validator;
import 'package:scanna/Home_Screens/Main_Home.dart';
import 'package:scanna/Log_In_And_Register_Screens/LoginPage.dart';
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
  String? confirmPassword;

  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyNameField = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;
  bool _passwordMismatch = false;
  bool _passwordTooShort = false;


  bool isValidEmail(String email) {
    final regex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }


  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    setState(() {
      _wrongEmail = false;
      _emptyNameField = false;
      _emptyEmailField = false;
      _emptyPasswordField = false;
      _passwordMismatch = false;
      _passwordTooShort = false;
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
    } else if (!isValidEmail(email!)) {
      setState(() {
        _wrongEmail = true;
      });
    }

    if (password == null || password!.isEmpty) {
      setState(() {
        _emptyPasswordField = true;
      });
    }

    if (confirmPassword == null || confirmPassword!.isEmpty || password != confirmPassword) {
      setState(() {
        _passwordMismatch = true;
      });
    }

    if (password != null && password!.length < 6) {
      setState(() {
        _passwordTooShort = true;
      });
    }

    if (_emptyNameField || _emptyEmailField || _emptyPasswordField || _passwordMismatch || _passwordTooShort) {
      return;
    }

    setState(() {
      _showSpinner = true;
    });

    try {
      final newUser = await _auth.createUserWithEmailAndPassword(email: email!, password: password!);
      if (newUser.user != null) {
        await _saveUserDetails(newUser.user!);
        _showSuccessToast();
        Navigator.pushNamed(context, Done.id);
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        _showSpinner = false;
        if (e.code == 'email-already-in-use') {
          _wrongEmail = true;
          _emptyEmailField = false;
        }
      });
    } finally {
      setState(() {
        _showSpinner = false;
      });
    }
  }


  Future<void> _saveUserDetails(User user) async {

    await FirebaseFirestore.instance.collection('Teacher').doc(user.uid).set({
      'name': name ?? 'Unknown',
      'email': email ?? 'Unknown',
      'createdAt': Timestamp.now(),
      'profilePictureUrl': '',

    });
  }

  void _showSuccessToast([String message = "Registered Successfully"]) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      textColor: Colors.blue,
      fontSize: 16.0,
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required IconData icon,
    required bool obscureText,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    bool showError = false,
    String? errorText,
  }) {
    return TextField(
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: showError ? errorText : null,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    try {
      if (provider == 'google') {
        // Google sign-in
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          Navigator.pushNamed(context, Done.id);
        }
      } else if (provider == 'facebook') {
        // Facebook sign-in
        final LoginResult loginResult = await FacebookAuth.instance.login();

        if (loginResult.status == LoginStatus.success) {
          final AuthCredential credential = FacebookAuthProvider.credential(loginResult.accessToken!.token);
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          Navigator.pushNamed(context, Done.id);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Sign-in failed",
        toastLength: Toast.LENGTH_SHORT,
        textColor: Colors.red,
        fontSize: 16.0,
      );
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Register',
                  style: TextStyle(fontSize: 40.0, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                _buildStyledTextField(
                  label: 'Name',
                  icon: Icons.person,
                  obscureText: false,
                  onChanged: (value) => name = value,
                  showError: _emptyNameField,
                  errorText: 'Please fill in the Name field',
                ),

                _buildStyledTextField(
                  label: 'Email',
                  icon: Icons.email,
                  obscureText: false,
                  onChanged: (value) => email = value,
                  showError: _wrongEmail || _emptyEmailField,
                  errorText: _emptyEmailField ? 'Email cannot be empty' :
                  _wrongEmail ? 'Email is already in use' :
                  'Please use a valid Email',
                ),


                SizedBox(height: 20.0),
                _buildStyledTextField(
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  onChanged: (value) => password = value,
                  showError: _wrongPassword || _emptyPasswordField || _passwordTooShort,
                  errorText: _passwordTooShort ? 'Password is too short, Password should be atleast 6 Charecters' : 'Please use a strong Password',
                ),
                SizedBox(height: 20.0),
                _buildStyledTextField(
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  onChanged: (value) => confirmPassword = value,
                  showError: _passwordMismatch,
                  errorText: 'Passwords do NOT match',
                ),
                SizedBox(height: 30.0),
                Container(
                  width: 350.0, // Adjust width as needed
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
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
                SizedBox(height: 20.0),
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
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an Account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, LoginPage.id);
                      },
                      child: Text('Log In', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
