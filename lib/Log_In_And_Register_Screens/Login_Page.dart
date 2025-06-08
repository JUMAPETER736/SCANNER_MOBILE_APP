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
  bool _emailNotRegistered = false;
  bool _isPasswordVisible = false;

  String _emailText = 'Please use a valid Email';
  String _emptyEmailFieldText = 'Please fill in the Email field';
  String _emptyPasswordFieldText = 'Please fill in the Password field';
  String _wrongPasswordFieldText = 'Wrong Password';
  String _emailNotRegisteredText = 'Email not registered';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';

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

  Widget _buildStyledTextField({
    required String label,
    required IconData icon,
    required bool obscureText,
    Function(String)? onChanged,
    bool showError = false,
    String? errorText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
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
        keyboardType: keyboardType,
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

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
          builder: (context) => Main_Home(),
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
      final AuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

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
      fontSize: _getResponsiveFontSize(context, 18.0),
    );
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    if (provider == 'google') {
      await onGoogleSignIn(context);
    } else if (provider == 'facebook') {
      await onFacebookSignIn(context);
    }
  }

  Future<void> _login() async {
    setState(() {
      _showSpinner = true;
      _emptyEmailField = email.isEmpty;
      _emptyPasswordField = password.isEmpty;
      _wrongEmail = false;
      _wrongPassword = false;
      _emailNotRegistered = false;
    });

    if (_emptyEmailField || _emptyPasswordField) {
      setState(() {
        _showSpinner = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Navigator.pushNamed(context, Main_Home.id);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _showSpinner = false;
        if (e.code == 'wrong-password') {
          _wrongPassword = true;
        } else if (e.code == 'user-not-found') {
          _emailNotRegistered = true;
        } else if (e.code == 'invalid-email') {
          _wrongEmail = true;
        } else if (e.code == 'too-many-requests') {
          // Handle too many failed attempts
          _showToast("Too many failed attempts. Please try again later.");
        } else if (e.code == 'user-disabled') {
          // Handle disabled user account
          _showToast("This account has been disabled.");
        } else {
          // Handle any other authentication errors
          _showToast("Authentication failed. Please try again.");
        }
      });

      // Show specific toast messages for different error types
      if (e.code == 'wrong-password') {
        _showToast("Incorrect Password");
      } else if (e.code == 'user-not-found') {
        _showToast("Email not Registered");
      } else if (e.code == 'invalid-email') {
        _showToast("Please enter a valid email address");
      }
    } catch (e) {
      // Handle any other non-Firebase exceptions
      setState(() {
        _showSpinner = false;
      });
      _showToast("An error occurred. Please try again.");
    } finally {
      setState(() {
        _showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        color: Colors.blueAccent,
        progressIndicator: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        child: Container(
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
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: _getResponsivePadding(context),
                    child: Column(
                      children: [
                        // Top spacing
                        SizedBox(height: _getResponsiveSpacing(context, 20.0)),

                        // Header Section
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                  Icons.login,
                                  size: _getResponsiveFontSize(context, 26.0),
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: _getResponsiveSpacing(context, 8.0)),
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 30.0),
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),

                        // Email Field
                        _buildStyledTextField(
                          label: 'Email Address',
                          icon: Icons.email,
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            email = value;
                            setState(() {
                              _wrongEmail = false;
                              _emailNotRegistered = false;
                              _emptyEmailField = email.isEmpty;
                            });
                          },
                          showError: _emptyEmailField || _wrongEmail || _emailNotRegistered,
                          errorText: _emptyEmailField
                              ? _emptyEmailFieldText
                              : _emailNotRegistered
                              ? _emailNotRegisteredText
                              : _wrongEmail
                              ? _emailText
                              : null,
                        ),

                        SizedBox(height: _getResponsiveSpacing(context, 16.0)),

                        // Password Field
                        _buildStyledTextField(
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: !_isPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (value) {
                            password = value;
                            setState(() {
                              _wrongPassword = false;
                              _emptyPasswordField = password.isEmpty;
                            });
                          },
                          showError: _emptyPasswordField || _wrongPassword,
                          errorText: _emptyPasswordField
                              ? _emptyPasswordFieldText
                              : _wrongPassword
                              ? _wrongPasswordFieldText
                              : null,
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

                        // Forgot Password Link - moved closer to password field
                        Padding(
                          padding: EdgeInsets.only(top: _getResponsiveSpacing(context, 8.0)),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, Forgot_Password.id);
                              },
                              child: Text(
                                'Forgot Password',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 22.0),
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),

                        // Login Button
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
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            child: Text(
                              'Log In',
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
                            SizedBox(width: _getResponsiveSpacing(context, 4.0)),
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

                        // Flexible spacer to push sign up link to bottom
                        Expanded(child: Container()),

                        // Sign Up Link
                        Padding(
                          padding: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 2.0)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: _getResponsiveFontSize(context, 20.0),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Register_Page.id);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Sign Up',
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