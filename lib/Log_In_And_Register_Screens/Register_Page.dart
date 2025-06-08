import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:scanna/Home_Screens/Main_Home.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Register_Page extends StatefulWidget {
  static String id = '/RegisterPage';

  @override
  _Register_PageState createState() => _Register_PageState();
}

class _Register_PageState extends State<Register_Page> {
  String? name;
  String? email;
  String? password;
  String? confirmPassword;
  String? selectedClass;
  String? selectedSubject;

  bool _showSpinner = false;
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyNameField = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;
  bool _passwordMismatch = false;
  bool _passwordTooShort = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Helper method to calculate responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate scale factor based on screen dimensions
    double widthScale = screenWidth / 375.0; // Base width (iPhone X)
    double heightScale = screenHeight / 812.0; // Base height (iPhone X)
    double scale = (widthScale + heightScale) / 2;

    // Calculate responsive font size
    double responsiveFontSize = baseFontSize * scale;

    // Ensure minimum font size of 22
    return responsiveFontSize < 22.0 ? 22.0 : responsiveFontSize;
  }

  // Helper method to get responsive padding
  EdgeInsets _getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double basePadding = screenWidth * 0.06; // 6% of screen width
    return EdgeInsets.symmetric(horizontal: basePadding.clamp(16.0, 32.0), vertical: 12.0);
  }

  // Helper method to get responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scale = screenHeight / 812.0; // Base height
    return (baseSpacing * scale).clamp(baseSpacing * 0.5, baseSpacing * 1.5);
  }

  // Helper method to check if device is in landscape mode
  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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

    if (confirmPassword == null || confirmPassword!.isEmpty ||
        password != confirmPassword) {
      setState(() {
        _passwordMismatch = true;
      });
    }

    if (password != null && password!.length < 6) {
      setState(() {
        _passwordTooShort = true;
      });
    }

    if (_emptyNameField || _emptyEmailField || _emptyPasswordField ||
        _passwordMismatch || _passwordTooShort) {
      return;
    }

    setState(() {
      _showSpinner = true;
    });

    try {
      final newUser = await _auth.createUserWithEmailAndPassword(
          email: email!, password: password!);
      if (newUser.user != null) {
        await _saveUserDetails(newUser.user!, name!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registered Successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
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

  Future<void> _saveUserDetails(User user, String name) async {
    String userEmail = user.email ?? '';

    await FirebaseFirestore.instance.collection('Teachers_Details').doc(userEmail).set({
      'name': name ?? 'false',
      'email': userEmail,
      'createdAt': Timestamp.now(),
    });
  }

  Widget _buildStyledTextField({
    required String label,
    required IconData icon,
    required bool obscureText,
    Function(String)? onChanged,
    bool showError = false,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 16.0)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 16.0)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontSize: _getResponsiveFontSize(context, 16.0),
            fontWeight: FontWeight.w500,
          ),
          errorText: showError ? errorText : null,
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: _getResponsiveFontSize(context, 12.0),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: _getResponsiveFontSize(context, 20.0)),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        ),
      ),
    );
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    try {
      if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          Navigator.pushNamed(context, Main_Home.id);
        }
      } else if (provider == 'facebook') {
        final LoginResult loginResult = await FacebookAuth.instance.login();

        if (loginResult.status == LoginStatus.success) {
          Navigator.pushNamed(context, Main_Home.id);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Sign-in failed",
        toastLength: Toast.LENGTH_SHORT,
        textColor: Colors.red,
        fontSize: _getResponsiveFontSize(context, 16.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape = _isLandscape(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        color: Colors.white,
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blueAccent.withOpacity(0.1),
                Colors.white,
                Colors.blueAccent.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: _getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section - Adjusted for landscape
                      Container(
                        padding: EdgeInsets.symmetric(vertical: isLandscape ? 20.0 : 40.0),
                        child: Column(
                          children: [
                            Container(
                              width: _getResponsiveFontSize(context, 50.0),
                              height: _getResponsiveFontSize(context, 50.0),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_add,
                                size: _getResponsiveFontSize(context, 26.0),
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 12.0)),
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 24.0),
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Form Fields Section
                      Column(
                        children: [
                          _buildStyledTextField(
                            label: 'Full Name',
                            icon: Icons.person,
                            obscureText: false,
                            onChanged: (value) => name = value,
                            showError: _emptyNameField,
                            errorText: 'Please fill in the Name field',
                          ),

                          _buildStyledTextField(
                            label: 'Email Address',
                            icon: Icons.email,
                            obscureText: false,
                            onChanged: (value) => email = value,
                            showError: _wrongEmail || _emptyEmailField,
                            errorText: _emptyEmailField ? 'Email cannot be empty' :
                            _wrongEmail ? 'Email is already in use' :
                            'Please use a valid Email',
                          ),

                          // Password Field
                          _buildStyledTextField(
                            label: 'Password',
                            icon: Icons.lock,
                            obscureText: !_isPasswordVisible,
                            onChanged: (value) => password = value,
                            showError: _wrongPassword || _emptyPasswordField || _passwordTooShort,
                            errorText: _passwordTooShort
                                ? 'Password must be at least 6 characters'
                                : 'Please use a strong Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.blueAccent,
                                size: _getResponsiveFontSize(context, 20.0),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),

                          // Confirm Password Field
                          _buildStyledTextField(
                            label: 'Confirm Password',
                            icon: Icons.lock,
                            obscureText: !_isConfirmPasswordVisible,
                            onChanged: (value) => confirmPassword = value,
                            showError: _passwordMismatch,
                            errorText: 'Passwords do not match',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.blueAccent,
                                size: _getResponsiveFontSize(context, 20.0),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      // Spacer to push buttons to bottom
                      SizedBox(height: _getResponsiveSpacing(context, 24.0)),

                      // Bottom Section - Buttons and Links
                      Column(
                        children: [
                          // Register Button
                          Container(
                            height: _getResponsiveFontSize(context, 48.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent, Colors.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 22.0),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: _getResponsiveSpacing(context, 20.0)),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(context, 22.0),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: _getResponsiveSpacing(context, 20.0)),

// Social Media Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: _getResponsiveFontSize(context, 44.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _signInWithSocialMedia('google'),
                                    icon: Image.asset('assets/images/google.png', width: _getResponsiveFontSize(context, 18.0)),
                                    label: Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(context, 22.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.grey[700],
                                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: _getResponsiveSpacing(context, 12.0)),
                              Expanded(
                                child: Container(
                                  height: _getResponsiveFontSize(context, 44.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _signInWithSocialMedia('facebook'),
                                    icon: Image.asset('assets/images/facebook.png', width: _getResponsiveFontSize(context, 18.0)),
                                    label: Text(
                                      'Facebook',
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(context, 22.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.grey[700],
                                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: _getResponsiveSpacing(context, 24.0)),

                          // Login Link
                          Padding(
                            padding: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 16.0)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: _getResponsiveFontSize(context, 20.0),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, Login_Page.id);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: _getResponsiveFontSize(context, 20.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}